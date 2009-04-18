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

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

namespace :trisano do

  namespace :dev do
       
    # You can invoke a Rake task with Rake::Task["db:create:all"].invoke, but the fixture loading
    # step below fails. Dig into that at some point.
    desc "full rebuild of all databases"
    task :db_rebuild_full do
      puts "doing full rebuild of all databases"
      sh "dropdb trisano_development; createdb -E UTF8 trisano_development" # there is an issue with observer that necessitates this, but also we can explicitly set the encoding which is useful
      ruby "-S rake db:drop:all"
      ruby "-S rake db:create:all"
      ruby "-S rake db:schema:load"
      ruby "-S rake db:migrate"
      Rake::Task["trisano:dev:load_codes_and_defaults"].invoke
      Rake::Task["db:test:prepare"].invoke
    end
    
    # may be able to delete this - 24-oct-08: build box no longer using
    desc "full rebuild of all databases for the build server"
    task :db_rebuild_full_for_build  => ['trisano:deploy:stoptomcat', 'db_rebuild_full'] do
    end
    
    desc "update locale configs"
    task :update_locale_configs => [:update_dev_locale_config, :update_test_locale_config] do
    end
    
    desc "update dev locale config"
    task :update_dev_locale_config do
      update_locale_config("trisano_development")
    end
    
    desc "update test locale config"
    task :update_test_locale_config do
      update_locale_config("trisano_test")
    end
    
    def update_locale_config(env)
      sh "psql #{env} -c \"UPDATE pg_ts_cfg SET LOCALE = current_setting('lc_collate') WHERE ts_name = 'default'\""
    end

    desc "Load codes and defauts into database"
    task :load_codes_and_defaults => [:load_codes, :load_defaults] do
    end

    desc "Load codes into database"
    task :load_codes do
      ruby "#{RAILS_ROOT}/script/runner #{RAILS_ROOT}/script/load_codes.rb"
    end

    desc "Load defaults into database"
    task :load_defaults do
      ruby "#{RAILS_ROOT}/script/runner #{RAILS_ROOT}/script/load_defaults.rb"
      ruby "#{RAILS_ROOT}/script/runner #{RAILS_ROOT}/script/load_cdc_export_data.rb"
      ruby "#{RAILS_ROOT}/script/runner #{RAILS_ROOT}/script/load_cdc_export_data_for_disease_core.rb"
      ruby "#{RAILS_ROOT}/script/runner #{RAILS_ROOT}/script/load_disease_export_statuses.rb"
      ruby "#{RAILS_ROOT}/script/runner #{RAILS_ROOT}/script/load_csv_defaults.rb"
    end

    # Debt: dry this up
    desc "Prep work for feature (cucumber) runs"
    task :feature_prep do
      ruby "#{RAILS_ROOT}/script/runner -e test #{RAILS_ROOT}/script/load_codes.rb"
      ruby "#{RAILS_ROOT}/script/runner -e test #{RAILS_ROOT}/script/load_defaults.rb"
    end

    desc "Run standard features"
    task :standard_features do
      sh "cucumber features/standard -n -p standard"
    end

    desc "Run enhanced features"
    task :enhanced_features do
      sh "cucumber features/enhanced -n -p enhanced"
    end

  end
  
end