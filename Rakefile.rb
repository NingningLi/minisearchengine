# -*- coding: utf-8 -*-
require "yaml"
require "active_record"
require "activerecord-import"
require "redis"
require "json"
require "rack"

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
  require "#{ProjectRoot}/app/searcher"
  require "#{ProjectRoot}/app/searcher_page/searcher_page"

  Dir.glob(ProjectRoot + "/app/models/*.rb").each {|f| require f}    

  desc "爬页面"
  task :crawl do
    ActiveRecord::Base.establish_connection(connection_details)
    Crawler.new(["http://kqis.me/"]).crawl
  end

  desc "执行索引"
  task :index do
    ActiveRecord::Base.establish_connection(connection_details)
    Crawler.index_pages
  end

  desc "搜索"
  task :search do
    ActiveRecord::Base.establish_connection(connection_details)
    Rack::Handler::WEBrick.run SearcherPage.get_app, :Port => 9293
  end

end
