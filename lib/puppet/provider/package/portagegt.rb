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

require 'set'

require 'puppet/provider/package'
require 'fileutils'
require 'rexml/document'
include REXML

Puppet::Type.type(:package).provide(
  :portagegt,
  parent: Puppet::Provider::Package
) do
  ##################
  # Config Options #
  ##################

  # Update eix database before each run
  EIX_RUN_UPDATE = true

  # Minimum age of local portage tree, in seconds,
  # before re-syncing. -1 to never run eix-sync.
  # Consider increasing if puppet is run multiple
  # times per day to prevent rsync server bans.
  EIX_RUN_SYNC = 48 * 3600

  # You probably don't want to change these
  DEFAULT_SLOT = '0'.freeze
  DEFAULT_REPOSITORY = 'gentoo'.freeze
  EIX_DUMP_VERSION = [6, 7, 8, 9, 10, 11].freeze
  USE_DIR = '/etc/portage/package.use'.freeze
  ENV_DIR = '/etc/portage/package.env'.freeze
  KEYWORDS_DIR = '/etc/portage/package.accept_keywords'.freeze
  PACKAGE_STATE_DIR = '/var/db/pkg'.freeze
  TIMESTAMP_FILE = '/usr/portage/metadata/timestamp'.freeze

  ################
  # Puppet Setup #
  ################

  desc "Provides better support for Gentoo's portage system."
  confine operatingsystem: :gentoo

  # It turns out has_features automatically determines what's available from
  # the definitions in this file, so the following lines probably aren't
  # necessary, regardless, I wanted to document this for my own purposes

  has_feature :versionable
  # Handles package versions

  has_feature :installable
  # Method install is available

  has_feature :uninstallable
  # Method uninstall is available

  has_feature :upgradeable
  # Method latest is available
  # Method update is available

  has_feature :install_options
  # Allows passing custom parameters

  has_feature :package_settings
  # Method package_settings_insync? is available
  # Method package_settings is available
  # Method package_settings= is available

  commands emerge: '/usr/bin/emerge'

  has_command(:eix, '/usr/bin/eix') do
    environment EIXRC: '/etc/eixrc'
  end

  has_command(:eix_update, '/usr/bin/eix-update') do
    environment EIXRC: '/etc/eixrc'
  end

  has_command(:eix_sync, '/usr/bin/eix-sync') do
    environment EIXRC: '/etc/eixrc'
  end

  def package_settings_validate(opts)
    return if opts.nil?
    raise Puppet::ResourceError, 'Must be a hash' unless opts.is_a? Hash

    return unless opts.key?(:slot)

    raise Puppet::ResourceError, 'slot may not contain whitespace' if opts[:slot] =~ /\s/
    raise Puppet::ResourceError, 'slot may not contain subslot' if opts[:slot] =~ %r{/}
  end

  ######################
  # Custom self.* APIs #
  ######################

  # void (void)
  def self.run_eix
    unless EIX_RUN_UPDATE
      if EIX_RUN_SYNC >= 0
        raise Puppet::Error, 'EIX_RUN_UPDATE must be true if EIX_RUN_SYNC is not -1'
      end
      return
    end

    if EIX_RUN_SYNC >= 0
      eix_sync if File.mtime(TIMESTAMP_FILE) + EIX_RUN_SYNC < Time.now
    else
      eix_update
    end
  end

  # void (package[], string dir, string opts, string function)
  def self.set_portage(packages, dir, function)
    old_categories = Dir.entries(dir).select do |entry|
      # File.directory?(File.join(dir, entry)) and # for old legacy compatibility
      !(entry == '.' || entry == '..')
    end

    new_categories = Set.new
    new_entries = {}

    packages.each do |name, package|
      # Early check variables
      category = package.provider.package_category
      opt_flags = package.provider.send(function)

      # We cannot specify these attributes unless we have a category as well
      if category.nil?
        unless opt_flags.empty?
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
      if slot && slot != DEFAULT_SLOT
        opt_file = "#{opt_file}:#{slot}"
        opt_name = "#{opt_name}:#{slot}"
      end

      ################################
      # Packages *without* opt flags #
      ################################

      if opt_flags.empty?

        # No package in this category has opt flags, done
        next unless File.directory?(opt_dir)

        # This package has no opt flags, done
        next unless File.file?(opt_file)

        # This package does have opt flags, remove them
        File.unlink(opt_file)
        next
      end # opt_flags.empty?

      ###########################
      # Packages with opt flags #
      ###########################

      # Update newoptCats
      new_categories << category

      # Add category to new_entries
      new_entries[category] = [] unless new_entries.key?(category)

      new_entries[category].push(opt_name)

      # Create directory of none exists
      unless File.directory?(opt_dir)

        # Not a directory, but exists
        if File.exist?(opt_dir)
          if File.file?(opt_dir)
            File.unlink(opt_dir)
          else
            raise Puppet::Error, "Unexpected file type: #{opt_dir}"
          end
        end

        debug("#{function}: creating category #{opt_dir}")
        Dir.mkdir(opt_dir)
      end

      out = "#{category}/#{package.provider.package_name}"

      out = "#{out}:#{slot}" if slot && slot != DEFAULT_SLOT

      out = "#{out} #{opt_flags.sort.join(' ')}\n"

      debug("#{function}: comparing existing to #{out}".rstrip)

      # Create file
      next unless !File.file?(opt_file) || File.read(opt_file) != out

      debug("#{function}: WriteFile #{out}")
      File.open(opt_file, 'w') do |fh|
        fh.write(out)
      end
    end # packages.each

    # Remove (what should be) empty directories
    remove_categories = old_categories - new_categories.to_a
    remove_categories.each do |c|
      debug("#{function}: removing empty category #{c}")
      FileUtils.rm_rf(File.join(dir, c))
    end

    # Remove stray entries from categories
    new_categories.each do |cat|
      old_entries = Dir.entries(File.join(dir, cat)).select do |entry|
        !(entry == '.' || entry == '..')
      end

      remove_entries = old_entries - new_entries[cat]
      remove_entries.each do |e|
        debug("#{function}: removing empty entry #{cat}/#{e}")
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

    if File.exist?(USE_DIR) && !File.directory?(USE_DIR)
      Puppet.warning("#{USE_DIR} is not a directory, puppet management of USE flags has been disabled")
    else
      Dir.mkdir(USE_DIR) unless File.exist?(USE_DIR)
      set_portage(packages, USE_DIR, 'package_use')
    end

    if File.exist?(ENV_DIR) && !File.directory?(ENV_DIR)
      Puppet.warning("#{ENV_DIR} is not a directory, puppet management of environment variables has been disabled")
    else
      Dir.mkdir(ENV_DIR) unless File.exist?(ENV_DIR)
      set_portage(packages, ENV_DIR, 'package_env')
    end

    if File.directory?('/etc/portage/package.keywords')
      Puppet.warning('/etc/portage/package.keywords may conflict with /etc/portage/package.accept_keywords and cause unexpected behavior')
    end

    if File.exist?(KEYWORDS_DIR) && !File.directory?(KEYWORDS_DIR)
      Puppet.warning("#{KEYWORDS_DIR} is not a directory, puppet management of KEYWORDs has been disabled")
    else
      Dir.mkdir(KEYWORDS_DIR) unless File.exist?(KEYWORDS_DIR)
      set_portage(packages, KEYWORDS_DIR, 'package_keywords')
    end
  end

  ###########################################
  # Utility classes (not for use in self.*) #
  ###########################################

  # string (string)
  def _strip_subslot(slot)
    return slot.split('/').first if slot.count('/') == 1

    slot
  end

  # string[] (string)
  # string[] (string[])
  def resource_tok(string)
    return [] if string.nil?
    return string if string.is_a? Array

    string.split(' ').reject(&:empty?)
  end

  # string (void)
  def package_name
    raise Puppet::ResourceError, 'name must be specified' if @resource[:name].empty?
    raise Puppet::ResourceError, 'name may not contain whitespace' if @resource[:name] =~ /\s/
    raise Puppet::ResourceError, 'name may not end with category boundary' if @resource[:name] =~ %r{/$}
    raise Puppet::ResourceError, 'name may not start with category boundary' if @resource[:name] =~ %r{^/}
    raise Puppet::ResourceError, 'name may not contain multiple category boundaries' if @resource[:name].count('/') > 1
    raise Puppet::ResourceError, 'name may not end with slot boundary' if @resource[:name] =~ /:$/
    raise Puppet::ResourceError, 'name may not start with slot boundary' if @resource[:name] =~ /^:/
    raise Puppet::ResourceError, 'name may not contain repository' if @resource[:name].include?('::')
    raise Puppet::ResourceError, 'name may not contain multiple slot boundaries' if @resource[:name].count(':') > 1

    name = @resource[:name]
    name = name.split(':').first if name.count(':') > 0
    name = name.split('/').last if name.count('/') > 0

    name
  end

  # string (void)
  def package_category
    name = @resource[:name]

    category = nil
    name_category = false

    if name.count('/') > 0
      category = name.split('/').first
      name_category = true
    end

    if @resource[:category]
      if name_category && category != @resource[:category]
        raise Puppet::Error, "Category disagreement on Package[#{name}]"
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

    unless @resource[:package_settings].nil?
      if @resource[:package_settings].key?('slot')
        if name_slot && slot != @resource[:package_settings]['slot'].to_s
          raise Puppet::Error, "Slot disagreement on Package[#{name}]"
        end

        slot = @resource[:package_settings]['slot']
      end
    end

    slot
  end

  # string (void)
  def package_repository
    return nil if @resource[:package_settings].nil?
    return nil unless @resource[:package_settings].key?('repository')

    @resource[:package_settings]['repository']
  end

  # string[] (void)
  def package_use
    return [] if @resource[:package_settings].nil?
    return [] unless @resource[:package_settings].key?('use')

    resource_tok(@resource[:package_settings]['use'])
  end

  # string[] (void)
  def package_env
    return [] if @resource[:package_settings].nil?
    return [] unless @resource[:package_settings].key?('environment')

    resource_tok(@resource[:package_settings]['environment'])
  end

  # string[] (void)
  def package_keywords
    return [] if @resource[:package_settings].nil?
    return [] unless @resource[:package_settings].key?('keywords')

    resource_tok(@resource[:package_settings]['keywords'])
  end

  ###########################
  # Implement required APIs #
  ###########################

  # This populates the "is" value in package_settings_insync?
  # hash (void)
  def package_settings
    query
  end

  # bool (hash, hash)
  def package_settings_insync?(should, is)
    if should.key?('repository')
      return false if should['repository'] != is[:repository]
    end

    should_positive = is[:use_valid] & use_neutral(resource_tok(should['use']))
    should_negative = is[:use_valid] & use_negative(resource_tok(should['use']))

    use_conflict = should_positive & should_negative
    unless use_conflict.empty?
      Puppet.warning("Package[#{package_name}] contains conflicting instructions for USE flag #{use_conflict.inspect}")
      return true
    end

    unless (should_positive - is[:use_positive]).empty?
      # debug("+ use flag not in use #{(should_positive - is[:use_positive]).inspect}")
      return false
    end

    unless (should_negative & is[:use_positive]).empty?
      # debug("- use flag found use: #{(should_negative & is[:use_positive]).inspect}")
      return false
    end

    true
  end

  # void (hash)
  def package_settings=(_settings)
    install
  end

  # void (void)
  def install
    should = @resource.should(:ensure)

    name = package_name

    name = "#{package_category}/#{name}" unless package_category.nil?

    if should == :present || should == :latest
      if package_slot
        # Install a specific slot
        name = "#{name}:#{package_slot}"
      end
    else
      # We must install a specific version
      name = "=#{name}-#{should}"

      # A specific version can't have multiple slots, so no need to specify
    end

    # Install from a specific source
    name = "#{name}::#{package_repository}" if package_repository

    @resource[:install_options] = [] \
      unless @resource[:install_options].is_a? Array

    execute([command(:emerge)] + @resource[:install_options] + [name])
  end

  # void (void)
  def uninstall
    name = package_name
    name = "#{package_category}/#{name}" unless package_category.nil?
    name = "#{name}:#{package_slot}" unless package_slot.nil?
    name = "#{name}::#{package_repository}" unless package_repository.nil?

    emerge('--unmerge', name)
  end

  # void (void)
  def update
    install
  end

  # Returns the currently installed version
  # hash (void)
  def query
    slots = {}
    categories = Set.new

    _package_glob.each do |directory|
      %w(SLOT PF CATEGORY repository USE).each do |expected|
        unless File.exist?("#{directory}/#{expected}")
          raise Puppet::Error, "The metadata file \"#{expected}\" was not found in #{directory}"
        end
      end

      slot = _strip_subslot(File.read("#{directory}/SLOT").rstrip)
      next if package_slot && slot != package_slot

      category = File.read("#{directory}/CATEGORY").rstrip
      categories << category

      repository = File.read("#{directory}/repository").rstrip

      use_positive = resource_tok(File.read("#{directory}/USE").rstrip)

      # I have observed the IUSE file does not exist on packages emerged before a certain date
      # I expect it would be safe to make this file mandatory sometime in 2018
      use_valid = if File.exist?("#{directory}/IUSE")
                    use_strip_positive(resource_tok(File.read("#{directory}/IUSE").rstrip))
                  else
                    []
                  end

      # http://dev.gentoo.org/~ulm/pms/5/pms.html#x1-280003.2
      version = File.read("#{directory}/PF").rstrip.split(/-(?=[0-9])/).last

      # if this slot isn't yet defined in the slots hash, define it with the defaults
      next if slots.key?(slot)

      slots[slot] = {
        repository: repository,
        use_positive: use_positive & use_valid,
        use_valid: use_valid,

        ensure: version
      }
    end

    # Disambiguation errors
    if categories.length > 1
      raise Puppet::Error, "Package[#{@resource[:name]}] is ambiguous, specify a category: #{categories.to_a.join(', ')}"
    end

    if slots.length > 1
      raise Puppet::Error, "Package[#{@resource[:name]}] is ambiguous, specify a slot: #{slots.keys.join(', ')}"
    end

    slots.values.first
  end

  # Returns the string for the newest version of a package available
  # string (void)
  def latest
    slots = {}
    categories = Set.new

    # Chose arguments based on what we've received
    if package_category.nil?
      search_field = '--name'
      search_value = package_name
    else
      search_field = '--category-name'
      search_value = "#{package_category}/#{package_name}"
    end

    eixout = eix('--xml', '--pure-packages', '--exact', search_field, search_value)

    xml = REXML::Document.new(eixout)

    unless EIX_DUMP_VERSION.include?(Integer(xml.root.attributes['version']))
      warnonce("eixdump version is not in: #{EIX_DUMP_VERSION.join(', ')}.")
    end

    xml.elements.each('eixdump/category/package') do |p|
      p.elements.each('version') do |v|
        unless package_repository.nil?
          if package_repository == DEFAULT_REPOSITORY
            next unless v.attributes['repository'].nil?
          elsif v.attributes['repository'] != package_repository
            next
          end
        end

        # Establish variables for reuse
        slot = if v.attributes['slot']
                 _strip_subslot(v.attributes['slot'])
               else
                 DEFAULT_SLOT
               end

        # Update disambiguation values
        categories << p.parent.attributes['name']

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
        hard_unmasked = (!v.elements['mask[@type!=\'keyword\']'] || v.elements['unmask[@type=\'package_unmask\']'])
        keyword_unmasked = (!v.elements['mask[@type=\'keyword\']'] || v.elements['unmask[@type=\'package_keywords\']'])

        # installed versions are always valid candidates for latest
        # this way latest should never try to downgrade a package
        if v.attributes['installed'] && v.attributes['installed'] == '1'
          slots[slot] = v.attributes['id']
          next
        end

        # Check package masks
        if hard_unmasked && keyword_unmasked
          slots[slot] = v.attributes['id']
          next
        end
      end
    end

    # Disambiguation errors
    case categories.length
    when 0
      if package_category
        raise Puppet::Error, "No package found with the specified name [#{search_value}] in category [#{package_category}]: #{categories.to_a.join(' ')}"
      else
        raise Puppet::Error, "No package found with the specified name [#{search_value}]"
      end
    when 1
      # Correct number, we're done here
    else
      categories_available = categories.to_a.join(' ')
      raise Puppet::Error, "Multiple categories [#{categories_available}] available for package [#{search_value}]"
    end

    # If a slot is specified, use it
    return slots[package_slot] unless package_slot.nil?

    # If there's a single slot, use it
    return slots.values.first if slots.length == 1

    # If there's multiple slots including the default, use the default
    return slots[DEFAULT_SLOT] if slots.key?(DEFAULT_SLOT)

    # Multiple slots
    raise Puppet::Error, "Package[#{@resource[:name]}] is ambiguous, specify a slot: #{slots.keys.join(' ')}"
  end

private

  def use_strip_positive(use)
    use.map { |x| x[0, 1] == '+' ? x[1..-1] : x }
  end

  def use_neutral(use)
    use.select { |x| x[0, 1] != '-' && x[0, 1] != '+' }
  end

  def use_negative(use)
    use.select { |x| x[0, 1] == '-' }.map { |x| x[1..-1] }
  end

  def use_positive(use)
    use.select { |x| x[0, 1] == '+' }.map { |x| x[1..-1] }
  end

  # string[] (void)
  def _package_glob
    glob_value = if package_category.nil?
                   "*/#{package_name}"
                 else
                   "#{package_category}/#{package_name}"
                 end

    Dir.glob("#{PACKAGE_STATE_DIR}/#{glob_value}-[0-9]*")
  end
end
