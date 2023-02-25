require 'rake'

class ShellStep
  attr_accessor :script
  attr_accessor :is_active

  def initialize
    @is_active = true
  end

  def run
    Rake.sh @script
  end
end
