require 'rake'

class ClearCachesStep
  attr_accessor :paths

  def run
    @paths
      .select { |path| File.exist?(path) }
      .each do |path|
        FileUtils.remove_dir(File.expand_path(path))
        puts "Removed: #{path}"
      end
  end
end
