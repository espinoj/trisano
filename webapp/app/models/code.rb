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

class Code < ActiveRecord::Base

  def self.other_place_type_id
    safe_table_access do
      @@other_place_type ||= find(:first, :conditions => "code_name = 'placetype' and the_code = 'O'")
      @@other_place_type.id unless @@other_place_type.nil?
    end
  end

  def self.telephone_location_type_id
    safe_table_access do
      @@telephone_location_type ||= find_by_code_name_and_the_code 'locationtype', 'TLT'
      @@telephone_location_type.id if @@telephone_location_type
    end
  end

  def self.address_location_type_id
    safe_table_access do
      @@address_location_type ||= find_by_code_name_and_the_code 'locationtype', 'ALT'
      @@address_location_type.id if @@address_location_type
    end
  end

  def self.jurisdiction_place_type_id
    safe_table_access do
      @@jurisdiction_place_type ||= Code.find_by_code_name_and_code_description('placetype', 'Jurisdiction')
      @@jurisdiction_place_type.id if @@jurisdiction_place_type
    end
  end

  def self.lab_place_type
    safe_table_access do
      @@lab_place_type ||= Code.find_by_code_name_and_the_code('placetype', 'L')
    end
  end

  def self.lab_place_type_id
    self.lab_place_type.id if self.lab_place_type
  end

  private
  
  def self.safe_table_access
    begin
      return yield if block_given?
    rescue
      logger.error "Error reading from the codes table. This sometimes happens when running rake"
    ensure
      nil
    end
  end
end