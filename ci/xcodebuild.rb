require 'rake'
require_relative 'shell'

module XcodeBuild
  ARGS_MAP = {
    archive_path: 'archivePath',
    allow_internal_distribution: 'allow-internal-distribution'
  }.freeze

  extend self

  def resolve_dependencies
    Rake.sh 'set -o pipefail && xcodebuild -resolvePackageDependencies -onlyUsePackageVersionsFromResolvedFile | xcbeautify'
  end

  def build_archive(options)
    run("archive #{stringify_options(options)} | xcbeautify")
  end

  def run(command)
    jobs_count = Shell.run('sysctl -n hw.ncpu').to_i
    Rake.sh "set -o pipefail && xcodebuild IDEBuildOperationMaxNumberOfConcurrentCompileTasks=#{jobs_count} #{command}"
  end

  private

  def stringify_options(options)
    command = ''
    options.except(:flags).each_pair { |k, v| command += "#{stringify_option(k, v)} " }
    options[:flags].each_pair { |k, v| command += "#{stringify_flag(k, v)} " } if options.key? :flags
    command.strip
  end

  def stringify_flag(key, value)
    "#{key}=#{value}"
  end

  def stringify_option(key, value)
    "-#{stringify_key(key)} #{stringify_value(value)}".strip
  end

  def stringify_key(key)
    arg = ARGS_MAP[key]
    (arg.nil? ? key.to_s : arg)
  end

  def stringify_value(value)
    (value != true && value.to_s.length.positive? ? "\"#{value}\"" : '')
  end
end
