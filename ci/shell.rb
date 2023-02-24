require 'English'

module Shell
  module_function

  def zip(directory_path)
    target = File.basename(directory_path)
    location = File.dirname(directory_path)
    run "(cd #{location} && zip -r -o #{target}.zip #{target})"
    "#{location}/#{target}.zip"
  end

  def run(command)
    output = `#{command}`
    raise "Command '#{command}' failed." unless $CHILD_STATUS.success?
    output
  end
end
