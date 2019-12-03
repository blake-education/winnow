ENV["RAILS_ENV"] = 'test'

require File.join(__dir__, 'dummy/config/environment.rb')
require "winnow"

Rails.backtrace_cleaner.remove_silencers!

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = "random"
end
