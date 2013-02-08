require 'mo_test_helpers'
require 'rspec/expectations'
require "watir-webdriver"
require 'capybara'
require "selenium-webdriver"
require 'pp'
require 'mo_test_helpers/selenium_helper'

module MoTestHelpers
  
  class Cucumber
    
    class << self
      attr_accessor :engine
    
      def configure
        yield self
      end
    end
    
  end
  
end

MoTestHelpers::Cucumber.configure do |config|
  config.engine = :watir
end

puts "Running with engine: #{MoTestHelpers::Cucumber.engine}"
puts "Running in CI: #{ENV['CI']}"
puts "Running Headless: #{ENV['HEADLESS']}"

# should we run headless? Careful, CI does this alone!
if ENV['HEADLESS'] and not ENV['CI']
  puts "Starting headless..."
  require 'headless'

  headless = Headless.new
  headless.start
  at_exit do
    headless.destroy
  end
end

# Validate the browser
MoTestHelpers::SeleniumHelper.validate_browser!

# see if we are running on MO CI Server
if ENV['CI'] and not ENV['SELENIUM_GRID_URL']
  puts "Running Cucumber in CI Mode."

  if MoTestHelpers::Cucumber.engine == :capybara
    raise ArgumentError.new('Please give the URL to the Rails Server!') if ENV['URL'].blank?

    Capybara.app_host = ENV['URL']
    Capybara.register_driver :selenium do |app|
      MoTestHelpers::SeleniumHelper.grid_capybara_browser(app)
    end
  else
    browser = MoTestHelpers::SeleniumHelper.grid_watir_browser
  end
else
  if MoTestHelpers::Cucumber.engine == :capybara
    Capybara.register_driver :selenium do |app|
      MoTestHelpers::SeleniumHelper.capybara_browser(app)
    end
  else
    browser = MoTestHelpers::SeleniumHelper.watir_browser
  end
end

if MoTestHelpers::Cucumber.engine == :capybara
  Capybara.server_port = ENV['SERVER_PORT'] || 3001
end

# "before all"
Before do
  if MoTestHelpers::Cucumber.engine == :watir
    puts "Running Watir Browser."

    @browser = browser

    unless ENV['URL']
      ENV['URL'] = 'http://localhost:3000/'
      puts "Warning: Using default URL localhost:3000 because ENV URL is not given."
    end

    @base_url = ENV['URL']
    @browser.goto ENV['URL']
  end
end

# "after all"
at_exit do
  if @browser
    puts "Closing Watir browser."
    @browser.close unless ENV["STAY_OPEN"]
  end
end