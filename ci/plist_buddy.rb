require 'plist'

class PlistBuddy
  def initialize(plist_path)
    @plist_path = plist_path
    raise "#{plist_path} not exist" unless File.exist?(plist_path)
  end

  def extract_value(key)
    Rake.sh "/usr/libexec/PlistBuddy -c \"Print :#{key}\" #{@plist_path}"
  end

  def insert_value(key, value)
    Rake.sh "/usr/libexec/PlistBuddy -c \"Set :#{key} #{value}\" #{@plist_path}"
  end
end

class InfoPlistBuddy < PlistBuddy
  def bundle_version
    extract_value 'CFBundleVersion'
  end

  def bundle_version=(bundle_version)
    insert_value('CFBundleVersion', bundle_version.to_s)
  end

  def archive_version=(archive_version)
    insert_value('ApplicationProperties:CFBundleVersion', archive_version.to_s)
  end
end
