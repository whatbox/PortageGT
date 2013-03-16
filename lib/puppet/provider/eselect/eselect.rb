Puppet::Type.type(:eselect).provide(:eselect) do
	include Puppet::Util::Execution

	################
	# Puppet Setup #
	################

	desc "Provides support for Gentoo's eselect system."
	confine :operatingsystem => :gentoo

	# Because we allow custom list / set commands, it's cleaner not to use this
	# commands :eselect => '/usr/bin/eselect'

	######################
	# Puppet self.* APIs #
	######################

	# One of void self.prefetch(package[]) or package[] self.instances() must be used
	def self.prefetch(packages)
	end

	#string (void)
	def eselect_module
		if @resource[:name] =~ /^[a-z]+$/
			emodule = @resource[:name]
			nameModule = true
		end

		if @resource[:module]
			if nameModule && emodule != @resource[:module]
				raise Puppet::Error.new("Module disagreement on eselect[#{name}], please check the definition")
			end

			emodule = @resource[:module]
		end 

		return emodule
	end

	#string (void)
	def eselect_submodule
		submodule = nil

		if @resource[:submodule]
			submodule = @resource[:submodule]
		end 

		return submodule
	end

	#string (void)
	def eselect_list
		if @resource[:listcmd]
			if @resource[:module]
				raise Puppet::Error.new("module should not be specified if listcmd is in eselect[#{@resource[:name]}], please check the definition")
			end

			if @resource[:submodule]
				raise Puppet::Error.new("submodule should not be specified if listcmd is in eselect[#{@resource[:name]}], please check the definition")
			end

			if @resource[:setcmd].nil?
				raise Puppet::Error.new("listcmd is specified but setcmd is not in eselect[#{@resource[:name]}], please check the definition")
			end

			return @resource[:listcmd]
		end

		if @resource[:submodule]
			return "eselect #{eselect_module} list #{eselect_submodule}"
		else
			return "eselect #{eselect_module} list"
		end
	end

	#string (void)
	def eselect_set
		if @resource[:setcmd]
			if @resource[:module]
				raise Puppet::Error.new("module should not be specified if setcmd is in eselect[#{@resource[:name]}], please check the definition")
			end

			if @resource[:submodule]
				raise Puppet::Error.new("submodule should not be specified if setcmd is in eselect[#{@resource[:name]}], please check the definition")
			end

			if @resource[:listcmd].nil?
				raise Puppet::Error.new("setcmd is specified but listcmd is not in eselect[#{@resource[:name]}], please check the definition")
			end

			return @resource[:setcmd]
		end

		if @resource[:submodule]
			return "eselect #{eselect_module} set #{eselect_submodule}"
		else
			return "eselect #{eselect_module} set"
		end
	end

	#string (void)
	def ensure
		should = @resource.should(:ensure)

		begin
			output = Puppet::Util::Execution.execute(eselect_list)
		rescue Puppet::ExecutionFailure => detail
			raise Puppet::Error.new(detail)
		end

		selected = nil
		options = []
		output.split(/\r?\n/).each { |line|
			option = line.strip().split(/\s+/)

			next if option[0] !~ /\[\d+\]/

			if option[option.length-1] == '*'
				raise Puppet::Error.new("Multiple selected versions for eselect[#{@resource[:name]}]") if !selected.nil?

				selected = option[1]
			end

			options.push(option[1])
		}

		if !options.include? should
			availableOptions = options.join(" ")
			raise Puppet::Error.new("Invalid option \"#{should}\", should be one of [#{availableOptions}] for eselect[#{@resource[:name]}]")
		end

		return selected
	end

	#void (string)
	def ensure=(target)
		begin
			Puppet::Util::Execution.execute("#{eselect_set} #{target}")
		rescue Puppet::ExecutionFailure => detail
			raise Puppet::Error.new(detail)
		end
	end
end