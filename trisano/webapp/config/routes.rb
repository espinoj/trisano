# Copyright (C) 2007, 2008, The Collaborative Software Foundation
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

ActionController::Routing::Routes.draw do |map|
  map.resources :diseases

  map.resources :event_queues

  
  map.home '', :controller => 'dashboard'
  
  map.with_options :controller => 'search' do |search|
    search.search_cmrs   'search/cmrs',         :action => 'cmrs'
    search.cmrs_format   'search/cmrs.:format', :action => 'cmrs'
    search.search_people 'search/people',       :action => 'people'
    search.search        'search'
  end

  map.export 'export/cdc.:format', :controller => 'export', :action => 'cdc'
  
  map.admin 'admin', :controller => 'admin'
  map.builder 'forms/builder/:id', :controller => 'forms', :action => 'builder'
  map.form_rollback 'forms/rollback/:id', :controller => 'forms', :action => 'rollback'
  map.open_library 'forms/library_admin/:type', :controller => 'forms', :action => 'library_admin'
  map.order_section_children 'forms/order_section_children/:id', :controller => 'forms', :action => 'order_section_children'
  map.toggle_value 'value_set_elements/toggle_value/:value_element_id', :controller => 'value_set_elements', :action => 'toggle_value'

  map.resources :forms, :member => {
    :copy => :post,
    :export => :post
  }

  map.resources :external_codes

  map.resources :question_elements
  
  map.resources :group_elements

  map.resources :section_elements

  map.resources :value_set_elements
  
  map.resources :core_view_elements
  
  map.resources :core_field_elements
  
  map.resources :view_elements
  
  map.resources :form_elements, :member => { :to_library => :post }, :member => { :from_library => :post }
  
  map.resources :follow_up_elements

  map.resources :users
  
  map.resources :cmrs, 
    :controller => :morbidity_events,
    :member => { :state => :post, :jurisdiction => :post }

  map.resources :contact_events

  map.resources :codes, :controller => :external_codes

  map.resources :place_events

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
