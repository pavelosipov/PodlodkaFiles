require_relative 'build_app_step'
require_relative 'clear_caches_step'
require_relative 'deploy_app_step'
require_relative 'pipeline_spec'
require_relative 'secrets_spec'
require_relative 'shell_step'

class PipelineSpec
  attr_reader :type
  attr_reader :secrets
  attr_accessor :build_path

  def initialize(path)
    @type = :local
    @secrets = SecretsSpec.new(File.expand_path('~/.local_ci/PodlodkaFiles/Secretsfile')).secrets
    @build_path = 'build'
    @steps = {}
    instance_eval(File.read path)
  end

  def run(tag)
    @steps[tag].run()
  end

  def sh(tag)
    step = ShellStep.new
    yield step
    @steps[tag] = step
  end

  def clear_caches_step
    @steps[:clear_caches]
  end

  def clear_caches
    step = ClearCachesStep.new
    yield step
    step.paths.append(@build_path)
    @steps[:clear_caches] = step
  end

  def build_app_step
    @steps[:build_app]
  end

  def build_app
    step = BuildAppStep.new
    yield step
    step.build_path = "#{@build_path}/app"
    @steps[:build_app] = step
  end

  def deploy_app_step
    @steps[:deploy_app]
  end

  def deploy_app
    step = DeployAppStep.new
    yield step, self
    step.ipa_path = build_app_step.ipa_path
    step.dsym_path = build_app_step.dsym_path
    @steps[:deploy_app] = step
  end
end
