require 'find'
require 'zip'
require_relative 'plist_buddy'
require_relative 'xcodebuild'

class BuildAppStep
  attr_accessor :build_path, :project_path, :scheme, :target, :destination, :sign

  def archive_path
    "#{@build_path}/#{@target}.xcarchive"
  end

  def ipa_path
    File.expand_path(archive_path).ext 'ipa'
  end

  def dsym_path
    File.join(File.dirname(File.expand_path(archive_path)), "#{@target}.dSYM.zip")
  end

  def run
    clean_artifacts
    build_archive unless File.exist? archive_path
    update_build_version unless File.exist? archive_path
    update_archive_version unless File.exist? archive_path
    export_ipa unless File.exist? ipa_path
    export_dsym unless File.exist? dsym_path
  end

  private

  def clean_artifacts
    FileUtils.rm_rf Dir.glob("#{@build_path}/*") if Dir.exist? @build_path
  end

  def build_archive
    XcodeBuild.build_archive(
      project: @project_path,
      scheme: @scheme,
      configuration: 'Release',
      destination: @destination,
      archive_path: archive_path,
      flags: {
        CODE_SIGNING_REQUIRED: @sign ? 'YES' : 'NO',
        CODE_SIGNING_ALLOWED: @sign ? 'YES' : 'NO'
      }
    )
  end

  def update_build_version
    paths = [
      "#{archive_path}/Products/Applications/#{@target}.app/Info.plist",
      "#{archive_path}/dSYMs/#{@target}.app.dSYM/Contents/Info.plist"
    ]
    paths.each do |path|
      plist = InfoPlistBuddy.new(path)
      plist.bundle_version = bundle_version
    end
  end

  def update_archive_version
    path = "#{archive_path}/Info.plist"
    InfoPlistBuddy.new(path).archive_version = bundle_version
  end

  def bundle_version
    Shell.run('git rev-list HEAD').lines.count
  end

  def export_ipa
    app_path = File.join(archive_path, 'Products', 'Applications')
    Zip::File.open(ipa_path, Zip::File::CREATE) do |zip_file|
      Dir[File.join(app_path, '**', '**')].each do |file|
        zip_entry = file.sub(app_path, 'Payload')
        zip_file.add(zip_entry, file)
      end
    end
  end

  def export_dsym
    dsyms_path = File.join(archive_path, 'dSYMs')
    Zip::File.open(dsym_path, Zip::File::CREATE) do |zipfile|
      Find.find(dsyms_path).select { |path| path.end_with?('.dSYM') }.each do |dir|
        Find.find(dir).each do |file|
          zipfile.add(file.sub(dsyms_path, '').sub(%r{^/}, ''), file)
        end
      end
    end
  end
end
