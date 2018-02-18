# frozen_string_literal: true

module ReFrame
  CONFIG = {
    east_asian_ambiguous_width: 1,
    default_file_encoding: Encoding::UTF_8,
    default_file_format: :unix,
    tab_width: 8,
    indent_tabs_mode: false,
    case_fold_search: true,
		working_dir: File.expand_path('~/.reframe'),
    mark_ring_max: 16,
    global_mark_ring_max: 16,
    window_min_height: 4,
    syntax_highlight: true,
    highlight_buffer_size_limit: 102_400,
    shell_file_name: ENV['SHELL'],
    shell_command_switch: '-c',
    grep_command: 'grep -nH -e',
    fill_column: 70
  }
	CONFIG[:buffer_dump_dir] = File.join(CONFIG[:working_dir], 'buffer_dump')
	# CONFIG[:db_config_file] = File.join(CONFIG[:working_dir], 'db_config.yml')
	CONFIG[:db_config_file] = File.join(Dir.getwd, 'db/config.yml')
end
