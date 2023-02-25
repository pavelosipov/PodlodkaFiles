require 'rake'
require_relative 'secrets_spec'

class DeployAppStep
  attr_accessor :api_token, :ipa_path, :dsym_path

  def run
    Rake.sh 'bundle exec fastlane ios distribute_app ' \
            "ipa_path:\"#{File.expand_path @ipa_path}\" " \
            "dsym_path:\"#{File.expand_path @dsym_path}\" " \
            "api_token:\"#{@api_token}\""
  end
end
