# Due to limitations in puppet, it is currently necessary to copy some code 
# directly from puppet itself, rather than simply adding the pieces we need
#
# Please see the LICENSE file for proper rights to this file
# Encoding: utf-8

module Puppet
	newtype(:package) do
		@doc = 'Overwrites the standard Package provider'

		# attributes not currently validated
		newparam(:slot) do
			desc 'Package slot'
		end

		newparam(:repository) do
			desc 'Package repository'
		end

		newparam(:use) do
			desc 'Package use flags'
		end

		newparam(:keywords) do
			desc 'Package keywords'
		end

		newparam(:environment) do
			desc 'Package Environment'
		end

		newparam(:name) do
			desc 'The package name.'
			isnamevar

			validate do |value|
				raise Puppet::Error, 'name may not contain whitespace' if value =~ /\s/
				raise Puppet::Error, 'name may not end with category boundary' if value =~ /\/$/
				raise Puppet::Error, 'name may not start with category boundary' if value =~ /^\//
				raise Puppet::Error, 'name may not contain multiple category boundaries' if value.count('/') > 1
				raise Puppet::Error, 'name may not end with slot boundary' if value =~ /:$/
				raise Puppet::Error, 'name may not start with slot boundary' if value =~ /^:/
				raise Puppet::Error, 'name may not contain multiple slot boundaries' if value.count(':') > 1
			end
		end


		##################################################
		# Everything bellow here is virtually unmodified #
		##################################################


		# Features
		feature :installable, 'Can install packages.',
			:methods => [:install]
		feature :uninstallable, 'Can remove packages.',
			:methods => [:uninstall]
		feature :upgradeable, 'Can update packages',
			:methods => [:update, :latest]
		feature :purgeable, 'Can purge packages, configuration and all.',
			:methods => [:purge]
		feature :versionable, 'Knows versions, can install exact versions.'
		feature :holdable, 'Can prevent a package from being installed as a result of other package dependencies.',
			:methods => [:hold]


		# Ensure
		ensurable do
			desc 'Specify the state the package should be in when done'
			
			attr_accessor :latest

			newvalue(:present, :event => :package_installed) do
				provider.install
			end

			newvalue(:absent, :event => :package_removed) do
				provider.uninstall
			end

			newvalue(:purged, :event => :package_purged, :required_features => :purgeable) do
				provider.purge
			end

			newvalue(:held, :event => :package_held, :required_features => :holdable) do
				provider.hold
			end

			# Alias the 'present' value.
			aliasvalue(:installed, :present)

			newvalue(:latest, :required_features => :upgradeable) do
				# Because yum always exits with a 0 exit code, there's a retrieve
				# in the 'install' method.  So, check the current state now,
				# to compare against later.
				current = self.retrieve
				begin
					provider.update
				rescue => detail
					self.fail "Could not update: #{detail}"
				end

				if current == :absent
					:package_installed
				else
					:package_changed
				end
			end

			newvalue(/./, :required_features => :versionable) do
				begin
					provider.install
				rescue => detail
					self.fail "Could not update: #{detail}"
				end

				if self.retrieve == :absent
					:package_installed
				else
					:package_changed
				end
			end

			defaultto :installed

			# Override the parent method, because we've got all kinds of
			# funky definitions of 'in sync'.
			def insync?(is)
				@lateststamp ||= (Time.now.to_i - 1000)
				# Iterate across all of the should values, and see how they
				# turn out.

				@should.each { |should|
					case should
					when :present
						return true unless [:absent, :purged, :held].include?(is)
					when :latest
						# Short-circuit packages that are not present
						return false if is == :absent or is == :purged

						# Don't run 'latest' more than about every 5 minutes
						if @latest and ((Time.now.to_i - @lateststamp) / 60) < 5
							#self.debug 'Skipping latest check'
						else
							begin
								@latest = provider.latest
								@lateststamp = Time.now.to_i
							rescue => detail
								error = Puppet::Error.new("Could not get latest version: #{detail}")
								error.set_backtrace(detail.backtrace)
								raise error
							end
						end

						case
							when is.is_a?(Array) && is.include?(@latest)
								return true
							when is == @latest
								return true
							when is == :present
								# This will only happen on retarded packaging systems
								# that can't query versions.
								return true
							else
								self.debug "#{@resource.name} #{is.inspect} is installed, latest is #{@latest.inspect}"
						end


					when :absent
						return true if is == :absent or is == :purged
					when :purged
						return true if is == :purged
					# this handles version number matches and
					# supports providers that can have multiple versions installed
					when *Array(is)
						return true
					end
				}

				false
			end

			# This retrieves the current state. LAK: I think this method is unused.
			def retrieve
				provider.properties[:ensure]
			end

			# Provide a bit more information when logging upgrades.
			def should_to_s(newvalue = @should)
				if @latest
					@latest.to_s
				else
					super(newvalue)
				end
			end
		end

		newparam(:instance) do
			desc 'A read-only parameter set by the package.'
		end

		newparam(:status) do
			desc 'A read-only parameter set by the package.'
		end

		newparam(:category) do
			desc 'A read-only parameter set by the package.'
		end
		newparam(:platform) do
			desc 'A read-only parameter set by the package.'
		end

		# The 'query' method returns a hash of info if the package
		# exists and returns nil if it does not.
		def exists?
			@provider.get(:ensure) != :absent
		end
	end
end
