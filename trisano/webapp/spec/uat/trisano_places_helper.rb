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

require File.dirname(__FILE__) + '/spec_helper'

module TrisanoPlacesHelper

  def add_place(browser, place_attributes, index = 1)
    click_core_tab(browser, EPI)
    browser.click "link=Add a Place Exposure"
    sleep(1)
    browser.type("//div[@class='place_exposure'][#{index}]//input[contains(@id, 'name')]", place_attributes[:name])
  end

  def save_place_event(browser)
    browser.click "save_and_exit_btn"
    browser.wait_for_page_to_load($load_time)
    return(browser.is_text_present("Place event was successfully created.") or
        browser.is_text_present("Place event was successfully updated."))
  end
  
end
