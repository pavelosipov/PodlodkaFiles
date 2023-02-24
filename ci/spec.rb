class Spec
  attr_reader :path

  def initialize(path)
    raise 'Spec has not been specified.' unless !path.to_s.empty?
    @path = path
  end

  def fire message
    raise "#{@path}: #{message}"
  end
end
