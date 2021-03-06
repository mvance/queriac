# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Load sensitive data like database and SMTP passwords into the environment..
require File.join(File.dirname(__FILE__), 'secrets')

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

#needs to be placed before initializer b/c routes
STATIC_PAGES = %w(options_tutorial tutorial setup help features)

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_queriac_session',
    :secret      => '2f9275c3303b81678fb1d8dadedf5941c741ca79cf0924d5d154e614f6f2b2f1da0b26bad096d323ec3fd59222087751c2564ff854b40793e94942172df02665'
  }
  
  config.action_mailer.delivery_method = :smtp
  
  config.active_record.observers = :user_observer
  
  config.gem "hpricot"

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
end

Time::DATE_FORMATS[:short] = "%B %d, %l:%M%p"
Time::DATE_FORMATS[:medium] = "%B %d, %Y"
Time::DATE_FORMATS[:blog] = "%A, %B %d at %l:%M%p"
Time::DATE_FORMATS[:long] = "%A, %B %d at %l:%M%p"
Time::DATE_FORMATS[:ymdhms] = Time::DATE_FORMATS[:batch] = "%Y%m%d%H%M%S"

DEFAULT_PARAM = "(q)"
OPTION_NAME_REGEX = '\w+'
#option is a word with a optional metadata delimited by '=' ie [:type=normal]
OPTION_PARAM_REGEX = /\[:(#{OPTION_NAME_REGEX})(=[^\[\]]+)?\]/    

ExceptionNotifier.exception_recipients = %w(zeke@queri.ac gabriel.horner@gmail.com)
ExceptionNotifier.sender_address = %("Application Error" <admin@queri.ac>)
ExceptionNotifier.email_prefix = "[queriac] "

# Include your application configuration below
require 'open-uri'
require 'hpricot'

common_stopwords = %w(user_commands commands tags queries users opensearch)
COMMAND_STOPWORDS = %w(default_to delete search_form search_all execute update tag_set tag_add_remove find_by_ids) + common_stopwords + Command::TYPES.map {|e| e.to_s}
USER_STOPWORDS = %w(home settings) + STATIC_PAGES + common_stopwords
HOST = 'localhost:3000' unless Object.const_defined?('HOST')