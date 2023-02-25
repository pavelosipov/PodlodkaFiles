require 'rake'
require_relative 'ci/pipeline_spec'

$pipeline = PipelineSpec.new('Pipefile')

desc 'Clears Xcode and SPM caches'
task :clear_caches do
  $pipeline.run :clear_caches
end

desc 'Installs Brew tools'
task :install_tools do
  $pipeline.run :install_tools
end

desc 'Installs Ruby gems'
task :install_gems do
  $pipeline.run :install_gems
end

desc 'Runs Swiftlint'
task :lint_app do
  $pipeline.run :lint_app
end

desc 'Runs lint_app step with its dependencies'
task lint_app_wired: %i[install_tools install_gems lint_app]

desc 'Builds both ipa and dsym archives'
task :build_app do
  $pipeline.run :build_app
end

desc 'Runs lint_app step with its dependencies'
task build_app_wired: %i[install_tools install_gems build_app]

desc 'Uploads to AppCenter'
task :deploy_app do
  $pipeline.run :deploy_app
end

desc 'Runs lint_app step with its dependencies'
task deploy_app_wired: %i[install_tools install_gems deploy_app]

desc 'Performs all steps oredred by Pipefile'
task :all do
  $pipeline.run_all
end

task default: :all
