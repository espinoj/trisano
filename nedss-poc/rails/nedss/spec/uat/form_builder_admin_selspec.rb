require File.dirname(__FILE__) + '/spec_helper'

# $dont_kill_browser = true

describe 'Form Builder Admin' do
  
  before(:all) do
    @form_name = get_unique_name(4) + " fb uat"
    
    @question_to_add_to_library_text = "Was this added to the library " + get_unique_name(4) + " fb uat" 
    @question_to_delete_text = "Describe the tick " + get_unique_name(4) + " fb uat" 
    @question_to_edit_text = "Can you describe the tick " + get_unique_name(4) + " fb uat" 
    @question_to_edit_modified_text = "Can you describe the tick edited " + get_unique_name(4) + " fb uat" 
    @question_to_inactivate_text = "Did you see the tick that got you " + get_unique_name(4) + " fb uat" 
    
    @user_defined_tab_text = "User-defined tab " + get_unique_name(3) + " fb uat"
    @user_defined_tab_section_text = "User-defined tab section " + get_unique_name(3) + " fb uat"
    @user_defined_tab_question_text = "User-defined tab questoin " + get_unique_name(3) + " fb uat" 
    
    @cmr_last_name = get_unique_name(1) + " fb uat"
  end
  
  after(:all) do
    @form_name = nil
    @question_to_delete_text = nil
    @question_to_edit_text = nil
    @question_to_edit_modified_text = nil
    @cmr_last_name = nil
  end
  
  it 'should create a new form and allow navigation to builder' do
    create_new_form_and_go_to_builder(@browser, @form_name, "African Tick Bite Fever", "All Jurisdictions")
  end
  
  # Debt: The remaining examples had to be combined into one in order to have access
  # to saved IDs across what used to be separate examples.
  # The methods provide some segmentation of all of the activities of the large example.
  it 'should do all this stuff...' do
    
    to_and_from_library_no_group
    to_and_from_library_new_group
    add_a_section
    add_questions
    reorder_elements
    add_value_sets
    edit_value_sets
    add_and_populate_tab
    publish_form(@browser)
    @browser.is_text_present("Form was successfully published").should be_true
    validate_investigator_rendering
    navigate_to_form_edit
    delete_edit_and_inactivate_questions
    publish_form(@browser)
    @browser.is_text_present("Form was successfully published").should be_true
    revalidate_investigator_rendering

  end
end

def add_a_section
  @browser.click "link=Add section to tab"
  wait_for_element_present("new-section-form")
  @browser.type "section_element_name", "Section 1"
  @browser.click "section_element_submit"
  wait_for_element_not_present("new-section-form")
  @browser.is_text_present("Section 1").should be_true

  @reorderable_section_id = "section_#{@browser.get_value("id=modified-element")}_children"
end

def add_questions
  add_question_to_section(@browser, "Section 1", "Did you go into the tall grass?", "Drop-down select list")
  @browser.is_text_present("Did you go into the tall grass?").should be_true
  
  add_question_to_section(@browser, "Section 1", @question_to_inactivate_text, "Drop-down select list")
  @browser.is_text_present(@question_to_inactivate_text).should be_true
    
  @question_to_inactivate_id = @browser.get_value("id=modified-element")
  
  add_question_to_section(@browser, "Section 1", @question_to_delete_text, "Multi-line text")
  @browser.is_text_present(@question_to_delete_text).should be_true
    
  @question_to_delete_id = @browser.get_value("id=modified-element")
  
  add_question_to_section(@browser, "Section 1", @question_to_edit_text, "Drop-down select list")
  @browser.is_text_present(@question_to_edit_text).should be_true
    
  @question_to_edit_id = @browser.get_value("id=modified-element")
end

