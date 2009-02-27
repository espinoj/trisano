# Copyright (C) 2007, 2008, 2009 The Collaborative Software Foundation
#
# This file is part of TriSano.
#
# TriSano is free software: you can redistribute it and/or modify it under the 
# terms of the GNU Affero General Public License as published by the 
# Free Software Foundation, either version 3 of the License, 
# or (at your option) any later version.
#
# TriSano is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License 
# along with TriSano. If not, see http://www.gnu.org/licenses/agpl-3.0.txt.

class MorbidityEventsController < EventsController

  before_filter :capture_old_attributes, :only => [:update]

  def auto_complete_for_event_reporting_agency
    entered_name = params[:morbidity_event][:active_reporting_agency][:name]
    @items = Place.find(:all, :select => "DISTINCT ON (entity_id) entity_id, name", 
      :conditions => [ "LOWER(name) LIKE ? and place_type_id IN 
                       (SELECT id FROM codes WHERE code_name = 'placetype' AND the_code IN ('H', 'L', 'C'))", entered_name.downcase + '%'],
      :order => "entity_id, created_at ASC, name ASC",
      :limit => 10
    )
    render :inline => '<ul><% for item in @items %><li id="reporting_agency_id_<%= item.entity_id %>"><%= h item.name %></li><% end %></ul>'
  end

  def index
    begin
      @export_options = params[:export_options]

      @events = MorbidityEvent.find_all_for_filtered_view(
        :states => params[:states],
        :queues => params[:queues],
        :investigators => params[:investigators],
        :diseases => params[:diseases],
        :order_by => params[:sort_order],
        :do_not_show_deleted => params[:do_not_show_deleted],
        :set_as_default_view => params[:set_as_default_view],
        :page => params[:page]
      )
    rescue
      render :file => "#{RAILS_ROOT}/public/404.html", :layout => 'application', :status => 404 and return
    end
    
    respond_to do |format|
      format.html # { render :template => "events/index" }
      format.xml  { render :xml => @events }
      format.csv
    end
  end

  def show
    @export_options = params[:export_options]
    
    # @event initialized in can_view? filter

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
      format.csv
      format.print
    end
  end

  def new
    unless User.current_user.is_entitled_to?(:create_event)
      render :text => "Permission denied: You do not have privileges to create a CMR", :status => 403 and return
    end

    @event = MorbidityEvent.new
    
    prepopulate if !params[:from_search].nil?

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def edit
    # Via filters above #can_update? is called which loads up @event with the found event.
    # Nothing to do here.
  end

  def create
    go_back = params.delete(:return)
    
    if params[:from_patient]
      @event = MorbidityEvent.new_event_from_patient(Entity.find(params[:from_patient]))
    else
      @event = MorbidityEvent.new(params[:morbidity_event])
    end

    # Allow for test scripts and developers to jump directly to the "under investigation" state
    if RAILS_ENV == 'production'
      @event.primary_jurisdiction.name == "Unassigned" ? @event.event_status = "NEW" : @event.event_status = "ACPTD-LHD"
    end
    @event.event_onset_date = Date.today

    unless User.current_user.is_entitled_to_in?(:create_event, @event.primary_jurisdiction.entity_id)
      render :text => "Permission denied: You do not have create privileges for this jurisdiction", :status => 403 and return
    end
    
    @event.initialize_children

    respond_to do |format|
      if @event.save
        # Debt:  There's gotta be a beter place for this.  Doesn't work on after_save of events.
        Event.transaction do
          [@event, @event.contact_child_events].flatten.all? { |event| event.set_primary_entity_on_secondary_participations }
          @event.add_note(@event.instance_eval(Event.states["NEW"].note_text))
        end
        flash[:notice] = 'CMR was successfully created.'
        format.html { 
          query_str = @tab_index ? "?tab_index=#{@tab_index}" : ""
          if go_back
            redirect_to(edit_cmr_url(@event) + query_str)
          else
            redirect_to(cmr_url(@event) + query_str)
          end
        }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    go_back = params.delete(:return)

    # Do this assign and a save rather than update_attributes in order to get the contacts array (at least) properly built
    @event.attributes = params[:morbidity_event]

    # Assume that "save & exits" represent a 'significant' update
    @event.add_note("Edited event") unless go_back

    @event.initialize_children

    respond_to do |format|
      if @event.save
        # Debt:  There's gotta be a beter place for this.  Doesn't work on after_save of events.
        Event.transaction do
          [@event, @event.contact_child_events].flatten.all? { |event| event.set_primary_entity_on_secondary_participations }
        end
        flash[:notice] = 'CMR was successfully updated.'
        format.html { 
          query_str = @tab_index ? "?tab_index=#{@tab_index}" : ""
          if go_back
            redirect_to(edit_cmr_url(@event) + query_str)
          else
            redirect_to(cmr_url(@event) + query_str)
          end
        }
        format.xml  { head :ok }
        format.js   { render :inline => "CMR saved.", :status => :created }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
        format.js   { render :inline => "Morbidity Event not saved: <%= @event.errors.full_messages %>", :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    head :method_not_allowed
  end

  # Route an event from one jurisdiction to another
  def jurisdiction
 
    @event = MorbidityEvent.find(params[:id])

    # user cannot route events _from_ a jurisdiction for which they do not have the 'route_event_to_any_lhd' privilege
    unless User.current_user.is_entitled_to_in?(:route_event_to_any_lhd, @event.jurisdiction.secondary_entity_id)
      render :text => "Permission denied: You do not have sufficent privileges to route events from this jurisdiction", :status => 403 and return
    end

    begin
      Event.transaction do
        # Only change the status if they've changed the investigating jurisdiction.  Not if they only changed secondaries
        @event.update_attribute("event_status", "ASGD-LHD") unless params[:jurisdiction_id].to_i == @event.jurisdiction.secondary_entity_id
        
        # the following line must follow the previous line or state won't get changed.
        @event.route_to_jurisdiction(params[:jurisdiction_id], params[:secondary_jurisdiction_ids] || [], params[:note])
      end
    rescue Exception => ex
      flash[:error] = 'Unable to route CMR.' + ex.message
    end
    if User.current_user.is_entitled_to_in?(:view_event, params[:jurisdiction_id])
      flash[:notice] = 'Event successfully routed.'
      redirect_to request.env["HTTP_REFERER"]
    else
      flash[:notice] = "Event successfully routed, but you have insufficent privileges to view it in it's new jurisdiction"
      redirect_to cmrs_url
    end
  end

  def state
    @event = MorbidityEvent.find(params[:id])
    event_status = params[:morbidity_event].delete(:event_status)

    # Determine what privileges are required to change to the passed in state
    priv_required = Event.states[event_status].required_privilege if Event.states[event_status]

    # If nothing came back, then the passed in state was malformed
    if priv_required.nil?
      render :text => "Bad state", :status => 403 and return
    end

    # Check if the user is allowed to change the event to the passed in state
    unless User.current_user.is_entitled_to_in?(priv_required, @event.jurisdiction.secondary_entity_id)
      render :text => "Permission denied: You do not have sufficent privileges to make this change", :status => 403 and return
    end
    
    # Check if the state transition is legal. E.g: Legal -> "accepted by LHD" to "assigned to investigator".  Illegal -> "accepted by LHD" to "investigation complete"
    unless @event.current_state.allows_transition_to?(event_status)
      render :text => "Illegal State Transition", :status => 409 and return
    end
    
    # event_status is protected from mass update, set individually
    @event.event_status = event_status

    # Squirrel any notes away
    note = params[:morbidity_event].delete(:note)

    # A status change may be accompanied by other values such as an event queue, set them
    @event.attributes = params[:morbidity_event]

    # This must follow the attribute setting so that the model is set up for the instance_eval
    @event.add_note(@event.instance_eval(Event.states[event_status].note_text) + "\n#{note}")

    # Special handling for certain state changes
    case event_status
    when "RJCTD-LHD"
      @event.route_to_jurisdiction(Place.jurisdiction_by_name("Unassigned"))
    when "RJCTD-INV"
      @event.investigator_id = nil
      @event.investigation_started_date = nil
    when "UI"
      @event.investigator_id = User.current_user.id
      @event.investigation_started_date = Date.today
    when "IC"
      @event.investigation_completed_LHD_date = Date.today
    when "RO-MGR"
      @event.investigation_completed_LHD_date = nil
    when "CLOSED"
      @event.review_completed_by_state_date = Date.today
    end

    if @event.save
      redirect_to request.env["HTTP_REFERER"]
    else
      flash[:error] = 'Unable to change state of CMR.'
      redirect_to cmrs_path
    end
  end

  private
  
  def prepopulate
    # Perhaps include a message if we know the names were split out of a full text search
    @event.interested_party.person_entity.person.first_name = params[:first_name]
    @event.interested_party.person_entity.person.middle_name = params[:middle_name]
    @event.interested_party.person_entity.person.last_name = params[:last_name]
    @event.interested_party.person_entity.person.birth_gender = ExternalCode.find(params[:gender]) unless params[:gender].blank? || params[:gender].to_i == 0
    @event.interested_party.person_entity.address.city = params[:city]
    @event.interested_party.person_entity.address.county = ExternalCode.find(params[:county]) unless params[:county].blank?
    @event.jurisdiction.secondary_entity_id = params[:jurisdiction_id] unless params[:jurisdiction_id].blank?
    @event.interested_party.person_entity.person.birth_date = params[:birth_date]
    @event.disease_event.disease_id = params[:disease]
  end
  
  def capture_old_attributes
    @old_attributes = @event.attributes
  end
end
