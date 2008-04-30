require File.dirname(__FILE__) + '/../../spec_helper'

describe "/forms/builder.html.haml" do
  include FormsHelper
  
  before(:each) do
    @form = mock_model(Form)
    @base_element = mock_model(FormBaseElement)
    @view_element = mock_model(ViewElement)
    @section_element = mock_model(SectionElement)
    @question_element = mock_model(QuestionElement)
    @question = mock_model(Question)
    
    @form.stub!(:name).and_return("MyString")
    @form.stub!(:description).and_return("MyString")
    @form.stub!(:description).and_return("MyString")
    @form.stub!(:form_base_element).and_return(@base_element)
    
    @base_element.stub!(:children).and_return([@view_element])
    @view_element.stub!(:children).and_return([@section_element])
    @section_element.stub!(:name).and_return("Section Name")
    @section_element.stub!(:children).and_return([@question_element])
    @question_element.stub!(:question).and_return(@question)
    @question.stub!(:question_text).and_return("Que?")
    
    assigns[:form] = @form
  end

  it "should have basic form info and links'" do
    render "/forms/builder.html.haml"
    response.should have_text(/Builder/)
    response.should have_text(/MyString/)
    response.should have_text(/Add a question/)
    
  end
end