def add_value_sets
  @browser.click "link=Add value set"
  wait_for_element_present("new-value-set-form")
  @browser.type "value_set_element_name", "Yes/No/Maybe"
  @browser.click "link=Add a value"
  @browser.click "link=Add a value"
  @browser.click "link=Add a value"
  wait_for_element_present("value_set_element_new_value_element_attributes__name")
  @browser.type "value_set_element_new_value_element_attributes__name", "Yes"
  @browser.type "document.forms['value-set-element-new-form'].elements['value_set_element[new_value_element_attributes][][name]'][1]", "No"
  @browser.type "document.forms['value-set-element-new-form'].elements['value_set_element[new_value_element_attributes][][name]'][2]", "Maybe"
  @browser.click "value_set_element_submit"
  wait_for_element_not_present("new-value-set-form")
  @browser.is_text_present("Yes/No/Maybe").should be_true
  @browser.click "link=Add value set"
  wait_for_element_present("new-value-set-form")
  @browser.type "value_set_element_name", "Yes/No"
  @browser.click "link=Add a value"
  @browser.click "link=Add a value"
  wait_for_element_present("value_set_element_new_value_element_attributes__name")
  @browser.type "value_set_element_new_value_element_attributes__name", "Yes"
  @browser.type "document.forms['value-set-element-new-form'].elements['value_set_element[new_value_element_attributes][][name]'][1]", "No"
  @browser.click "value_set_element_submit"
  wait_for_element_not_present("new-value-set-form")
  @browser.click "link=Add value set"
  wait_for_element_present("new-value-set-form")
  @browser.type "value_set_element_name", "Yes/No"
  @browser.click "link=Add a value"
  @browser.click "link=Add a value"
  wait_for_element_present("value_set_element_new_value_element_attributes__name")
  @browser.type "value_set_element_new_value_element_attributes__name", "Yes"
  @browser.type "document.forms['value-set-element-new-form'].elements['value_set_element[new_value_element_attributes][][name]'][1]", "No"
  @browser.click "value_set_element_submit"
  wait_for_element_not_present("new-value-set-form")
end

def reorder_elements
  @browser.get_eval("nodes = window.document.getElementById(\"#{@reorderable_section_id}\").getElementsByTagName('li'); firstItem =nodes[0].id.toString().substring(9); secondItem =nodes[1].id.toString().substring(9); firstItem > secondItem").should == "false"
  @browser.drag_and_drop "//ul[@id='#{@reorderable_section_id}']/li[2]", "0,-40"
  sleep(2)
  @browser.get_eval("nodes = window.document.getElementById(\"#{@reorderable_section_id}\").getElementsByTagName('li'); firstItem =nodes[0].id.toString().substring(9); secondItem =nodes[1].id.toString().substring(9); firstItem > secondItem").should == "true"
end

def edit_value_sets
  @browser.click "link=Edit value set"
  wait_for_element_present("edit-value-set-form")
  @browser.is_element_present("edit-value-set-form").should be_true
  @browser.type "value_set_element_name", "Edited"
  @browser.click "link=Remove"
  @browser.click "link=Remove"
  @browser.click "value_set_element_submit"
  wait_for_element_not_present("edit-value-set-form")
  @browser.click "link=Edit value set"
  wait_for_element_present("edit-value-set-form")
    
  @browser.type "document.forms['value-set-element-edit-form'].elements[4]", "Edited value"
  sleep(5)
  @browser.check "document.forms['value-set-element-edit-form'].elements[6]"
    
  @browser.click "value_set_element_submit"
  wait_for_element_not_present("edit-value-set-form")
    
  @browser.is_text_present("Edited value").should be_true
  @browser.is_text_present("Maybe").should be_false
  @browser.is_text_present("Inactive").should be_true
  
  @browser.click "link=Edit value set"
  wait_for_element_present("edit-value-set-form")
  @browser.click "link=Add a value"
  wait_for_element_present("value_set_element_new_value_element_attributes__name")
  @browser.type "value_set_element_new_value_element_attributes__name", "Added after value"
  @browser.click "value_set_element_submit"
  wait_for_element_not_present("edit-value-set-form")
  @browser.is_text_present("Added after value").should be_true
end

