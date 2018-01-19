# frozen_string_literal: true

module ReFrame
  #
  class Ring
    include Enumerable

    def initialize(max = 30, on_delete: ->(x) {})
      @max = max
      @ring = []
      @current = -1
      @on_delete = on_delete
    end

    def clear
      @ring.clear
      @current = -1
    end

    def push(obj)
      @current += 1
      if @ring.size < @max
        @ring.insert(@current, obj)
      else
        @current = 0 if @current == @max
        @on_delete.call(@ring[@current])
        @ring[@current] = obj
      end
    end

    def pop
      x = @ring[@current]
      rotate(1)
      x
    end

    def current
      raise EditorError, 'Ring is empty' if @ring.empty?
      @ring[@current]
    end

    def rotate(n)
      @current = get_index(n)
      @ring[@current]
    end

    def [](n = 0)
      @ring[get_index(n)]
    end

    def empty?
      @ring.empty?
    end

    def size
      @ring.size
    end

    def each(&block)
      @ring.each(&block)
    end

    def to_a
      @ring.to_a
    end

    private

    def get_index(n)
      raise EditorError, 'Ring is empty' if @ring.empty?
      i = @current - n
      if i >= 0 && i < @ring.size
        i
      else
        i % @ring.size
      end
    end
  end
end
