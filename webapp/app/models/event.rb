# Copyright (C) 2007, 2008, 2009, 2010, 2011 The Collaborative Software Foundation
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

class Event < ActiveRecord::Base
  include Blankable
  include TaskFilter
  include EventSearch
  include Export::Cdc::EventRules

  before_update :attempt_form_assignment_on_update
  after_create :attempt_form_assignment_on_create

  if RAILS_ENV == "production"
    attr_protected :workflow_state
  end

  composed_of :age_info, :mapping => [%w(age_at_onset age_at_onset), %w(age_type_id age_type_id)]
  belongs_to  :age_type, :class_name => 'ExternalCode', :foreign_key => :age_type_id

  belongs_to :investigator, :class_name => 'User'
  belongs_to :imported_from, :class_name => 'ExternalCode'
  belongs_to :lhd_case_status, :class_name => 'ExternalCode'
  belongs_to :state_case_status, :class_name => 'ExternalCode'
  belongs_to :outbreak_associated, :class_name => 'ExternalCode'

  has_one :jurisdiction, :dependent => :destroy
  alias primary_jurisdiction jurisdiction # fixes csv exports

  has_many :associated_jurisdictions,
    :order => 'created_at ASC',
    :dependent => :destroy

  has_many :all_jurisdictions, :class_name => 'Participation',
    :conditions => ["participations.type IN ('Jurisdiction', 'AssociatedJurisdiction')"],
    :order => 'created_at ASC'

  has_one :disease_event, :order => 'created_at ASC', :dependent => :delete

  belongs_to :event_queue
  has_many :form_references, :order => 'created_at ASC'
  has_many :forms, :through => :form_references
  has_many :answers, :autosave => true, :include => [:question]
  has_many :tasks, :order => 'due_date ASC'
  has_many :notes, :order => 'created_at ASC', :dependent => :destroy
  has_many :attachments, :order => 'updated_at DESC'

  has_many :participations

  has_many :place_child_events,
           :class_name => 'PlaceEvent',
           :foreign_key => 'parent_id',
           :order => "position, created_at ASC" do
    def active(reload=false)
      @active_places = nil if reload
      @active_places ||= PlaceEvent.find(:all,
        :conditions => ["parent_id = ? AND deleted_at IS NULL", proxy_owner.id],
        :order => "position, created_at ASC"
      )
    end
  end

  has_many :contact_child_events,
           :class_name => 'ContactEvent',
           :foreign_key => 'parent_id',
           :order => 'position, created_at ASC' do
    def active(reload=false)
      @active_contacts = nil if reload
      @active_contacts ||= ContactEvent.find(:all,
        :conditions => ["parent_id = ? AND deleted_at IS NULL", proxy_owner.id],
        :order => "position, created_at ASC"
      )
    end
  end

  has_many :encounter_child_events, :class_name => 'EncounterEvent', :foreign_key => 'parent_id' do
    def active(reload=false)
      @active_encounters = nil if reload
      @active_encounters ||= EncounterEvent.find(:all,
        :conditions => ["parent_id = ? AND deleted_at IS NULL", proxy_owner.id],
        :order => "created_at ASC"
      )
    end
  end

  has_many :child_events,
    :class_name => 'Event',
    :foreign_key => 'parent_id',
    :order => "created_at ASC"

  named_scope :active, :conditions => ['deleted_at IS NULL']
  named_scope :morbs_or_contacts,
    :conditions => ['type IN (?)', %w(MorbidityEvent ContactEvent)],
    :order => "created_at ASC"

  named_scope :sensitive, lambda { |user|
    jurisdiction_ids = user.jurisdiction_ids_for_privilege(:access_sensitive_diseases)
    jurisdiction_ids << "NULL" if jurisdiction_ids.empty?
    {
      :joins => "JOIN (SELECT a.event_id FROM participations a LEFT JOIN disease_events b on b.event_id = a.event_id LEFT JOIN diseases c ON disease_id = c.id WHERE (c.sensitive IS NULL or c.sensitive = false) OR ((a.type = 'Jurisdiction' OR a.type = 'AssociatedJurisdiction') AND a.secondary_entity_id IN (#{jurisdiction_ids.join(',')})) GROUP BY a.event_id) j ON events.id = j.event_id"
    }
  }

  named_scope :for_jurisdictions, lambda { |jurisdiction_ids|
    { :conditions => { :participations => { :secondary_entity_id => jurisdiction_ids } },
      :include => :all_jurisdictions }
  }

  # These are morbidity events that have been 'elevated' from contacts of this event
  has_many :morbidity_child_events, :class_name => 'MorbidityEvent', :foreign_key => 'parent_id' do
    def active(reload=false)
      @active_siblings = nil if reload
      @active_siblings ||= MorbidityEvent.find(:all, :conditions => ["parent_id = ? AND deleted_at IS NULL", proxy_owner.id])
    end
  end

  has_one :address

  belongs_to :parent_event, :class_name => 'Event', :foreign_key => 'parent_id'

  accepts_nested_attributes_for :jurisdiction,
    :reject_if => proc { |attrs| attrs["secondary_entity_id"].blank? }
  accepts_nested_attributes_for :disease_event,
    :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }
  accepts_nested_attributes_for :contact_child_events,
    :allow_destroy => true,
    :reject_if => proc { |attrs| check_contact_attrs(attrs) }
  accepts_nested_attributes_for :place_child_events,
    :allow_destroy => true,
    :reject_if => :place_exposure_blank?
  accepts_nested_attributes_for :encounter_child_events,
    :allow_destroy => true,
    :reject_if => proc { |attrs| check_encounter_attrs(attrs) }
  accepts_nested_attributes_for :notes,
    :reject_if => proc { |attrs| !attrs.has_key?('note') || attrs['note'].blank?}
  accepts_nested_attributes_for :address,
    :reject_if => proc { |attrs| attrs.all? { |k, v| v.blank? } }

  def self.check_contact_attrs(attrs)
    # Contact is an existing entity chosen from search
    return false if attrs["interested_party_attributes"].has_key?('primary_entity_id') and !attrs["interested_party_attributes"][:primary_entity_id].blank?

    # Contact is brand new
    person_empty = attrs["interested_party_attributes"]["person_entity_attributes"]["person_attributes"].all? { |k, v| v.blank? }
    phones_empty = attrs["interested_party_attributes"]["person_entity_attributes"]["telephones_attributes"].all? { |k, v| v.all? { |k, v| v.blank? } }
    disposition_empty = attrs["participations_contact_attributes"].all? { |k, v| v.blank? }

    (person_empty && phones_empty && disposition_empty) ? true : false
  end

  def place_exposure_blank?(attrs)
    attrs["interested_place_attributes"]["primary_entity_id"].nil? &&
      place_and_canonical_address_blank?(attrs["interested_place_attributes"]) &&
      nested_attributes_blank?(attrs["participations_place_attributes"])
  end

  def self.check_encounter_attrs(attrs)
    encounter_empty = attrs["participations_encounter_attributes"].all? do |k, v|
      if ((k == "user_id") ||  (k == "encounter_location_type"))
        true
      else
        v.blank?
      end
    end

    encounter_empty ? true : false
  end

  validates_date :results_reported_to_clinician_date, :allow_blank => true
  validates_existence_of :investigator, :allow_nil => true
  validates_numericality_of :acuity, :only_integer => true, :less_than => 100, :allow_nil => true
  validates_length_of :event_name, :maximum => 100, :allow_blank => true
  validates_length_of :other_data_1, :maximum => 255, :allow_blank => true
  validates_length_of :other_data_2, :maximum => 255, :allow_blank => true
  validates_length_of :outbreak_name, :maximum => 255, :allow_blank => true

  cattr_reader :per_page
  @@per_page = 25

  # Hack.  We want the some validations to fire only when being saved
  # directly, not indirectly as part of a morbidity event.  Morbs will
  # check related events explicitly.  This value should be set in the
  # controller, if it is being used
  attr_accessor :validate_against_bday

  def suppress_validation(validation)
    suppressed_validations << validation
  end

  def suppress_validation?(validation)
    suppressed_validations.include?(validation)
  end

  def suppressed_validations
    @suppressed_validations ||= []
  end

  class << self

    # Does not return full on Event objects. Returns find_by_sql-records.
    def exportable_ibis_records(start_date, end_date)
      active_sql = ibis_export_sql do
        <<-WHERE
          events.type = 'MorbidityEvent' AND
          events.deleted_at IS NULL AND
          (
            (events.created_at::date BETWEEN ?::date AND ?::date) OR
            (events.ibis_updated_at BETWEEN ? AND ?)
          )
        WHERE
      end

      deleted_sql = ibis_export_sql do
        <<-WHERE
          events.type = 'MorbidityEvent'
          AND events.sent_to_ibis = true
          AND events.deleted_at::date BETWEEN ?::date AND ?::date
        WHERE
      end

      Event.find_by_sql([active_sql, start_date, end_date, start_date, end_date]) + Event.find_by_sql([deleted_sql, start_date, end_date])
    end

    # Can receive either an array of event objects or an array of event records returned by a
    # find_by_sql where the ID is named event_id, hence the respond_to?
    def reset_ibis_status(events)
      event_ids = events.compact.collect do |record|
        if record.respond_to?(:event_id)
          record.event_id if record.event_id
        else
          record.id if record.id
        end
      end
      Event.update_all('sent_to_ibis=true', ['id IN (?)', event_ids])
    end

    def ibis_export_sql
      sql = <<-SQL
        SELECT
        events.id AS event_id,
        events.imported_from_id AS imported_from_id,
        events."first_reported_PH_date" AS first_reported_ph_date,
        events.age_at_onset AS age_at_onset,
        events.age_type_id AS age_type_id,
        events.created_at AS event_created_at,
        events.record_number AS record_number,
        events.deleted_at AS deleted_at,
        scsid.the_code AS event_case_status_code,
        lcsid.the_code AS event_lhd_case_status,
        diseases.cdc_code AS disease_cdc_code,
        disease_events.disease_onset_date AS disease_onset_date,
        disease_events.date_diagnosed AS disease_event_date_diagnosed,
        addresses.postal_code AS address_postal_code,
        cid.the_code AS address_county_code,
        cjid.short_name AS residence_jurisdiction_short_name,
        jurispl.short_name AS investigation_jurisdiction_short_name,
        intpplent.id AS interested_party_person_entity_id,
        ethid.the_code AS interested_party_ethnicity_code,
        sexid.the_code AS interested_party_sex_code
    FROM
        events
        LEFT OUTER JOIN disease_events
            ON disease_events.event_id = events.id
        JOIN diseases
            ON diseases.id = disease_events.disease_id
        LEFT OUTER JOIN addresses
            ON addresses.event_id = events.id
        LEFT JOIN external_codes cid
            ON cid.id = addresses.county_id
        LEFT JOIN places cjid
            ON cjid.id = cid.jurisdiction_id
        LEFT JOIN external_codes ifid
            ON ifid.id = events.imported_from_id
        LEFT JOIN external_codes scsid
            ON scsid.id = events.state_case_status_id
        LEFT JOIN external_codes oaid
            ON oaid.id = events.outbreak_associated_id
        LEFT JOIN external_codes lcsid
            ON lcsid.id = events.lhd_case_status_id
        LEFT JOIN external_codes disevhospid
            ON disevhospid.id = disease_events.hospitalized_id
        LEFT JOIN external_codes disevdiedid
            ON disevdiedid.id = disease_events.died_id
        JOIN participations juris
            ON juris.event_id = events.id AND juris.type = 'Jurisdiction'
        JOIN entities jurisent
            ON juris.secondary_entity_id = jurisent.id AND jurisent.entity_type = 'PlaceEntity'
        JOIN places jurispl
            ON jurispl.entity_id = juris.secondary_entity_id
        JOIN participations intpplpart
            ON intpplpart.type = 'InterestedParty' AND intpplpart.event_id = events.id
        JOIN entities intpplent
            ON intpplent.id = intpplpart.primary_entity_id
        JOIN people intppl
            ON intppl.entity_id = intpplpart.primary_entity_id
        LEFT JOIN external_codes ethid
            ON ethid.id = intppl.ethnicity_id
        LEFT JOIN external_codes sexid
            ON sexid.id = intppl.birth_gender_id
        WHERE
      SQL

      sql <<  yield
      sql << "order by events.id;"
    end

  end

  def short_type
    @short_type ||= self.type.sub(/event$/i, '')
  end

  def deleted?
    not deleted_at.nil?
  end

  def open_for_investigation?
    self.under_investigation? or self.investigation_complete? or self.reopened_by_manager?
  end

  # returns only the references for forms that should be rendered on
  # the investigation tab
  def investigation_form_references
    form_references.select {|ref| ref.form.has_investigator_view_elements?}
  end

  def core_only_form_references
    form_references.reject {|ref| ref.form.has_investigator_view_elements?}
  end

  def jurisdiction_of_investigation
    jurisdiction
  end

  def jurisdiction_entity_ids
    if new_record?
      [
        jurisdiction.try(:secondary_entity_id),
        associated_jurisdictions.map(&:secondary_entity_id)
      ].flatten.compact.uniq
    else
      Set.new(all_jurisdictions.map(&:secondary_entity_id))
    end
  end

  # wow. wish this didn't return the disease_event.
  def disease
    self.disease_event
  end

  def disease?
    !self.disease_event.try(:disease).nil?
  end

  def sensitive?
    self.disease_event.try(:disease).try(:sensitive)
  end

  def add_note(message, *note_type_and_options)
    options = note_type_and_options.extract_options!
    note_type = note_type_and_options.first || 'administrative'
    note = Note.new options.merge(:note => message, :note_type => note_type)
    self.notes << note
    note
  end

  def eager_load_answers
    self.answers
  end

  # Walks through all unsaved children of this event and assigns them the parent's disease and
  # jurisdiction.  Expected to be called after parent and children have been initially created
  # but not saved, i.e., from the morbidity_event controller, but should be called as needed.
  # Can't do this after the save, because we don't want to overwrite any user made changes to
  # existing records.
  def initialize_children
    parent_jurisdiction = nil
    if self.jurisdiction
      parent_jurisdiction = Jurisdiction.new
      parent_jurisdiction.secondary_entity_id = self.jurisdiction.secondary_entity_id
    end

    parent_disease_event = nil
    unless self.disease_event.nil?
      parent_disease_event = DiseaseEvent.new
      parent_disease_event.disease_id = self.disease_event.disease_id
    end

    # Can't use plain old child_events association 'cause nothin's been saved yet
    # new_record? because we don't wanna overwrite user-made changes
    (self.contact_child_events.select(&:new_record?) + self.place_child_events.select(&:new_record?)).each do |child|
      child.build_disease_event(parent_disease_event.attributes) unless parent_disease_event.nil?
      child.build_jurisdiction(parent_jurisdiction.attributes) unless parent_jurisdiction.nil?
    end
  end

  def add_forms(forms_to_add)
    forms_to_add = [forms_to_add] unless forms_to_add.respond_to?('each')
    return if forms_to_add.empty?

    # Accepts either form_ids or forms.  If forms, convert to form_ids
    forms_to_add.map! { |form_ref| if form_ref.is_a? Form then form_ref.id else form_ref.to_i end }

    existing_template_ids = self.form_references.map { |ref| ref.template_id }

    Event.transaction do
      unless (forms_to_add.all? do |form_id|
            form = Form.find(form_id)

            if existing_template_ids.detect {|template_id| template_id == form.template_id }
              # A version of this form already exists as a reference, just return true to make the forms_to_add.all? above happy
              true
            else
              self.form_references.create(:form_id => form_id, :template_id => form.template_id)
            end

          end)
        raise I18n.translate('unable_to_process_new_forms')
      end
    end
  end

  # Removes the reference to the form with the provided form ID.
  #
  # Returns true on success, nil on failure
  def remove_forms(form_ids)
    form_ids = [form_ids] unless form_ids.respond_to?('each')
    transaction do
      form_ids.each do |form_id|
        form_reference = FormReference.find_by_event_id_and_form_id(self.id, form_id)
        if form_reference.nil?
          raise I18n.translate('missing_form_reference')
        else
          question_elements = FormElement.find_all_by_form_id_and_type(form_id, "QuestionElement", :include => [:question])
          question_ids = question_elements.collect { |element| element.question.id}
          Answer.delete_all(["event_id = ? and question_id in (?)", self.id, question_ids])
          form_reference.destroy
        end
      end
      return true
    end
  rescue Exception => ex
    I18nLogger.warn("could_not_remove_form_from_event", :message => ex.message)
    return nil
  end

  def soft_delete
    Event.transaction do
      transactional_soft_delete
    end
  end

  def transactional_soft_delete
    if self.deleted_at.nil?
      self.deleted_at = Time.new
      self.add_note(I18n.translate('system_notes.event_deleted', :locale => I18n.default_locale))
      self.save!
      self.child_events.each { |child| child.transactional_soft_delete }
      true
    else
      nil
    end
  end

  def answers=(attributes)
    if answers.empty?
      answers.build(attributes.values)
    else
      answers.each { |answer| answer.attributes = attributes[answer.id.to_s] }
    end
  end

  def new_answers=(attributes)
    answers.build(attributes)
  end

  def new_checkboxes=(attributes)
    attributes.each do |key, value|
      answers.build(
        :question_id => key,
        :check_box_answer => value[:check_box_answer],
        :code => value[:code]
      )
    end
  end

  def new_radio_buttons=(attributes)
    attributes.each do |key, value|
      answers.build(
        :question_id => key,
        :radio_button_answer => value[:radio_button_answer],
        :export_conversion_value_id => value[:export_conversion_value_id],
        :code => value[:code]
      )
    end
  end

  # can't use #detect here because of http://jira.codehaus.org/browse/JRUBY-5058
  def get_or_initialize_answer(question_id)
    answers.each do |answer_object|
      return answer_object if answer_object.question_id == question_id
    end
    Answer.new(:question_id => question_id)
  end


  # Indicates whether an event supports tasks. Generally used by the UI in shared partials
  # to determine whether task-specific layout should be included.
  #
  # Sub-classes can either override this method to return true or use a declarative option:
  #
  # supports :tasks
  def supports_tasks?
    false
  end

  # Indicates whether an event supports attachements. Generally used by the UI in shared partials
  # to determine whether attachment-specific layout should be included.
  #
  # Sub-classes can either override this method to return true or use a declarative option:
  #
  # supports :attachments
  def supports_attachments?
    false
  end

  def clone_event(event_components=[])
    event_components = [] if event_components.nil?
    _event = self.class.new
    self.copy_event(_event, event_components)
    _event
  end

  def copy_event(new_event, event_components)
    new_event.suppress_validation(:first_reported_PH_date)
    new_event.event_name = "#{I18n.translate('copy_of', :locale => I18n.default_locale)} #{self.event_name}" unless self.event_name.blank?
    new_event.build_jurisdiction
    new_event.jurisdiction.secondary_entity = (User.current_user.jurisdictions_for_privilege(:create_event).first || Place.unassigned_jurisdiction).entity
    new_event.workflow_state = 'accepted_by_lhd' unless new_event.jurisdiction.place.is_unassigned_jurisdiction?
    new_event.acuity = self.acuity

    if event_components.include?("clinical")
      if self.disease_event
        new_event.build_disease_event(:hospitalized_id =>  self.disease_event.hospitalized_id,
          :died_id => self.disease_event.died_id,
          :disease_onset_date => self.disease_event.disease_onset_date,
          :date_diagnosed => self.disease_event.date_diagnosed)
      end
    end

    if event_components.include?("disease_specific")
      self.form_references.each do |form|
        new_event.form_references.build(:form_id => form.form_id, :template_id => form.template_id) # Can't use add_forms here since the new event isn't saved
      end

      self.answers.each do |answer|
        new_event.answers.build(:question_id => answer.question_id,
          :text_answer => answer.text_answer,
          :export_conversion_value_id => answer.export_conversion_value_id)
      end
    end

    if event_components.include?("notes")
      self.notes.each do |note|
        if note.note_type == "clinical"
          attrs = note.attributes
          attrs.delete('event_id')
          new_event.notes.build(attrs)
        end
      end
    end
  end

  def attempt_form_assignment_on_create
    return unless can_receive_auto_assigned_forms?
    create_form_references
    if (self.form_references.size > 0)
      self.form_references.each do |ref|
        ref.event_id = self.id
        ref.save
      end
    end
    self.update_attribute(:undergone_form_assignment, true)
  end

  def attempt_form_assignment_on_update
    return unless can_receive_auto_assigned_forms?
    create_form_references
    self.update_attribute(:undergone_form_assignment, true)
  end

  def can_receive_auto_assigned_forms?
    if self.disease_event.nil? || self.disease_event.disease_id.blank? || self.jurisdiction.nil? || self.undergone_form_assignment
      return false
    else
      return true
    end
  end

  class << self
    def supports(functionality)
      return unless [:tasks, :attachments].include?(functionality)
      supports_method = %Q{
        def supports_#{functionality.to_s}?
          true
        end
      }
      class_eval(supports_method)
    end
  end

  def events_quick_list(reload=false)
    if reload or @events_quick_list.nil?
      @events_quick_list = self.class.find_by_sql([<<-SQL, self.id, self.id])
        SELECT ev.id,
               ev.workflow_state,
               ev.type,
               TRIM(
                 COALESCE(pp.first_name, '')
                 || ' '
                 || COALESCE(pp.last_name, '')
               ) as full_name
          FROM events ev
          JOIN participations pt ON pt.event_id = ev.id AND pt.type = 'InterestedParty'
          JOIN entities en ON en.id = pt.primary_entity_id AND en.deleted_at IS NULL
          JOIN people pp ON pp.entity_id = en.id
         WHERE ev.parent_id = ?
           AND ev.type IN ('MorbidityEvent', 'ContactEvent')
           AND ev.deleted_at IS NULL
        UNION
        SELECT ev.id,
               ev.workflow_state,
               ev.type,
               pl.name as full_name
          FROM events ev
          JOIN participations pt ON pt.event_id = ev.id AND pt.type = 'InterestedPlace'
          JOIN entities en ON en.id = pt.primary_entity_id AND en.deleted_at IS NULL
          JOIN places pl ON pl.entity_id = en.id
         WHERE ev.parent_id = ?
           AND ev.type IN ('PlaceEvent')
           AND ev.deleted_at IS NULL;
      SQL
    else
      @events_quick_list
    end
  end

  def event_siblings_quick_list(reload=false)
    return [] if parent_event.nil?
    if reload or @event_siblings.nil?
      @event_siblings = parent_event.events_quick_list.reject { |event| event == self }
    else
      @event_siblings
    end
  end

  private

  def create_form_references
    return [] if self.disease_event.nil? || self.disease_event.disease_id.blank? || self.jurisdiction.nil?

    # In the case of a deep copy it's possible for an event to have forms associated with it even if it hasn't undergone form assigment formally.
    template_ids = self.form_references.collect { |fr| fr.template_id }
    i = self.form_references.size - 1
    Form.get_published_investigation_forms(self.disease_event.disease_id, self.jurisdiction.secondary_entity_id, self.class.name.underscore).each do |form|
      next if template_ids.include?(form.template_id)
      self.form_references[i += 1] = FormReference.new(:form_id => form.id, :template_id => form.template_id)
    end
    return true
  end

  # This method can be invoked by sub-classes before_create hooks in order to set
  # attributes on them which may be required for saving. Jurisdiction and disease
  # setting is also attempted by Event#initialize_children. The duplication that
  # occurs by having the before_create hooks call direct_child_creation_initialization
  # on the creation of a morbidity event with children doesn't incur any penalty
  # when saving from the morbidity event level b/c the parent_event.*.nil? checks
  # will return true in that scenario.
  def direct_child_creation_initialization
    build_jurisdiction_based_on_parent
    build_disease_based_on_parent
  end

  def build_jurisdiction_based_on_parent
    return if parent_event.nil? || parent_event.jurisdiction.nil? || !self.jurisdiction.nil?
    parent_jurisdiction = Jurisdiction.new
    parent_jurisdiction.secondary_entity_id = parent_event.jurisdiction.secondary_entity_id
    build_jurisdiction(parent_jurisdiction.attributes)
  end

  def build_disease_based_on_parent
    return if parent_event.nil? || parent_event.disease_event.nil? || !self.disease_event.nil?
    parent_disease_event = DiseaseEvent.new
    parent_disease_event.disease_id = parent_event.disease_event.disease_id
    build_disease_event(parent_disease_event.attributes)
  end
end
