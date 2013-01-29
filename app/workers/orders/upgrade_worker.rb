require 'pathname'
require 'rubygems'
require 'fileutils'

Application.load 'lib/sidekiq'

module Orders
  class UpgradeWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :orders

    def perform(order_id)
      order = Order.find(order_id)

      @order_id      = order_id
      @build_version = Gem::Version.new order.args[1]
      @build_id      = order.args[0]
      @base_url      = URI.parse(order.args[3]).scheme.nil? ? "#{Terminal.config.host}#{order.args[3]}"
                                                            : order.args[3]

      @releases_pathname = Terminal.smartguard.releases_path
      @build_pathname    = @releases_pathname.join @build_version.to_s

      self.sync!
      Terminal.smartguard.switch_release @build_version.to_s.to_sym do
        order.complete
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

  end
end