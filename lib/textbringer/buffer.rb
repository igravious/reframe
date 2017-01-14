# frozen_string_literal: true

require "nkf"
require "unicode/display_width"

module Textbringer
  class Buffer
    extend Enumerable

    attr_accessor :file_name, :file_encoding, :file_format, :keymap
    attr_reader :name, :point, :marks, :line, :column

    GAP_SIZE = 256
    UNDO_LIMIT = 1000

    UTF8_CHAR_LEN = Hash.new(1)
    [
      [0xc0..0xdf, 2],
      [0xe0..0xef, 3],
      [0xf0..0xf4, 4]
    ].each do |range, len|
      range.each do |c|
        UTF8_CHAR_LEN[c.chr] = len
      end
    end

    @@auto_detect_encodings = [
      Encoding::UTF_8,
      Encoding::EUC_JP,
      Encoding::Windows_31J
    ]

    DEFAULT_DETECT_ENCODING = ->(s) {
      @@auto_detect_encodings.find { |e|
        s.force_encoding(e)
        s.valid_encoding?
      }
    }

    NKF_DETECT_ENCODING = ->(s) {
      e = NKF.guess(s)
      e == Encoding::US_ASCII ? Encoding::UTF_8 : e
    }

    @@detect_encoding_proc = DEFAULT_DETECT_ENCODING

    @@table = {}
    @@list = []
    @@current = nil
    @@minibuffer = nil

    def self.auto_detect_encodings
      @@auto_detect_encodings
    end

    def self.auto_detect_encodings=(encodings)
      @@auto_detect_encodings = encodings
    end

    def self.detect_encoding_proc
      @@detect_encoding_proc
    end

    def self.detect_encoding_proc=(f)
      @@detect_encoding_proc = f
    end

    def self.add(buffer)
      @@table[buffer.name] = buffer
      @@list.unshift(buffer)
    end

    def self.current
      @@current
    end

    def self.current=(buffer)
      if buffer && buffer.name
        @@list.delete(buffer)
        @@list.push(buffer)
      end
      @@current = buffer
    end

    def self.minibuffer
      @@minibuffer ||= Buffer.new
    end

    def self.last
      if @@list.last == @@current
        @@list[-2]
      else
        @@list.last
      end
    end

    def self.count
      @@table.size
    end

    def self.[](name)
      @@table[name]
    end

    def self.find_or_new(name)
      @@table[name] ||= new_buffer(name)
    end

    def self.names
      @@table.keys
    end

    def self.kill_em_all
      @@table.clear
      @@list.clear
      @@current = nil
    end

    def self.find_file(file_name)
      buffer = @@table.each_value.find { |buffer|
        buffer.file_name == file_name
      }
      if buffer.nil?
        name = File.basename(file_name)
        begin
          buffer = Buffer.open(file_name, name: new_buffer_name(name))
          add(buffer)
        rescue Errno::ENOENT
          buffer = new_buffer(name, file_name: file_name)
        end
      end
      buffer
    end

    def self.new_buffer(name, **opts)
      buffer = Buffer.new(**opts.merge(name: new_buffer_name(name)))
      add(buffer)
      buffer
    end

    def self.new_buffer_name(name)
      if @@table.key?(name)
        (2..Float::INFINITY).lazy.map { |i|
          "#{name}<#{i}>"
        }.find { |i| !@@table.key?(i) }
      else
        name
      end
    end

    def self.each(&block)
      @@table.each_value(&block)
    end

    def initialize(s = "", name: nil,
                   file_name: nil, file_encoding: Encoding::UTF_8,
                   new_file: true, undo_limit: UNDO_LIMIT)
      @contents = s.encode(Encoding::UTF_8)
      @contents.force_encoding(Encoding::ASCII_8BIT)
      @name = name
      @file_name = file_name
      @file_encoding = file_encoding
      case @contents
      when /(?<!\r)\n/ 
        @file_format = :unix
      when /\r(?!\n)/
        @file_format = :mac
        @contents.gsub!(/\r/, "\n")
      when /\r\n/
        @file_format = :dos
        @contents.gsub!(/\r/, "")
      else
        @file_format = :unix
      end
      @new_file = new_file
      @undo_limit = undo_limit
      @point = 0
      @gap_start = 0
      @gap_end = 0
      @marks = []
      @mark = nil
      @line = 1
      @column = 1
      @desired_column = nil
      @yank_start = new_mark
      @undo_stack = []
      @redo_stack = []
      @undoing = false
      @version = 0
      @modified = false
      @keymap = nil
      @attributes = {}
      @save_point_level = 0
    end

    def name=(name)
      if @@table[@name] == self
        @@table.delete(@name)
        @name = Buffer.new_buffer_name(name)
        @@table[@name] = self
      else
        @name = name
      end
    end

    def kill
      @@table.delete(@name)
      @@list.delete(self)
      if @@current == self
        @@current = nil
      end
    end

    def current?
      @@current == self
    end

    def modified?
      @modified
    end

    def [](name)
      @attributes[name]
    end

    def []=(name, value)
      @attributes[name] = value
    end

    def new_file?
      @new_file
    end

    def self.open(file_name, name: File.basename(file_name))
      s = File.read(file_name)
      enc = @@detect_encoding_proc.call(s)
      s.force_encoding(enc)
      Buffer.new(s, name: name,
                 file_name: file_name, file_encoding: enc,
                 new_file: false)
    end

    def save
      if @file_name.nil?
        raise "file name is not set"
      end
      s = to_s
      case @file_format
      when :dos
        s.gsub!(/\n/, "\r\n")
      when :mac
        s.gsub!(/\n/, "\r")
      end
      File.write(@file_name, s, encoding: @file_encoding)
      @version += 1
      @modified = false
      @new_file = false
    end

    def to_s
      (@contents[0...@gap_start] +
       @contents[@gap_end..-1]).force_encoding(Encoding::UTF_8)
    end

    def substring(s, e)
      if s > @gap_start || e <= @gap_start
        @contents[user_to_gap(s)...user_to_gap(e)]
      else
        len = @gap_start - s
        @contents[user_to_gap(s), len] + @contents[@gap_end, e - s - len]
      end.force_encoding(Encoding::UTF_8)
    end

    def byte_after(location = @point)
      if location < @gap_start
        @contents.byteslice(location)
      else
        @contents.byteslice(location + gap_size)
      end
    end

    def char_after(location = @point)
      s = substring(location, location + UTF8_CHAR_LEN[byte_after(location)])
      s.empty? ? nil : s
    end

    def bytesize
      @contents.bytesize - gap_size
    end
    alias size bytesize

    def point_min
      0
    end

    def point_max
      bytesize
    end

    def goto_char(pos)
      if pos < 0 || pos > size
        raise RangeError, "Out of buffer"
      end
      if /[\x80-\xbf]/n =~ byte_after(pos)
        raise ArgumentError, "Position is in the middle of a character"
      end
      @desired_column = nil
      if @save_point_level == 0
        @line = 1 + substring(point_min, pos).count("\n")
        if pos == point_min
          @column = 1
        else
          i = get_pos(pos, -1)
          while i > point_min
            if byte_after(i) == "\n"
              i += 1
              break
            end
            i = get_pos(i, -1)
          end
          @column = 1 + substring(i, pos).size
        end
      end
      @point = pos
    end

    def insert(s, merge_undo = false)
      pos = @point
      size = s.bytesize
      adjust_gap(size)
      @contents[@point, size] = s.b
      @marks.each do |m|
        if m.location > @point
          m.location += size
        end
      end
      @point = @gap_start += size
      update_line_and_column(pos, @point)
      unless @undoing
        if merge_undo && @undo_stack.last.is_a?(InsertAction)
          @undo_stack.last.merge(s)
          @redo_stack.clear
        else
          push_undo(InsertAction.new(self, pos, s))
        end
      end
      @modified = true
      @desired_column = nil
    end

    def newline
      indentation = save_point { |saved|
        beginning_of_line
        s = @point
        while /[ \t]/ =~ char_after
          forward_char
        end
        str = substring(s, @point)
        if end_of_buffer? || char_after == "\n"
          delete_region(s, @point)
        end
        str
      }
      insert("\n" + indentation)
    end

    def delete_char(n = 1)
      adjust_gap
      s = @point
      pos = get_pos(@point, n)
      if n > 0
        str = substring(s, pos)
        # fill the gap with NUL to avoid invalid byte sequence in UTF-8
        @contents[@gap_end...user_to_gap(pos)] = "\0" * (pos - @point)
        @gap_end += pos - @point
        @marks.each do |m|
          if m.location > @point
            m.location -= pos - @point
          end
        end
        push_undo(DeleteAction.new(self, s, s, str))
        @modified = true
      elsif n < 0
        str = substring(pos, s)
        update_line_and_column(@point, pos)
        # fill the gap with NUL to avoid invalid byte sequence in UTF-8
        @contents[user_to_gap(pos)...@gap_start] = "\0" * (@point - pos)
        @marks.each do |m|
          if m.location >= @point
            m.location -= @point - pos
          end
        end
        @point = @gap_start = pos
        push_undo(DeleteAction.new(self, s, pos, str))
        @modified = true
      end
      @desired_column = nil
    end

    def backward_delete_char(n = 1)
      delete_char(-n)
    end

    def forward_char(n = 1)
      pos = get_pos(@point, n)
      update_line_and_column(@point, pos)
      @point = pos
      @desired_column = nil
    end

    def backward_char(n = 1)
      forward_char(-n)
    end

    def forward_word(n = 1)
      n.times do
        while !end_of_buffer? && /\p{Letter}|\p{Number}/ !~ char_after
          forward_char
        end
        while !end_of_buffer? && /\p{Letter}|\p{Number}/ =~ char_after
          forward_char
        end
      end
    end

    def backward_word(n = 1)
      n.times do
        break if beginning_of_buffer?
        backward_char
        while !beginning_of_buffer? && /\p{Letter}|\p{Number}/ !~ char_after
          backward_char
        end
        while !beginning_of_buffer? && /\p{Letter}|\p{Number}/ =~ char_after
          backward_char
        end
        if /\p{Letter}|\p{Number}/ !~ char_after
          forward_char
        end
      end
    end

    def next_line
      if @desired_column
        column = @desired_column
      else
        prev_point = @point
        beginning_of_line
        column = Unicode::DisplayWidth.of(substring(@point, prev_point), 2)
      end
      end_of_line
      forward_char
      s = @point
      while !end_of_buffer? &&
          byte_after != "\n" &&
          Unicode::DisplayWidth.of(substring(s, @point), 2) < column
        forward_char
      end
      @desired_column = column
    end

    def previous_line
      if @desired_column
        column = @desired_column
      else
        prev_point = @point
        beginning_of_line
        column = Unicode::DisplayWidth.of(substring(@point, prev_point), 2)
      end
      beginning_of_line
      backward_char
      beginning_of_line
      s = @point
      while !end_of_buffer? &&
          byte_after != "\n" &&
          Unicode::DisplayWidth.of(substring(s, @point), 2) < column
        forward_char
      end
      @desired_column = column
    end

    def beginning_of_buffer
      if @save_point_level == 0
        @line = 1
        @column = 1
      end
      @point = 0
    end

    def beginning_of_buffer?
      @point == 0
    end

    def end_of_buffer
      goto_char(bytesize)
    end

    def end_of_buffer?
      @point == bytesize
    end

    def beginning_of_line
      while !beginning_of_buffer? &&
          byte_after(@point - 1) != "\n"
        backward_char
      end
      @point
    end

    def end_of_line
      while !end_of_buffer? &&
          byte_after(@point) != "\n"
        forward_char
      end
      @point
    end

    def new_mark
      Mark.new(self, @point).tap { |m|
        @marks << m
      }
    end

    def point_to_mark(mark)
      update_line_and_column(@point, mark.location)
      @point = mark.location
    end

    def mark_to_point(mark)
      mark.location = @point
    end

    def point_at_mark?(mark)
      @point == mark.location
    end

    def point_before_mark?(mark)
      @point < mark.location
    end

    def point_after_mark?(mark)
      @point > mark.location
    end

    def exchange_point_and_mark(mark = @mark)
      update_line_and_column(@point, mark.location)
      @point, mark.location = mark.location, @point
    end

    def save_point
      saved = new_mark
      column = @desired_column
      @save_point_level += 1
      begin
        yield(saved)
      ensure
        point_to_mark(saved)
        saved.delete
        @desired_column = column
        @save_point_level -= 1
      end
    end

    def mark
      if @mark.nil?
        raise "The mark is not set"
      end
      @mark.location
    end

    def set_mark(pos = @point)
      @mark ||= new_mark
      @mark.location = pos
    end

    def copy_region(s = @point, e = mark, append = false)
      str = s <= e ? substring(s, e) : substring(e, s)
      if append && !KILL_RING.empty?
        KILL_RING.current.concat(str)
      else
        KILL_RING.push(str)
      end
    end

    def kill_region(s = @point, e = mark, append = false)
      copy_region(s, e, append)
      delete_region(s, e)
    end

    def delete_region(s = @point, e = mark)
      save_point do
        old_pos = @point
        if s > e
          s, e = e, s
        end
        str = substring(s, e)
        @point = s
        adjust_gap
        len = e - s
        # fill the gap with NUL to avoid invalid byte sequence in UTF-8
        @contents[@gap_end, len] = "\0" * len
        @gap_end += len
        @marks.each do |m|
          if m.location > @point
            m.location -= len
          end
        end
        push_undo(DeleteAction.new(self, old_pos, s, str)) 
        @modified = true
      end
    end

    def kill_line(append = false)
      save_point do |saved|
        if end_of_buffer?
          raise RangeError, "End of buffer"
        end
        if char_after == ?\n
          forward_char
        else
          end_of_line
        end
        pos = @point
        point_to_mark(saved)
        kill_region(@point, pos, append)
      end
    end

    def kill_word(append = false)
      save_point do |saved|
        if end_of_buffer?
          raise RangeError, "End of buffer"
        end
        forward_word
        pos = @point
        point_to_mark(saved)
        kill_region(@point, pos, append)
      end
    end

    def insert_for_yank(s)
      mark_to_point(@yank_start)
      insert(s)
    end

    def yank
      insert_for_yank(KILL_RING.current)
    end

    def yank_pop
      delete_region(@yank_start.location, @point)
      insert_for_yank(KILL_RING.current(1))
    end

    def undo
      if @undo_stack.empty?
        raise "No further undo information"
      end
      action = @undo_stack.pop
      @undoing = true
      begin
        was_modified = @modified
        action.undo
        if action.version == @version
          @modified = false
          action.version = nil
        elsif !was_modified
          action.version = @version
        end
        @redo_stack.push(action)
      ensure
        @undoing = false
      end
    end

    def redo
      if @redo_stack.empty?
        raise "No further redo information"
      end
      action = @redo_stack.pop
      @undoing = true
      begin
        was_modified = @modified
        action.redo
        if action.version == @version
          @modified = false
          action.version = nil
        elsif !was_modified
          action.version = @version
        end
        @undo_stack.push(action)
      ensure
        @undoing = false
      end
    end

    def re_search_forward(s)
      re = Regexp.new(s)
      b, e = utf8_re_search(@contents, re, user_to_gap(@point))
      if b.nil?
        raise "Search failed"
      end
      if b < @gap_end && e > @gap_start
        b, e = utf8_re_search(@contents, re, @gap_end)
        if b.nil?
          raise "Search failed"
        end
      end
      goto_char(gap_to_user(e))
    end

    def transpose_chars
      if end_of_buffer? || char_after == "\n"
        backward_char
      end
      if beginning_of_buffer?
        raise RangeError, "Beginning of buffer"
      end
      backward_char
      c = char_after
      delete_char
      forward_char
      insert(c)
    end

    def gap_filled_with_nul?
      /\A\0*\z/ =~ @contents[@gap_start...@gap_end] ? true : false
    end

    private

    def adjust_gap(min_size = 0)
      if @gap_start < @point
        len = user_to_gap(@point) - @gap_end
        @contents[@gap_start, len] = @contents[@gap_end, len]
        @gap_start += len
        @gap_end += len
      elsif @gap_start > @point
        len = @gap_start - @point
        @contents[@gap_end - len, len] = @contents[@point, len]
        @gap_start -= len
        @gap_end -= len
      end
      # fill the gap with NUL to avoid invalid byte sequence in UTF-8
      @contents[@gap_start...@gap_end] = "\0" * (@gap_end - @gap_start)
      if gap_size < min_size
        new_gap_size = GAP_SIZE + min_size
        extended_size = new_gap_size - gap_size
        @contents[@gap_end, 0] = "\0" * extended_size
        @gap_end += extended_size
      end
    end

    def gap_size
      @gap_end - @gap_start
    end

    def user_to_gap(pos)
      if pos <= @gap_start
        pos
      else
        gap_size + pos 
      end
    end

    def gap_to_user(gpos)
      if gpos <= @gap_start
        gpos
      elsif gpos >= @gap_end
        gpos - gap_size
      else
        raise RangeError, "Position is in gap"
      end
    end

    def get_pos(pos, offset)
      if offset >= 0
        i = offset
        while i > 0
          raise RangeError, "Out of buffer" if end_of_buffer?
          b = byte_after(pos)
          pos += UTF8_CHAR_LEN[b]
          raise RangeError, "Out of buffer" if pos > bytesize
          i -= 1
        end
      else
        i = -offset
        while i > 0
          pos -= 1
          raise RangeError, "Out of buffer" if pos < 0
          while /[\x80-\xbf]/n =~ byte_after(pos)
            pos -= 1
            raise RangeError, "Out of buffer" if pos < 0
          end
          i -= 1
        end
      end
      pos
    end

    def update_line_and_column(pos, new_pos)
      return if @save_point_level > 0
      if pos < new_pos
        s = substring(pos, new_pos)
        n = s.count("\n")
        if n == 0
          @column += s.size
        else
          @line += n
          @column = 1 + s.slice(/[^\n]*\z/).size
        end
      elsif pos > new_pos
        s = substring(new_pos, pos)
        n = s.count("\n")
        if n == 0
          @column -= s.size
        else
          @line -= n
          if new_pos == point_min
            @column = 1
          else
            i = get_pos(new_pos, -1)
            while i > point_min
              if byte_after(i) == "\n"
                i += 1
                break
              end
              i = get_pos(i, -1)
            end
            @column = 1 + substring(i, new_pos).size
          end
        end
      end
    end

    def push_undo(action)
      return if @undoing
      if @undo_stack.size >= @undo_limit
        @undo_stack[0, @undo_stack.size + 1 - @undo_limit] = []
      end
      if !modified?
        action.version = @version
      end
      @undo_stack.push(action)
      @redo_stack.clear
    end

    def utf8_re_search(s, re, pos)
      char_pos = s[0...pos].force_encoding(Encoding::UTF_8).size
      s.force_encoding(Encoding::UTF_8)
      begin
        if s.index(re, char_pos)
          m = Regexp.last_match
          b = m.pre_match.bytesize
          e = b + m.to_s.bytesize
          [b, e]
        else
          nil
        end
      ensure
        s.force_encoding(Encoding::ASCII_8BIT)
      end
    end
  end

  class Mark
    attr_accessor :location

    def initialize(buffer, location)
      @buffer = buffer
      @location = location
    end

    def delete
      @buffer.marks.delete(self)
    end
  end

  class KillRing
    def initialize(max = 30)
      @max = max
      @ring = []
      @current = -1
    end

    def clear
      @ring.clear
      @current = -1
    end

    def push(str)
      @current += 1
      if @ring.size < @max
        @ring.insert(@current, str)
      else
        if @current == @max
          @current = 0
        end
        @ring[@current] = str
      end
    end

    def current(n = 0)
      if @ring.empty?
        raise "Kill ring is empty"
      end
      @current -= n
      if @current < 0
        @current += @ring.size
      end
      @ring[@current]
    end

    def empty?
      @ring.empty?
    end
  end

  KILL_RING = KillRing.new

  class UndoableAction
    attr_accessor :version

    def initialize(buffer, location)
      @version = nil
      @buffer = buffer
      @location = location
    end
  end

  class InsertAction < UndoableAction
    def initialize(buffer, location, string)
      super(buffer, location)
      @string = string
    end

    def undo
      @buffer.goto_char(@location)
      @buffer.delete_char(@string.size)
    end

    def redo
      @buffer.goto_char(@location)
      @buffer.insert(@string)
    end

    def merge(s)
      @string.concat(s)
    end
  end

  class DeleteAction < UndoableAction
    def initialize(buffer, location, insert_location, string)
      super(buffer, location)
      @insert_location = insert_location
      @string = string
    end

    def undo
      @buffer.goto_char(@insert_location)
      @buffer.insert(@string)
      @buffer.goto_char(@location)
    end

    def redo
      @buffer.goto_char(@insert_location)
      @buffer.delete_char(@string.size)
    end
  end
end
