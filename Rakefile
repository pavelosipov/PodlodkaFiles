require 'rake'
require_relative 'ci/app_builder'
require_relative 'ci/secrets_spec'
require_relative 'ci/xcodebuild'

# Configuration

$build_root_path = 'build'
$app_build_path = "#{$build_root_path}/app"
$app_project_path = 'PodlodkaFiles.xcodeproj'
$app_target_name = 'PodlodkaFiles'

# Global variables

$ipa_path = nil
$dsym_path = nil

# Tasks

desc 'Clears Xcode and SPM caches'
task :clear_caches do
  [
    $build_root_path,
    '~/Library/Developer/Xcode/DerivedData',
    '~/Library/org.swift.swiftpm',
    '~/Library/Caches/org.swift.swiftpm'
  ]
  .select { |path| File.exist?(path) }
  .each do |path|
    puts "Removing #{path}"
    FileUtils.remove_dir(File.expand_path(path))
  end
end

desc 'Installs Brew tools'
task :install_tools do
  Rake.sh 'brew bundle'
end

desc 'Installs Ruby gems'
task :install_gems do
  Rake.sh 'bundle install'
end

desc 'Resolves SPM dependencies'
task :resolve_app_dependencies do
  XcodeBuild.resolve_dependencies()
end

desc 'Runs Swiftlint'
task :lint_app do
  Rake.sh 'bundle exec fastlane ios lint'
end

desc 'Builds both ipa and dsym archives'
task :build_app do
  $ipa_path, $dsym_path = AppBuilder.build($app_project_path, $app_target_name, $app_build_path, true)
end

desc 'Upload to AppCenter'
task :distribute_app do
  spec = SecretsSpec.new(File.expand_path('~/.local_ci/PodlodkaFiles/Secretsfile'))
  $ipa_path = 'build/app/PodlodkaFiles.ipa'
  $dsym_path = 'build/app/PodlodkaFiles.dSYM.zip'
  raise 'ipa file does not exist' unless File.exist? $ipa_path
  raise 'dsym archive does not exist' unless File.exist? $dsym_path
  Rake.sh 'bundle exec fastlane ios distribute_app ' \
          "ipa_path:\"#{File.expand_path $ipa_path}\" " \
          "dsym_path:\"#{File.expand_path $dsym_path}\" " \
          "api_token:\"#{spec.secrets[:APPCENTER_API_TOKEN]}\""
end
