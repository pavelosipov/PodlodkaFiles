source 'https://rubygems.org/'

gem 'fastlane'
gem 'rubocop'
gem 'rubocop-rake'

group :development, optional: true do
  gem 'solargraph'
  gem 'yard'
end

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
