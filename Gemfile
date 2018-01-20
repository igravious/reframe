source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in rerame.gemspec
gemspec :path => 'gemspec'

group :test do
	#	gem 'minitest'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
	#	gem 'pry' # i prefer pry?
	gem 'standalone_migrations', github: 'ekampp/standalone-migrations'
end

group :development do
	#	gem 'rubocop'
	#	gem 'rcodetools'
end
