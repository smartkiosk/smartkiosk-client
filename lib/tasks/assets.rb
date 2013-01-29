namespace :assets do
  desc 'compile assets'
  task :precompile do
    sprockets = Application.sprockets
    destination = Application.root.join('public/assets')

    Application.assets_compile.each do |file|
      asset   = sprockets[file]
      outfile = destination.join(file)

      FileUtils.mkdir_p outfile.dirname

      asset.write_to(outfile)
      asset.write_to("#{outfile}.gz")
      puts "compiled #{file}"
    end
  end
end