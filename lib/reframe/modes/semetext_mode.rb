# frozen_string_literal: true
# it begins, here

module ReFrame
	class SemetextMode < FundamentalMode # should have a markup/markdown mode (or both?)
    self.file_name_pattern = /\A(?:.*\.(?:seme))\z/ix

		self.lexer = Rouge::Lexers::Markdown.new

		self.highlighter = :rouge_highlight
	end
end
