# frozen_string_literal: true

module Textbringer
  class FundamentalMode < Mode
    def symbol_pattern
      /[\p{Letter}\p{Number}_]/
    end
  end
end
