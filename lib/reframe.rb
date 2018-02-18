# frozen_string_literal: true

require_relative 'reframe/version'
require_relative 'reframe/config'
require_relative 'reframe/errors'
require_relative 'reframe/ring'
require_relative 'reframe/buffer'
require_relative 'reframe/window'
require_relative 'reframe/keymap'
require_relative 'reframe/utils'
require_relative 'reframe/color'
require_relative 'reframe/faces'
# require_relative 'reframe/buffer256'
require_relative 'reframe/commands'
# have commands.rb load these ?
require_relative 'reframe/commands/buffers'
require_relative 'reframe/commands/windows'
require_relative 'reframe/commands/files'
require_relative 'reframe/commands/misc'
require_relative 'reframe/commands/isearch'
require_relative 'reframe/commands/replace'
require_relative 'reframe/commands/dabbrev'
require_relative 'reframe/commands/ctags'
require_relative 'reframe/commands/clipboard'
require_relative 'reframe/commands/register'
require_relative 'reframe/commands/keyboard_macro'
require_relative 'reframe/commands/fill'
require_relative 'reframe/commands/help'
require_relative 'reframe/modes'
# have modes.rb load these ?
require_relative 'reframe/modes/fundamental_mode'
require_relative 'reframe/modes/semetext_mode'
require_relative 'reframe/modes/programming_mode'
require_relative 'reframe/modes/ruby_mode'
require_relative 'reframe/modes/c_mode'
require_relative 'reframe/modes/backtrace_mode'
require_relative 'reframe/modes/completion_list_mode'
require_relative 'reframe/modes/help_mode'
require_relative 'reframe/plugin'
require_relative 'reframe/controller'

require_relative 'reframe/app'

require 'active_record'
App.init_logging()
App.setup_database()
App.load_models()

# and/or

# ContextProxy = Struct.new(:name)
# UNTITLED_FILE=ContextProxy.new('*untitled*')
# Context = Class.new

