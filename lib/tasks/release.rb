require "zip/zip"

task :release do
  exclude = [
    'tmp/',
    'config/services/',
    'config/database.yml',
    'test/',
    'spec/',
    'doc/'
  ]

  builds   = Pathname.new("tmp/builds/")
  zip_file = builds.join(File.read(Application.root.join "VERSION") + '.zip')

  FileUtils.mkdir_p builds
  File.delete zip_file if File.exist? zip_file

  Zip::ZipFile.open(zip_file, Zip::ZipFile::CREATE) do |zipfile|
    `git ls-files`.split($/).each do |filename|
      next unless File.file?(filename)
      next if exclude.map{|x| filename.start_with?(x)}.include?(true)

      zipfile.add(filename, filename)
    end
  end
end