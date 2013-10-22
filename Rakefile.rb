# -*- coding: utf-8 -*-
require "yaml"
require "active_record"
require "activerecord-import"

ProjectRoot = File.dirname(File.absolute_path(__FILE__))
connection_details = YAML::load(File.open('config/database.yml'))

namespace :db do
  db_name = connection_details["database"]

  desc "Create the db"
  task :create do
    ActiveRecord::Base.connection.create_database(db_name)
  end
  
  desc "Migrate the db"
  task :migrate do
    ActiveRecord::Migrator.migrate("db/migrate")
  end
  
  desc "Drop the db"
  task :drop do
    ActiveRecord::Base.connection.drop_database(connection_details.fetch('database'))
  end

  tasks = Rake.application.instance_variable_get('@tasks')
  tasks.keys.each do |task_name| 
    next unless task_name.start_with? "db:"
    old_task = tasks.delete(task_name.to_s)
    desc old_task.full_comment    
    task task_name.split(":")[1] do
      connection_details.delete "database" if task_name == "db:create"
      ActiveRecord::Base.establish_connection(connection_details)
      old_task.invoke
    end
  end
end

namespace :se do
  require "#{ProjectRoot}/app/crawler"
  Dir.glob(ProjectRoot + "/app/models/*.rb").each {|f| require f}    

  desc "爬页面"
  task :crawl do
    ActiveRecord::Base.establish_connection(connection_details)
    Crawler.new(["http://guides.rubyonrails.org/"]).crawl
  end
end
