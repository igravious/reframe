# frozen_string_literal: true

module ReFrame
  module Plugin
    class << self
      attr_accessor :directory
    end

    @directory = File.expand_path("~/.reframe/plugins")

    def self.load_plugins
      files = Gem.find_latest_files("reframe.rb", false) +
        Dir.glob(File.join(directory, "*/**/reframe.rb"))
      files.each do |file|
        begin
          load(file)
        rescue Exception => e
          show_exception(e)
        end
      end
    end
  end
end
