require 'rake'

class ShellStep
  attr_accessor :script, :is_active

  def initialize
    @is_active = true
  end

  def run
    Rake.sh @script
  end
end
