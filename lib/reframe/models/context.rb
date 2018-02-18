
# TODO: monkey patch rouge

class Hash
	def name_it(s) # will do i18n
		copy = self.dup
		copy[:name] = s
		copy
	end
end

class Context < Structured

	require 'socket'

	GLOBAL_SCOPE		= {scope: 'global'}
	MACHINE_SCOPE		= {scope: 'machine'}
	AGENT_SCOPE			= {scope: 'agent'}
	PERSONA_SCOPE		= {scope: 'persona'}
	FILE_SCOPE			= {scope: 'file'}

	GLOBAL					= GLOBAL_SCOPE.name_it('Global')
	THIS_MACHINE		= MACHINE_SCOPE.name_it(Socket.gethostname)
	UNKNOWN_MACHINE	= MACHINE_SCOPE.name_it('Unknown')
	THIS_AGENT			= AGENT_SCOPE.name_it(Etc.getlogin)
	UNKNOWN_AGENT		= AGENT_SCOPE.name_it('Unknown')
	THIS_PERSONA		= PERSONA_SCOPE.name_it('I')
	UNKNOWN_PERSONA	= PERSONA_SCOPE.name_it('Unknown')

	# How to do ANONYMOUS and the other nyms?
		
	UNTITLED_FILE		= FILE_SCOPE.name_it('*untitled*') # deliberately replaces *scratch*

	class << self
		def str_to_const(s)
			const_get(s.upcase).to_json
		end

		# i never met a programming i didn't like
		
		# https://robots.thoughtbot.com/always-define-respond-to-missing-when-overriding
		def method_missing(method_name, *arguments, &block)
    	if method_name.to_s =~ /locate_(.*)/
      	# user.send($1, *arguments, &block)
				rel = where(locator: str_to_const($1)) # unique field?
				raise ActiveRecord::RecordNotFound unless rel.length == 1
				rel.first
			elsif method_name.to_s =~ /construct_(.*)/
				if arguments.empty?
					f = new(locator: str_to_const($1))
				else
					f = new(locator: str_to_const($1), frame_id: arguments.first.id)
				end
				f.save!
				f
    	else
      	super
    	end
		end

  	def respond_to_missing?(method_name, include_private = false)
			method_name.to_s.start_with?('locate_') || method_name.to_s.start_with?('construct_') || super
  	end
	end

end

c = begin
	Context.locate_global
rescue
	c1 = Context.construct_global
	c2 = Context.construct_this_machine(c1)
	c3 = Context.construct_this_agent(c2)
	c4 = Context.construct_this_persona(c3)
	Context.construct_untitled_file(c4)
	c1
end

# Context.global = c
# Context.this_machine = ?
UNTITLED_FILE = Context.locate_untitled_file
