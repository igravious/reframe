# frozen_string_literal: true

require 'curses'

module ReFrame
  #
  class Face
    attr_reader :name, :attributes

    @@face_table = {}
    @@next_color_pair = 100 # start high enough :)

    def self.[](name)
      @@face_table[name]
    end

    def self.define(name, **opts)
      if @@face_table.key?(name)
        @@face_table[name].update(**opts)
      else
        @@face_table[name] = new(name, **opts)
      end
    end

    def self.face
      @@face_table
    end

    def self.delete(name)
      @@face_table.delete(name)
    end

    def initialize(name, **opts)
      @name = name
      @color_pair = @@next_color_pair
      @@next_color_pair += 1
      update(**opts)
    end

    def the_attributes
      Curses.init_pair(@color_pair,
                       Color[@foreground], Color[@background])
      attributes = 0
      attributes |= Curses.color_pair(@color_pair)
      attributes |= Curses::A_BOLD if @bold
      attributes |= Curses::A_UNDERLINE if @underline
      attributes |= Curses::A_REVERSE if @reverse
			attributes
    end

    def update(foreground: -1, background: -1, bold: false, underline: false, the_reverse: false)
      @foreground = foreground
      @background = background
      @bold = bold
      @underline = underline
      @reverse = the_reverse
      @attributes = the_attributes
      self
    end
  end
end
