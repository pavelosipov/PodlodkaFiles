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

desc 'Builds both ipa and dsym archives'
task :build_app do
  $pipeline.run :build_app
end

desc 'Upload to AppCenter'
task :deploy_app do
  $pipeline.run :deploy_app
end
