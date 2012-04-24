#RAILS_ROOT = "#{File.dirname(__FILE__)}/.."
require 'rubygems'
require 'bundler'

Bundler.require :default, :development

# Set the default environment to sqlite3's in_memory database
ENV['RAILS_ENV'] ||= 'test'


require 'blacklight/engine'
Combustion.initialize!

require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/rails'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

MARC_DATA_PATH = "#{File.dirname(__FILE__)}/marc_data"

# Undo changes to RAILS_ENV
silence_warnings {RAILS_ENV = ENV['RAILS_ENV']}

# Run the migrations
ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")


RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{File.expand_path(File.dirname(__FILE__))}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  
  ##
  # Load CqlRuby and our local patches to it, so available for tests
  # 
  require 'cql_ruby'  
  require File.expand_path(File.dirname(__FILE__) + '/../lib/blacklight_cql/blacklight_to_solr.rb')
end

