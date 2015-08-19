require 'bundler/setup'
Bundler.require

require 'rake'
require 'yaml/store'
require 'ostruct'

Dir[File.join(File.dirname(__FILE__), '../app/models', '*.rb')].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), '../lib/support', '*.rb')].each { |f| require f }
DBConnection.instance.dbname = 'dynamic_orm_development'

RAKE_APP ||= begin
  app = Rake.application
  app.init
  app.load_rakefile
  app
end
