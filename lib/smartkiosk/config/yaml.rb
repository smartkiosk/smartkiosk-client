require 'yaml'
require_relative 'config_chunk'

module Smartkiosk
  module Config
    class YAML < ConfigChunk

      def initialize(file)
        super load_yml(@file = file)
      end

      def save!
        File.open(@file, 'wb') do |file|
          file.write(self.marshal_dump.to_yaml)
        end
      end

      private

      def load_yml(file)
        ::YAML.load(File.read file).to_hash
      end

    end
  end
end