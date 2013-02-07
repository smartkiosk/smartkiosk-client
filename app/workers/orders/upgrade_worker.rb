require 'pathname'
require 'rubygems'
require 'fileutils'
require 'bundler'

module Orders
  class UpgradeWorker
    include Sidekiq::Worker
    include DurableOrderExecution

    sidekiq_options :queue => :orders

    def perform(order_id)
      order = Order.find(order_id)

      @order_id      = order_id
      @build_version = Gem::Version.new order.args[1]
      @build_id      = order.args[0]
      @base_url      = URI.parse(order.args[3]).scheme.nil? ? "#{Terminal.config.host}#{order.args[3]}"
                                                            : order.args[3]
      @gems_url      = URI.parse(order.args[4])

      @releases_pathname = Smartguard::Client.releases_path
      @build_pathname    = @releases_pathname.join @build_version.to_s

      self.sync!
      self.rewrite_sources!

      safely_execute_order(order_id) do
        Smartguard::Client.switch_release @build_version.to_s.to_sym
      end
    end

    def files!
      FileUtils.mkdir_p @releases_pathname

      nearest_less_release = Dir.glob(@releases_pathname.join('*.*')).select do |v|
        Gem::Version.new(File.basename(v)) < @build_version
      end.max

      if !File.directory?(@build_pathname)
        if nearest_less_release.blank?
          FileUtils.mkdir_p @build_pathname
        else
          FileUtils.cp_r nearest_less_release, @build_pathname
        end
      end

      remotes = JSON.parse(RestClient.get "#{Terminal.config.host}/terminal_builds/#{@build_id}/hashes")
      locals  = Dir[File.join(@build_pathname, '**/**')].select{|x| File.file?(x)}.map{|x|
        Pathname.new(x).relative_path_from(@build_pathname).to_s
      }

      download = {}
      remove   = []

      remotes.each do |remote, data|
        local = @build_pathname.join(remote)

        if !File.file?(local) || Digest::MD5.file(local).hexdigest != data[0]
          download[remote] = data[1]
        end
      end

      locals.each do |local, hash|
        remove << local if remotes[local].blank?
      end

      {:download => download, :remove => remove}
    end

    def sync!
      diff = files!

      total_transfer_size = diff[:download].values.inject(0){|sum,x|(sum+=x) unless x.nil?; sum }.to_f

      diff[:download].each do |key,  value|
        uri  = URI.parse(URI.encode("#{@base_url}/#{key}"))
        path = @build_pathname.join key
        FileUtils.mkdir_p File.dirname(path)

        File.open(path, "wb") do |f|
          Net::HTTP.start(uri.host, uri.port) do |http|
            http.request_get(uri.path) do |resp|
              resp.read_body do |segment|
                f.write(segment)
              end
            end
          end
        end

        diff[:download][key] = 0

        delta_transfer_size = diff[:download].values.inject(0){|sum,x| (sum+=x) unless x.nil?; sum}.to_f

        current_percentage = (100.0 - (delta_transfer_size / total_transfer_size * 100.0)).round(2)
        if  current_percentage > (@percentage ||= 0) + 5 || current_percentage == 100
          @percentage = current_percentage
          AcknowledgeWorker.perform_async(@order_id, nil, @percentage)
        end

      end

      diff[:remove].each do |file|
        fullpath = @build_pathname.join file
        File.delete(fullpath) if File.exist?(fullpath)
      end
    end

    def rewrite_sources!
      gemfilename = File.join(@build_pathname, "Gemfile")
      lockfilename = File.join(@build_pathname, "Gemfile.lock")

      gemfile = Bundler::Definition.build gemfilename,
                                          lockfilename, {}

      filtered = gemfile.sources.reject { |s| s.kind_of? Bundler::Source::Rubygems }
      filtered.unshift(Bundler::Source::Rubygems.new("remotes" => [ @gems_url ]))

      gemfile.instance_variable_set :@sources, filtered

      File.open(gemfilename, "w") do |io|
        io.puts "source #{@gems_url.to_s.inspect}"

        groups = Hash.new { |hash, key| hash[key] = [] }

        gemfile.dependencies.each do |gem|
          gem.groups.each { |group| groups[group] << gem }
        end

        groups.each do |group, gems|
          io.puts "group #{group.inspect} do"

          gems.each do |gem|
            io.print "  gem #{gem.name.inspect}, #{gem.requirement.inspect.inspect}"

            if gem.platforms.any?
              io.print ", :platforms => #{gem.platforms.inspect}"
            end

            case gem.source
            when Bundler::Source::Git
              io.print ", :git => #{gem.source.uri.inspect}"

              unless gem.source.branch.nil?
                io.print ", :branch => #{gem.source.branch.inspect}"
              end

              unless gem.source.ref.nil?
                io.print ", :ref => #{gem.source.ref.inspect}"
              end

              if gem.source.submodules
                io.print ", :submodules => true"
              end
            end

            io.puts
          end

          io.puts "end"
        end
      end

      File.open(lockfilename, "w") { |io| io.write gemfile.to_lock }
    end
  end
end