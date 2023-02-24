require 'find'
require 'zip'
require_relative 'plist_buddy'

class AppBuilder
  def initialize(project_path, build_path, sign)
    @project_path = project_path
    @build_path = build_path
    @sign = sign
  end

  def self.build(project_path, scheme, build_path, sign)
    builder = AppBuilder.new(project_path, build_path, sign)
    builder.build_artifacts(scheme)
  end

  def build_artifacts(target)
    clean_artifacts
    archive_path = build_archive(target)
    update_build_version(archive_path, target)
    update_archive_version(archive_path)
    ipa_path = export_ipa(archive_path)
    dsym_path = export_dsym(archive_path, target)
    [ipa_path, dsym_path]
  end

  def clean_artifacts
    FileUtils.rm_rf Dir.glob("#{@build_path}/*") if Dir.exist? @build_path
  end

  def build_archive(target)
    archive_path = "#{@build_path}/#{target}.xcarchive"
    XcodeBuild.build_archive(
      project: @project_path,
      scheme: target,
      configuration: 'Release',
      destination: 'generic/platform=iOS',
      # destination: 'generic/platform=iOS Simulator',
      archive_path: archive_path,
      flags: {
        CODE_SIGNING_REQUIRED: @sign ? 'YES' : 'NO',
        CODE_SIGNING_ALLOWED: @sign ? 'YES' : 'NO'
      }
    )
    archive_path
  end

  def update_build_version(archive_path, target)
    paths = [
      "#{archive_path}/Products/Applications/#{target}.app/Info.plist",
      "#{archive_path}/dSYMs/#{target}.app.dSYM/Contents/Info.plist"
    ]
    paths.each do |path|
      module_plist = InfoPlistBuddy.new(path)
      module_plist.bundle_version = bundle_version
    end
  end

  def update_archive_version(archive_path)
    path = "#{archive_path}/Info.plist"
    InfoPlistBuddy.new(path).archive_version = bundle_version
  end

  def bundle_version
    Shell.run('git rev-list HEAD').lines.count
  end

  def export_ipa(archive_path)
    puts "Packing ipa from '#{File.basename archive_path}'..."
    app_path = File.join(File.expand_path(archive_path), 'Products', 'Applications')
    ipa_path = File.expand_path(archive_path).ext 'ipa'
    return ipa_path if File.exist? ipa_path
    Zip::File.open(ipa_path, Zip::File::CREATE) do |zip_file|
      Dir[File.join(app_path, '**', '**')].each do |file|
        zip_entry = file.sub(app_path, 'Payload')
        zip_file.add(zip_entry, file)
      end
    end
    return ipa_path
  end

  def export_dsym(archive_path, target)
    dsym_path = File.join(archive_path, 'dSYMs')
    dsym_archive_path = File.join(File.dirname(File.expand_path(archive_path)), "#{target}.dSYM.zip")
    return dsym_archive_path if File.exist? dsym_archive_path
    Zip::File.open(dsym_archive_path, Zip::File::CREATE) do |zipfile|
      Find.find(dsym_path).select { |path| path.end_with?('.dSYM') }.each do |dir|
        Find.find(dir).each do |file|
          zipfile.add(file.sub(dsym_path, '').sub(%r{^/}, ''), file)
        end
      end
    end
    dsym_archive_path
  end
end
