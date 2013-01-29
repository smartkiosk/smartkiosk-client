require 'yaml'
require_relative 'chunk'

module Smartkiosk
  module Config
    class YAML < Chunk

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