
module App

  def self.setup_migrations
		puts ENV['VERSION']
		exit
    ActiveRecord::Migrator.migrate('db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil )
  end

	def self.env
		@_env ||= ActiveSupport::StringInquirer.new(ENV['REFRAME_ENV'])
	end

  def self.setup_database
		filename = ReFrame.const_get(:CONFIG)[:db_config_file]
		yml = YAML::load(File.open(filename))
		spec = yml[env]
    ActiveRecord::Base.establish_connection(spec)
    # ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))
    ActiveRecord::Base.logger = logger
  end

	def self.logger
		@_logger
	end

	def self.init_logging
		@_logger = Logger.new("log/#{env}.log")
	end

	def self.load_models
		require_relative 'models/application_record'
		require_relative 'models/frame'
		require_relative 'models/unstructured'
		require_relative 'models/structured'
		require_relative 'models/element'
		require_relative 'models/remark'
		require_relative 'models/figure'
		require_relative 'models/citation'
		require_relative 'models/context'
		require_relative 'models/concept'
	end

end
