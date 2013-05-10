#
# PortageGT (Puppet Package Provider)
#
# Copyright 2012, Whatbox Inc.
#
# Contributions welcome under CLA
# http://whatbox.ca/policies/contributions
#
# Released under MIT, BSD & GPL Licenses.
#

require 'puppet/provider/package'
require 'fileutils'
require 'xmlsimple'
include REXML

Puppet::Type.type(:package).provide(
	:portagegt,
	:parent => Puppet::Provider::Package 
) do

	##################
	# Config Options #
	##################

	CONFIG = {
		# Run eix before every portage run
		:eixRunUpdate => true,

		# Sync with upstream before each run
		:eixRunSync => true,

		# Recompile package if use flags change
		:useChange => true,

		# Relatively static options, you'll probably want the defaults
		:defaultSlot => "0",
		:defaultRepository => "gentoo",
		:devVersion => "9999",
		:eixDumpVersion => [6,7,8,9,10],
		:useDir => "/etc/portage/package.use",
		:keywordsDir => "/etc/portage/package.keywords",
		:packageDB => "/var/db/pkg",
	}

	#######################
	# Internal Structures #
	#######################

	#package {
	#
	# :provider,
	# A self reference to this class
	#
	# :name
	# Package name within category
	#
	# :ensure
	# Absent or "version string"
	#
	#}


	################
	# Puppet Setup #
	################

	desc "Provides better support for Gentoo's portage system."
	confine :operatingsystem => :gentoo


	# It turns out has_features automatically determines what's available from 
	# the definitions in this file, so the following lines probably aren't
	# necessary, regardless, I wanted to document this for my own purposes

	has_feature :versionable
	# Handles package versions

	has_feature :installable
	# Method install() is available

	has_feature :uninstallable
	# Method uninstall() is available

	has_feature :upgradeable
	# Method latest() is available
	# Method update() is available

	#has_feature :holdable
	# Method hold() is available


	commands :emerge => "/usr/bin/emerge"

	has_command(:eix, "/usr/bin/eix") do
		environment :EIXRC => "/etc/eixrc"
	end

	has_command(:eix_update, "/usr/bin/eix-update") do
		environment :EIXRC => "/etc/eixrc"
	end

	has_command(:eix_sync, "/usr/bin/eix-sync") do
		environment :EIXRC => "/etc/eixrc"
	end

	######################
	# Custom self.* APIs #
	######################

	def self.cfg(param)
		return CONFIG[param]
	end

	#void (void)
	def self.runEix

		if !CONFIG[:eixRunUpdate]
			 if CONFIG[:eixRunSync]
				raise Puppet::Error.new("eixRunUpdate must be true if eixRunSync is true")
			 end
			return
		end

		begin
			if CONFIG[:eixRunSync]
				eix_sync
			else
				eix_update
			end

		rescue Puppet::ExecutionFailure => detail
			raise Puppet::Error.new(detail)
		end
	end

	#void (package[], string dir, string opts, string funcName)
	def self.setPortage(packages, dir, funcName)
		oldCats = Dir.entries(dir).select { |entry|
			#File.directory?(File.join(dir,entry)) and #for old legacy compatibility
			!(entry =='.' || entry == '..')
		}

		newCats = []
		newEntries = {}

		packages.each do |name, package|

			# Early check variables
			category = package.provider.package_category
			optFlags = package.provider.send(funcName)


			# We cannot specify these attributes unless we have a category as well
			if category.nil? 
				if optFlags.length != 0
					Puppet.warning("Cannot apply #{funcName} for Package[#{name}] without a category")
				end
				next
			end


			# Remaining variables
			slot = package.provider.package_slot
			optDir = File.join(dir,category)
			optName = package.provider.package_name
			optFile = File.join(optDir,optName)


			# Add slot to file where necessary
			if (!slot.nil? && slot != CONFIG[:defaultSlot])
				optFile = "#{optFile}:#{slot}"
				optName = "#{optName}:#{slot}"
			end
			
			#packages *without* opt flags
			if (optFlags.length == 0)

				# No package in this category has opt flags, done
				if !File.directory?(optDir)
					next
				end

				# This package has no opt flags, done 
				if !File.file?(optFile)
					next
				end

				# This package does have opt flags, remove them
				File.unlink(optFile)
				next
			end #optFlags.length == 0


			#packages with opt flags


			#Update newoptCats
			if !newCats.include?(category)
				newCats << category
			end

			#Add category to newEntries
			if !newEntries.has_key?(category)
				newEntries[category] = []
			end

			newEntries[category].push(optName)



			# Create directory of none exists
			if !File.directory?(optDir)

				#Not a directory, but exists
				if File.exists?(optDir)
					if File.file?(optDir)
						File.unlink(optDir)
					else
						raise Puppet::Error.new("Unexpected file type: #{optDir}")
					end
				end

				debug("#{funcName}: CreateCategory #{optDir}")
				Dir.mkdir(optDir)
			end

			out = "#{category}/#{package.provider.package_name}"

			if (!slot.nil? && slot != CONFIG[:defaultSlot])
				out = "#{out}:#{slot}"
			end

			out = "#{out} #{optFlags.join(' ')}\n"

			debug("#{funcName}: Testing #{out}".rstrip)

			# Create file
			if !File.file?(optFile) || File.read(optFile) != out
				debug("#{funcName}: WriteFile #{out}")
				File.open(optFile, 'w') { |fh|
					fh.write(out)
				}
				next
			end
		end #packages.each

		# Remove (what should be) empty directories
		removeCats = oldCats - newCats
		removeCats.each { |c|
			debug("#{funcName}: RemoveCategory #{c}")
			FileUtils.rm_rf(File.join(dir,c))
		}

		# Remove stray entries from categories
		newCats.each { |cat|
			oldEntries = Dir.entries(File.join(dir,cat)).select { |entry|
				!(entry =='.' || entry == '..')
			}

			removeEntries = oldEntries - newEntries[cat]
			removeEntries.each { |e|
				debug("#{funcName}: RemoveEntry #{cat}/#{e}")
				FileUtils.rm_rf(File.join(dir,cat,e))
			}
		}

	end

	######################
	# Puppet self.* APIs #
	######################

	# One of void self.prefetch(package[]) or package[] self.instances() must be used
	def self.prefetch(packages)
		runEix
		setPortage(packages,CONFIG[:useDir],'package_use')
		setPortage(packages,CONFIG[:keywordsDir],'package_keywords')
	end


	###########################################
	# Utility classes (not for use in self.*) #
	###########################################

	#string (string)
	def _strip_subslot(slot)
		if slot.count('/') == 1
			return slot.split('/')[0]
		end

		return slot
	end

	#string[] (string)
	#string[] (string[])
	def resourceTok(string)
		if string.nil?
			return []
		elsif string.kind_of?(Array)
			flags = string.sort
		else
			flags = string.split(" ")

			#Allow excess whitespace (by stripping it) between flags
			flags = flags.reject { |c|
				c.empty?
			}

			#Sort the flags so the order doesn't matter
			flags = flags.sort

			return flags
		end
	end

	#string (void)
	def package_name
		name = @resource[:name]

		if name.count(':') > 0
			name = name.split(':')[0]
		end

		if name.count('/') > 0
			name = name.split('/')[1]
		end
		
		return name
	end

	#string (void)
	def package_category
		name = @resource[:name]

		category = nil
		nameCategory = false

		if name.count('/') > 0
			category = name.split('/')[0]
			nameCategory = true
		end

		if @resource[:category]
			if nameCategory && category != @resource[:category]
				raise Puppet::Error.new("Category disagreement on Package[#{name}], please check the definition")
			end

			category = @resource[:category]
		end 

		return category
	end

	#string (void)
	def package_slot
		name = @resource[:name]

		slot = nil
		nameSlot = false

		if name.count(':') == 1
			slot = name.split(':')[1]
			nameSlot = true
		end

		if @resource[:slot]
			if nameSlot && slot != @resource[:slot]
				raise Puppet::Error.new("Slot disagreement on Package[#{name}], please check the definition")
			end

			slot = @resource[:slot]
		end

		return slot
	end

	#string (void)
	def package_repository
		if @resource[:repository]
			return @resource[:repository]
		end

		return nil
	end


	#string[] (void)
	def package_use
		resourceTok(@resource[:use])
	end

	#string[] (void)
	def package_keywords
		resourceTok(@resource[:keywords])
	end

	#bool (string have[], string valid[], string want[])
	def useChanged(have, valid, want)

		# Negative flags
		want.find_all { |x|
			x[0,1] == '-'
		}.collect { |x|
			x[1..-1]
		}.each { |x|
			next if !valid.include?(x)
			debug("Recopmiling #{package_category}/#{package_name} for USE=\"-#{x}\"")
			return true if have.include?(x)
		}

		# Positive flags
		want.find_all { |x|
			x[0,1] != '-'
		}.each { |x|
			next if !valid.include?(x)
			debug("Recopmiling #{package_category}/#{package_name} for USE=\"#{x}\"")
			return true if !have.include?(x)
		}

		return false
	end


	###########################
	# Implement required APIs #
	###########################

	#void (void)
	def install
		should = @resource.should(:ensure)

		name = package_name
		
		if !package_category.nil?
			name = "#{package_category}/#{name}"
		end
		
		if should == :present or should == :latest
			if package_slot
				# Install a specific slot
				name = "#{name}:#{package_slot}"
			end

			if package_repository
				# Install from a specific source
				name = "#{name}::#{package_repository}"
			end

		else
			# We must install a specific version
			name = "=#{name}-#{should}"
			
			# A specific version can't have multiple slots, so no need to specify

			if package_repository
				# Install from a specific source
				name = "#{name}::#{package_repository}"
			end
		end

		env_hold = ENV.to_hash
		if @resource[:environment].is_a? Hash
			ENV.replace(env_hold.merge(@resource[:environment]))
		end

		emerge name

		ENV.replace(env_hold)
	end

	#void (void)
	def uninstall
		name = package_name

		if !package_category.nil?
			name = "#{package_category}/#{name}"
		end

		if !package_slot.nil?
			name = "#{name}:#{package_slot}"
		end

		if !package_repository.nil?
			name = "#{name}::#{package_repository}"
		end

		emerge "--unmerge", name
	end

	#void (void)
	def update
		install
	end

	# Returns what is currently installed
	#package[] (void)
	def query
		slots = {}
		repositories = []
		categories = []

		if package_category.nil?
			glob_value = "*/#{package_name}"
			search_value = package_name
		else
			glob_value = "#{package_category}/#{package_name}"
			search_value = glob_value
		end
		Dir.glob("#{CONFIG[:packageDB]}/#{glob_value}-[0-9]*").each { |directory|

			['SLOT','PF','CATEGORY','BUILD_TIME','USE'].each { |expected|
				if !File.exists?("#{directory}/#{expected}")
					raise Puppet::Error.new("The metadata file \"#{expected}\" was not found in #{directory}")
				end
			}


			#Get variables
			slot = _strip_subslot(File.read("#{directory}/SLOT").rstrip)
			category = File.read("#{directory}/CATEGORY").rstrip
			use = File.read("#{directory}/USE").rstrip

			if File.exists?("#{directory}/IUSE")
				iuse = File.read("#{directory}/IUSE").rstrip
			else
				iuse = ""
			end

			# http://dev.gentoo.org/~ulm/pms/5/pms.html#x1-280003.2
			name, version = File.read("#{directory}/PF").rstrip.split(/-(?=[0-9])/)

			# Skip based on specific constraints
			if !package_slot.nil?
				if slot != package_slot
					next
				end
			end

			# Update disambiugation values
			if !categories.include?(category)
				categories.push(category)
			end

			# if this slot isn't yet defined in the slots hash, define it with the defaults
			if !slots.has_key?(slot)
				slots[slot] = {
					:provider => self.name,
					:name => name,
					:ensure => version,
				}
			end


			# Handle use flag Changes
			if CONFIG[:useChange]
				valid = resourceTok(iuse).map { |x|
					x[1..-1] if x[0,1] == '+'
					x
				}

				if useChanged(resourceTok(use), valid, package_use)

					#Recompile lie, 0 -> current
					slots[slot][:ensure] = "0"
					next
				end
			end
		}

		if @resource[:ensure] == :absent && slots.length == 0
			raise "Faulty assumption: categories empty when slots empty" unless categories.length == 0
			raise "Faulty assumption: repositories empty when slots empty" unless repositories.length == 0
			return nil
		end


		# Disambiguation errors
		case categories.length
			when 0
				return nil
			when 1
				# Correct number, we're done here
			else
				categoriesAvail = categories.join(" ")
				raise Puppet::Error.new("Multiple categories [#{categoriesAvail}] available for package [#{search_value}]")
		end

		case slots.length
			when 0
				return nil
			when 1
				# Correct number, we're done here
			else
				slotsAvail = slots.keys.join(" ")
				raise Puppet::Error.new("Multiple slots [#{slotsAvail}] available for package [#{search_value}]")
		end

		slot = slots.keys[0]
		return slots[slot]
	end

	# Returns the string for the newest version of a package available
	#string (void)
	def latest
		slots = {}
		repositories = []
		categories = []

		#Chose arguments based on what we've received
		if package_category.nil?
			search_field = "--name"
			search_value = package_name
		else
			search_field = "--category-name"
			search_value = "#{package_category}/#{package_name}"
		end

		begin
			eixout = eix("--xml", "--pure-packages", "--exact", search_field, search_value)
		rescue Puppet::ExecutionFailure => detail
			raise Puppet::Error.new(detail)
		end

		xml = REXML::Document.new(eixout)


		if !CONFIG[:eixDumpVersion].include?(Integer(xml.root.attributes["version"]))
			warnonce("eixdump version is not in [#{CONFIG[:eixDumpVersion].join(', ')}].")
		end

		xml.elements.each('eixdump/category/package') { |p|
			p.elements.each('version') { |v|

				# TODO: reenable this after some unit tests have been added accordingly
				#       - also needs checking for special cases to come after better tests for :installed, :present, etc.
				#
				# Throw an error if slot & ensure do not match up
				# if !package_slot.nil? && v.attributes['id'] == @resource[:ensure]
				# 	if v.attributes['slot'] != package_slot
				# 		raise Puppet::Error.new("Explicit version for Package[#{search_value}] \"#{v.attributes['id']}\" not in slot \"#{package_slot}\".")
				# 	end
				# end


				# Skip based on specific constraints
				if !package_slot.nil?
					if package_slot == CONFIG[:defaultSlot]
						if !v.attributes["slot"].nil?
							next
						end
					else
						if v.attributes["slot"] != package_slot
							next
						end
					end
				end

				if !package_repository.nil?
					if package_repository == CONFIG[:defaultRepository]
						if !v.attributes["repository"].nil?
							next
						end
					else
						if v.attributes["repository"] != package_repository
							next
						end
					end
				end


				# Establish variables for reuse
				if !v.attributes["slot"].nil?
					slot = _strip_subslot(v.attributes["slot"])
				else
					slot = CONFIG[:defaultSlot]
				end

				if !v.attributes["repository"].nil?
					repository = v.attributes["repository"]
				else
					repository = CONFIG[:defaultRepository]
				end


				# Update disambiguation values
				if !categories.include?(p.parent.attributes['name'])
					categories.push(p.parent.attributes['name'])
				end

				if !repositories.include?(repository)
					repositories.push(repository)
				end


				# if this slot isn't yet defined in the slots hash, define it with the defaults
				if !slots.has_key?(slot)
					slots[slot] = nil
				end

				# to make the if statements bellow easier to follow
				installed = (v.attributes["installed"] && v.attributes["installed"] == "1")
				dev = v.attributes["id"] == CONFIG[:devVersion]
				hard_masked = (v.elements["mask[@type='hard']"] && !v.elements["unmask[@type='package_unmask']"])
				keyword_masked = (v.elements["mask[@type='keyword']"] && !v.elements["unmask[@type='package_keywords']"])


				# Currently installed packages should always be valid candidates for staying installed
				if installed
					slots[slot] = v.attributes['id']
					next
				end

				# Skip dev builds
				if dev
					next
				end


				# Check package masks
				if !hard_masked && !keyword_masked
					slots[slot] = v.attributes['id']
					next
				end
			}
		}

		# Disambiguation errors
		case categories.length
			when 0
				if !package_category.nil?
					raise Puppet::Error.new("No package found with the specified name [#{search_value}] in category [#{package_category}]")
				else
					raise Puppet::Error.new("No package found with the specified name [#{search_value}]")
				end
			when 1
				# Correct number, we're done here
			else
				categoriesAvail = categories.join(" ")
				raise Puppet::Error.new("Multiple categories [#{categoriesAvail}] available for package [#{search_value}]")
		end

		case slots.length
			when 0
				if !package_slot.nil?
					raise Puppet::Error.new("No package found with the specified name [#{search_value}] in slot [#{package_slot}]")
				else
					raise Puppet::Error.new("No package found with the specified name [#{search_value}]")
				end
			when 1
				# Correct number, we're done here
			else
				slotsAvail = slots.keys.join(" ")
				raise Puppet::Error.new("Multiple slots [#{slotsAvail}] available for package [#{search_value}]")
		end

		case repositories.length
			when 0
				if !package_repository.nil?
					raise Puppet::Error.new("No package found with the specified name [#{search_value}] in repository [#{package_repository}]")
				else
					raise Puppet::Error.new("No package found with the specified name [#{search_value}]")
				end
			when 1
				# Correct number, we're done here
			else
				reposAvail = repositories.join(" ")
				raise Puppet::Error.new("Multiple repositories [#{reposAvail}] available for package [#{search_value}]")
		end


		# Return
		slot = slots.keys[0]
		return slots[slot]
	end
end
