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

require File.dirname(__FILE__) + '/../spec_helper'

describe Question do
  before(:each) do
    @question = Question.new
    @question.question_text = "Did you eat the fish?"
    @question.data_type = "single_line_text"
    @question.help_text = 's' * 1000
  end

  it "should be valid" do
    @question.should be_valid
  end

  it 'should produce an error if the help text is too long' do
    @question.help_text = 's' * 1001
    @question.should_not be_valid
    @question.errors.size.should == 1
    @question.errors.on(:help_text).should_not be_nil
  end

  it 'should produce an error if the question text is too long' do
    @question.question_text = 's' * 1001
    @question.should_not be_valid
    @question.errors.size.should == 1
    @question.errors.on(:question_text).should_not be_nil
  end

end
