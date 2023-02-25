class SecretsSpec
  attr_reader :secrets

  def initialize(path)
    instance_eval(File.read(path))
  end

  def variables(value)
    @secrets = value
  end
end
