# Encoding: utf-8
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

	# Update eix database before each run
	EIX_RUN_UPDATE = true

	# Run emerge --sync before each run
	EIX_RUN_SYNC = true

	# Recompile package if use flags change
	RECOMPILE_USE_CHANGE = true

	# You probably don't want to change these
	DEFAULT_SLOT = '0'
	DEFAULT_REPOSITORY = 'gentoo'
	EIX_DUMP_VERSION = [6, 7, 8, 9, 10]
	USE_DIR = '/etc/portage/package.use'
	KEYWORDS_DIR = '/etc/portage/package.keywords'
	PACKAGE_STATE_DIR = '/var/db/pkg'

	#######################
	# Internal Structures #
	#######################

	# package {
	#  :provider
	#  A self reference to this class
	#
	#  :name
	#  Package name within category
	#
	#  :ensure
	#  Absent or "version string"
	# }

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

	commands :emerge => '/usr/bin/emerge'

	has_command(:eix, '/usr/bin/eix') do
		environment :EIXRC => '/etc/eixrc'
	end

	has_command(:eix_update, '/usr/bin/eix-update') do
		environment :EIXRC => '/etc/eixrc'
	end

	has_command(:eix_sync, '/usr/bin/eix-sync') do
		environment :EIXRC => '/etc/eixrc'
	end

	######################
	# Custom self.* APIs #
	######################

	# void (void)
	def self.run_eix

		unless EIX_RUN_UPDATE
			 if EIX_RUN_SYNC
				raise Puppet::Error.new('EIX_RUN_UPDATE must be true if EIX_RUN_SYNC is true')
			 end
			return
		end

		begin
			if EIX_RUN_SYNC
				eix_sync
			else
				eix_update
			end

		rescue Puppet::ExecutionFailure => detail
			raise Puppet::Error.new(detail)
		end
	end

	# void (package[], string dir, string opts, string function)
	def self.set_portage(packages, dir, function)
		old_categories = Dir.entries(dir).select do |entry|
			# File.directory?(File.join(dir, entry)) and # for old legacy compatibility
			!(entry == '.' || entry == '..')
		end

		new_categories = []
		new_entries = {}

		packages.each do |name, package|

			# Early check variables
			category = package.provider.package_category
			opt_flags = package.provider.send(function)

			# We cannot specify these attributes unless we have a category as well
			if category.nil?
				if opt_flags.length != 0
					Puppet.warning("Cannot apply #{function} for Package[#{name}] without a category")
				end
				next
			end

			# Remaining variables
			slot = package.provider.package_slot
			opt_dir = File.join(dir, category)
			opt_name = package.provider.package_name
			opt_file = File.join(opt_dir, opt_name)

			# Add slot to file where necessary
			if !slot.nil? && slot != DEFAULT_SLOT
				opt_file = "#{opt_file}:#{slot}"
				opt_name = "#{opt_name}:#{slot}"
			end

			################################
			# Packages *without* opt flags #
			################################

			if opt_flags.length == 0

				# No package in this category has opt flags, done
				unless File.directory?(opt_dir)
					next
				end

				# This package has no opt flags, done
				unless File.file?(opt_file)
					next
				end

				# This package does have opt flags, remove them
				File.unlink(opt_file)
				next
			end # opt_flags.length == 0

			###########################
			# Packages with opt flags #
			###########################

			# Update newoptCats
			unless new_categories.include?(category)
				new_categories << category
			end

			# Add category to new_entries
			unless new_entries.has_key?(category)
				new_entries[category] = []
			end

			new_entries[category].push(opt_name)

			# Create directory of none exists
			unless File.directory?(opt_dir)

				# Not a directory, but exists
				if File.exists?(opt_dir)
					if File.file?(opt_dir)
						File.unlink(opt_dir)
					else
						raise Puppet::Error.new("Unexpected file type: #{opt_dir}")
					end
				end

				debug("#{function}: CreateCategory #{opt_dir}")
				Dir.mkdir(opt_dir)
			end

			out = "#{category}/#{package.provider.package_name}"

			if !slot.nil? && slot != DEFAULT_SLOT
				out = "#{out}:#{slot}"
			end

			out = "#{out} #{opt_flags.join(' ')}\n"

			debug("#{function}: Testing #{out}".rstrip)

			# Create file
			if !File.file?(opt_file) || File.read(opt_file) != out
				debug("#{function}: WriteFile #{out}")
				File.open(opt_file, 'w') do |fh|
					fh.write(out)
				end
				next
			end
		end # packages.each

		# Remove (what should be) empty directories
		remove_categories = old_categories - new_categories
		remove_categories.each do |c|
			debug("#{function}: RemoveCategory #{c}")
			FileUtils.rm_rf(File.join(dir, c))
		end

		# Remove stray entries from categories
		new_categories.each do |cat|
			old_entries = Dir.entries(File.join(dir, cat)).select do |entry|
				!(entry == '.' || entry == '..')
			end

			remove_entries = old_entries - new_entries[cat]
			remove_entries.each do |e|
				debug("#{function}: RemoveEntry #{cat}/#{e}")
				FileUtils.rm_rf(File.join(dir, cat, e))
			end
		end
	end

	######################
	# Puppet self.* APIs #
	######################

	# One of void self.prefetch(package[]) or package[] self.instances() must be used
	def self.prefetch(packages)
		run_eix
		set_portage(packages, USE_DIR, 'package_use')
		set_portage(packages, KEYWORDS_DIR, 'package_keywords')
	end

	###########################################
	# Utility classes (not for use in self.*) #
	###########################################

	# string (string)
	def _strip_subslot(slot)
		if slot.count('/') == 1
			return slot.split('/')[0]
		end

		slot
	end

	# string[] (string)
	# string[] (string[])
	def resource_tok(string)
		if string.nil?
			return []
		elsif string.kind_of?(Array)
			flags = string.sort
		else
			flags = string.split(' ')

			# Allow excess whitespace (by stripping it) between flags
			flags = flags.reject do |c|
				c.empty?
			end

			# Sort the flags so the order doesn't matter
			flags = flags.sort

			return flags
		end
	end

	# string (void)
	def package_name
		name = @resource[:name]

		if name.count(':') > 0
			name = name.split(':')[0]
		end

		if name.count('/') > 0
			name = name.split('/')[1]
		end

		name
	end

	# string (void)
	def package_category
		name = @resource[:name]

		category = nil
		name_category = false

		if name.count('/') > 0
			category = name.split('/')[0]
			name_category = true
		end

		if @resource[:category]
			if name_category && category != @resource[:category]
				raise Puppet::Error.new("Category disagreement on Package[#{name}], please check the definition")
			end

			category = @resource[:category]
		end

		category
	end

	# string (void)
	def package_slot
		name = @resource[:name]

		slot = nil
		name_slot = false

		if name.count(':') == 1
			slot = name.split(':')[1]
			name_slot = true
		end

		if @resource[:slot]
			if name_slot && slot != @resource[:slot]
				raise Puppet::Error.new("Slot disagreement on Package[#{name}], please check the definition")
			end

			slot = @resource[:slot]
		end

		slot
	end

	# string (void)
	def package_repository
		if @resource[:repository]
			return @resource[:repository]
		end

		nil
	end

	# string[] (void)
	def package_use
		resource_tok(@resource[:use])
	end

	# string[] (void)
	def package_keywords
		resource_tok(@resource[:keywords])
	end

	###########################
	# Implement required APIs #
	###########################

	# void (void)
	def install
		should = @resource.should(:ensure)

		name = package_name

		unless package_category.nil?
			name = "#{package_category}/#{name}"
		end

		if should == :present || should == :latest
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

	# void (void)
	def uninstall
		name = package_name

		unless package_category.nil?
			name = "#{package_category}/#{name}"
		end

		unless package_slot.nil?
			name = "#{name}:#{package_slot}"
		end

		unless package_repository.nil?
			name = "#{name}::#{package_repository}"
		end

		emerge('--unmerge', name)
	end

	# void (void)
	def update
		install
	end

	# Returns what is currently installed
	# package[] (void)
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
		Dir.glob("#{PACKAGE_STATE_DIR}/#{glob_value}-[0-9]*").each do |directory|

			%w(SLOT PF CATEGORY USE).each do |expected|
				unless File.exists?("#{directory}/#{expected}")
					raise Puppet::Error.new("The metadata file \"#{expected}\" was not found in #{directory}")
				end
			end

			# Get variables
			slot = _strip_subslot(File.read("#{directory}/SLOT").rstrip)
			category = File.read("#{directory}/CATEGORY").rstrip
			use = File.read("#{directory}/USE").rstrip

			if File.exists?("#{directory}/IUSE")
				iuse = File.read("#{directory}/IUSE").rstrip
			else
				iuse = ''
			end

			# http://dev.gentoo.org/~ulm/pms/5/pms.html#x1-280003.2
			name, version = File.read("#{directory}/PF").rstrip.split(/-(?=[0-9])/)

			# Skip based on specific constraints
			unless package_slot.nil?
				if slot != package_slot
					next
				end
			end

			# Update disambiugation values
			unless categories.include?(category)
				categories.push(category)
			end

			# if this slot isn't yet defined in the slots hash, define it with the defaults
			unless slots.has_key?(slot)
				slots[slot] = {
					:provider => self.name,
					:name => name,
					:ensure => version,
				}
			end

			# Handle use flag Changes
			if RECOMPILE_USE_CHANGE
				valid = resource_tok(iuse).map do |x|
					x[1..-1] if x[0, 1] == '+'

					x
				end

				if use_changed(resource_tok(use), valid, package_use)

					# Recompile lie, 0 -> current
					slots[slot][:ensure] = '0'
					next
				end
			end
		end

		if @resource[:ensure] == :absent && slots.length == 0
			raise 'Faulty assumption: categories empty when slots empty' unless categories.length == 0
			raise 'Faulty assumption: repositories empty when slots empty' unless repositories.length == 0
			return nil
		end

		# Disambiguation errors
		case categories.length
		when 0
			return nil
		when 1
			# Correct number, we're done here
		else
			categories_available = categories.join(' ')
			raise Puppet::Error.new("Multiple categories [#{categories_available}] available for package [#{search_value}]")
		end

		case slots.length
		when 0
			return nil
		when 1
			# Correct number, we're done here
		else
			slots_available = slots.keys.join(' ')
			raise Puppet::Error.new("Multiple slots [#{slots_available}] available for package [#{search_value}]")
		end

		slot = slots.keys[0]
		slots[slot]
	end

	# Returns the string for the newest version of a package available
	# string (void)
	def latest
		slots = {}
		repositories = []
		categories = []

		# Chose arguments based on what we've received
		if package_category.nil?
			search_field = '--name'
			search_value = package_name
		else
			search_field = '--category-name'
			search_value = "#{package_category}/#{package_name}"
		end

		begin
			eixout = eix('--xml', '--pure-packages', '--exact', search_field, search_value)
		rescue Puppet::ExecutionFailure => detail
			raise Puppet::Error.new(detail)
		end

		xml = REXML::Document.new(eixout)

		unless EIX_DUMP_VERSION.include?(Integer(xml.root.attributes['version']))
			warnonce("eixdump version is not in [#{EIX_DUMP_VERSION.join(', ')}].")
		end

		xml.elements.each('eixdump/category/package') do |p|
			p.elements.each('version') do |v|

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
				unless package_slot.nil?
					if package_slot == DEFAULT_SLOT
						unless v.attributes['slot'].nil?
							next
						end
					else
						if v.attributes['slot'] != package_slot
							next
						end
					end
				end

				unless package_repository.nil?
					if package_repository == DEFAULT_REPOSITORY
						unless v.attributes['repository'].nil?
							next
						end
					else
						if v.attributes['repository'] != package_repository
							next
						end
					end
				end

				# Establish variables for reuse
				if !v.attributes['slot'].nil?
					slot = _strip_subslot(v.attributes['slot'])
				else
					slot = DEFAULT_SLOT
				end

				if !v.attributes['repository'].nil?
					repository = v.attributes['repository']
				else
					repository = DEFAULT_REPOSITORY
				end

				# Update disambiguation values
				unless categories.include?(p.parent.attributes['name'])
					categories.push(p.parent.attributes['name'])
				end

				unless repositories.include?(repository)
					repositories.push(repository)
				end

				# if this slot isn't yet defined in the slots hash, define it with the defaults
				unless slots.has_key?(slot)
					slots[slot] = nil
				end

				# to make the if statements bellow easier to follow
				installed = (v.attributes['installed'] && v.attributes['installed'] == '1')
				dev = v.attributes['id'] =~ /^9+$/

				# http://docs.dvo.ru/eix-0.25.5/html/eix-xml.html
				# <mask type=" [..] " />
				# Possible values for the type are:
				# profile
				# hard
				# package_mask
				# keyword
				# missing_keyword
				# alien_stable
				# alien_unstable
				# minus_unstable
				# minus_asterisk
				# minus_keyword
				hard_masked = (v.elements['mask[@type!=\'keyword\']'] && !v.elements['unmask[@type=\'package_unmask\']'])
				keyword_masked = (v.elements['mask[@type=\'keyword\']'] && !v.elements['unmask[@type=\'package_keywords\']'])

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
			end
		end

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
			categories_available = categories.join(' ')
			raise Puppet::Error.new("Multiple categories [#{categories_available}] available for package [#{search_value}]")
		end

		case slots.length
		when 0
			if !package_slot.nil?
				raise Puppet::Error.new("No package found with the specified name [#{search_value}] in slot [#{package_slot}]")
			else
				raise Puppet::Error.new('Faulty assumption: 1 category and 0 slots with no slot specified')
			end
		when 1
			# Correct number, we're done here
		else
			slots_available = slots.keys.join(' ')
			raise Puppet::Error.new("Multiple slots [#{slots_available}] available for package [#{search_value}]")
		end

		case repositories.length
		when 0
			if !package_repository.nil?
				raise Puppet::Error.new("No package found with the specified name [#{search_value}] in repository [#{package_repository}]")
			else
				raise Puppet::Error.new('Faulty assumption: 1 category, 1 slot, and 0 repositories with no repository specified')
			end
		when 1
			# Correct number, we're done here
		else
			repos_available = repositories.join(' ')
			raise Puppet::Error.new("Multiple repositories [#{repos_available}] available for package [#{search_value}]")
		end

		slot = slots.keys[0]
		slots[slot]
	end

	private
	# string[] (string[])
	def use_filter_positive(everything)
		everything.select do |x|
			x[0, 1] != '-'
		end
	end

	private
	# string[] (string[])
	def use_filter_negative(everything)
		filtered = everything.select do |x|
			x[0, 1] == '-'
		end

		filtered.map do |x|
			x[1..-1]
		end
	end

	private
	# bool (string have[], string valid[], string want[])
	def use_changed(have, valid, want)

		# Negative flags
		use_filter_negative(want).each do |x|
			next unless valid.include?(x)

			if have.include?(x)
				debug("Recompiling #{package_category}/#{package_name} for USE=\"-#{x}\"")
				return true
			end
		end

		# Positive flags
		use_filter_positive(want).each do |x|
			next unless valid.include?(x)

			unless have.include?(x)
				debug("Recompiling #{package_category}/#{package_name} for USE=\"#{x}\"")
				return true
			end
		end

		false
	end
end