def add_and_populate_tab
  
  @browser.click "link=Add a tab"
  wait_for_element_present("new-view-form")
  @browser.type "view_element_name", @user_defined_tab_text
  @browser.click "view_element_submit"
  wait_for_element_not_present("new-view-form")
  
  @tab_element_id = @browser.get_value("id=modified-element")
  
  @browser.click "id=add-section-#{@tab_element_id}"
  wait_for_element_present("new-section-form")
  @browser.type "section_element_name", @user_defined_tab_section_text
  @browser.click "section_element_submit"
  wait_for_element_not_present("new-section-form")
  @browser.is_text_present(@user_defined_tab_text).should be_true

  @tab_section_element_id = @browser.get_value("id=modified-element")

  add_question_to_section(@browser, @user_defined_tab_section_text, @user_defined_tab_question_text, "Single line text")
  @browser.is_text_present(@user_defined_tab_question_text).should be_true
end

def to_and_from_library_no_group
  
  add_question_to_view(@browser, "Default View", @question_to_add_to_library_text, "Single line text")
  num_times_text_appears(@browser, @question_to_add_to_library_text).should == 1
  @browser.click "link=Copy to library"
  wait_for_element_present("new-group-form")
  @browser.click "link=No Group"
  sleep(2)
  num_times_text_appears(@browser, @question_to_add_to_library_text).should == 2
  @browser.click "link=Close"

  @browser.click "link=Add question to tab"
  wait_for_element_present("new-question-form")
  @browser.click "link=#{@question_to_add_to_library_text}"
  sleep(2)
  num_times_text_appears(@browser, @question_to_add_to_library_text).should == 2 #library closed or would be 3
end

def to_and_from_library_new_group
  group_name = get_unique_name(3)
  @browser.click "link=Copy to library"
  wait_for_element_present("new-group-form")
  @browser.type "group_element_name", group_name
  @browser.click "group_element_submit"    
  sleep(2)
  @browser.click "link=Add question to: #{group_name}"
  sleep(2)
  num_times_text_appears(@browser, @question_to_add_to_library_text).should == 4
  @browser.click "link=Close"
end

def validate_investigator_rendering  
  create_basic_investigatable_cmr(@browser, @cmr_last_name, "African Tick Bite Fever", "Bear River Health Department")
  @browser.click "edit_cmr_link"
  @browser.wait_for_page_to_load($load_time)
  @browser.is_text_present(@question_to_delete_text).should be_true
  @browser.is_text_present(@question_to_edit_text).should be_true
  @browser.is_text_present(@question_to_inactivate_text).should be_true
  @browser.is_text_present(@question_to_edit_modified_text).should be_false
  @browser.is_text_present(@user_defined_tab_text).should be_true
  @browser.is_text_present(@user_defined_tab_section_text).should be_true
  @browser.is_text_present(@user_defined_tab_question_text).should be_true
end

def navigate_to_form_edit
  @browser.click "link=Forms"
  @browser.wait_for_page_to_load($load_time)
  click_build_form(@browser, @form_name)
end

def delete_edit_and_inactivate_questions
  @browser.click "id=delete-question-#{@question_to_delete_id}"
  wait_for_element_present("modified-element")
    
  @browser.click "id=edit-question-#{@question_to_edit_id}"
  wait_for_element_present("edit-question-form")
  @browser.type "question_element_question_attributes_question_text", @question_to_edit_modified_text
  @browser.click "question_element_submit"    
  wait_for_element_not_present("edit-question-form")
  @browser.is_text_present(@question_to_edit_text).should be_false
  @browser.is_text_present(@question_to_edit_modified_text).should be_true
    
  @browser.click "id=edit-question-#{@question_to_inactivate_id}"
  wait_for_element_present("edit-question-form")
  @browser.click "question_element_is_active_false"
  @browser.click "question_element_submit"    
  wait_for_element_not_present("edit-question-form")
end

def revalidate_investigator_rendering
  @browser.click "link=View CMRs"
  @browser.wait_for_page_to_load($load_time)
  click_resource_edit(@browser, "cmrs", @cmr_last_name)
  @browser.is_text_present(@question_to_delete_text).should be_false
  @browser.is_text_present(@question_to_edit_text).should be_false
  @browser.is_text_present(@question_to_inactivate_text).should be_false
  @browser.is_text_present(@question_to_edit_modified_text).should be_true
end
