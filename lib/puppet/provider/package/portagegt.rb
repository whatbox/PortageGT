# frozen_string_literal: true

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

Puppet::Type.type(:package).provide(
  :portagegt,
  parent: Puppet::Provider::Package
) do
  ##################
  # Config Options #
  ##################

  # You probably don't want to change these
  DEFAULT_SLOT = '0'
  DEFAULT_REPOSITORY = 'gentoo'
  USE_DIR = '/etc/portage/package.use'
  ENV_DIR = '/etc/portage/package.env'
  KEYWORDS_DIR = '/etc/portage/package.accept_keywords'
  LICENSE_DIR = '/etc/portage/package.license'
  PACKAGE_STATE_DIR = '/var/db/pkg'
  TIMESTAMP_FILE = '/usr/portage/metadata/timestamp'
  # TODO: ensure we respect the DISTDIR environment variable in make.conf
  DISTFILES_DIR = '/usr/portage/distfiles'

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

  has_feature :package_settings
  # Method package_settings_insync? is available
  # Method package_settings is available
  # Method package_settings= is available

  commands emerge: '/usr/bin/emerge'

  attr_accessor :old_query

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

  # void (package[], string dir, string opts, string function)
  def self.set_portage(packages, dir, function)
    File.open(File.join(dir, 'puppet-packages'), 'w') do |fh|
      packages.each do |name, package|
        # Early check variables
        category = package.provider.package_category
        opt_flags = package.provider.send(function)

        next if opt_flags.empty?

        if category.nil?
          Puppet.warning("Cannot apply #{function} for Package[#{name}] without a category") unless opt_flags.empty?
          next
        end

        # Remaining variables
        slot = package.provider.package_slot

        out = "#{category}/#{package.provider.package_name}"
        out = "#{out}:#{slot}" if slot && slot != DEFAULT_SLOT
        out = "#{out} #{opt_flags.sort.join(' ')}\n"

        fh.write(out)
      end
    end
  end

  ######################
  # Puppet self.* APIs #
  ######################

  # One of void self.prefetch(package[]) or package[] self.instances() must be used
  def self.prefetch(packages)
    emerge('--sync')

    !File.file?('/var/lib/portage/world') \
    || File.open('/var/lib/portage/world').readlines.empty? \
    || Puppet.warning('Please migrate @world packages into puppet manifests then deselect them')

    File.write('/var/lib/portage/world_sets', "@puppet\n") unless File.exist?('/var/lib/portage/world_sets')

    sets = []
    File.open('/var/lib/portage/world_sets', 'r') do |fh|
      fh.each_line do |line|
        sets << line.chop
      end
    end

    File.write('/var/lib/portage/world_sets', "@puppet\n", mode: 'a') unless sets.include?('@puppet')

    sets.each do |set|
      next if set == '@puppet'

      Puppet.notice("Including updates for #{set}")
    end

    Dir.mkdir('/etc/portage/sets') unless File.exist?('/etc/portage/sets')
    File.open('/etc/portage/sets/puppet', 'w') do |fh|
      packages.each do |name, package|
        should = package.should(:ensure)
        next if %i[absent purged].include?(should)

        if package.provider.package_category.nil?
          Puppet.warning("Please specify a category for Package[#{name}]") unless opt_flags.empty?
          next
        end

        name = "#{package.provider.package_category}/#{package.provider.package_name}"

        if %i[present latest].include?(should)
          if package.provider.package_slot
            # Install a specific slot
            name = "#{name}:#{package.provider.package_slot}"
          end
        else
          # We must install a specific version
          name = "=#{name}-#{should}"

          # A specific version can't have multiple slots, so no need to specify
        end

        # Install from a specific source
        name = "#{name}::#{package.provider.package_repository}" if package.provider.package_repository

        fh.write("#{name}\n")
      end
    end

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

    Puppet.warning('/etc/portage/package.keywords may conflict with /etc/portage/package.accept_keywords and cause unexpected behavior') if File.directory?('/etc/portage/package.keywords')

    if File.exist?(KEYWORDS_DIR) && !File.directory?(KEYWORDS_DIR)
      Puppet.warning("#{KEYWORDS_DIR} is not a directory, puppet management of KEYWORDs has been disabled")
    else
      Dir.mkdir(KEYWORDS_DIR) unless File.exist?(KEYWORDS_DIR)
      set_portage(packages, KEYWORDS_DIR, 'package_keywords')
    end

    if File.exist?(KEYWORDS_DIR) && !File.directory?(KEYWORDS_DIR)
      Puppet.warning("#{KEYWORDS_DIR} is not a directory, puppet management of KEYWORDs has been disabled")
    else
      Dir.mkdir(LICENSE_DIR) unless File.exist?(LICENSE_DIR)
      set_portage(packages, LICENSE_DIR, 'package_license')
    end

    packages.each do |_name, package|
      package.provider.old_query = package.provider._query
    end

    # we don't inherit the default umask from /etc/profile when launching
    # programs, so we must set this ourselves
    Puppet::Util.withumask(0o022) do
      # Updating portage before other packages as Gentoo reccomends actually just results in more failures
      emerge('--quiet-build', '--update', '--deep', '--changed-use', '--with-bdeps=y', '@system', '@puppet')
    end
  end

  def self.post_resource_eval
    emerge('@preserved-rebuild')
    emerge('--depclean')

    # Purge distfiles
    FileUtils.rm_r(Dir.glob(DISTFILES_DIR + '/*'), secure: true)
  end

  ###########################################
  # Utility classes (not for use in self.*) #
  ###########################################

  # string (string)
  def _strip_subslot(slot)
    return slot.split('/').first if slot.include?('/')

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
    name = name.split(':').first if name.include?(':')
    name = name.split('/').last if name.include?('/')

    name
  end

  # string (void)
  def package_category
    name = @resource[:name]

    category = nil
    name_category = false

    if name.include?('/')
      category = name.split('/').first
      name_category = true
    end

    if @resource[:category]
      raise Puppet::Error, "Category disagreement on Package[#{name}]" if name_category && category != @resource[:category]

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
        raise Puppet::Error, "Slot disagreement on Package[#{name}]" if name_slot && slot != @resource[:package_settings]['slot'].to_s

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

  # string[] (void)
  def package_license
    return [] if @resource[:package_settings].nil?
    return [] unless @resource[:package_settings].key?('license')

    resource_tok(@resource[:package_settings]['license'])
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
  def package_settings_insync?(should, present)
    if should.key?('repository')
      debug('repository mismatch')
      return false if should['repository'] != present[:repository]
    end

    invalid_use = use_neutral(resource_tok(should['use'])) - present[:use_valid]
    invalid_use = invalid_use.reject do |use|
      # Don't try to validate wildcard use flags (commonly seen )
      use.end_with?('_*')
    end
    Puppet.warning("Package[#{package_name}] USE flag #{invalid_use.inspect} does not exist") unless invalid_use.empty?

    invalid_use = use_negative(resource_tok(should['use'])) - present[:use_valid]
    invalid_use = invalid_use.reject do |use|
      # Don't try to validate wildcard use flags (commonly seen )
      use.end_with?('_*')
    end
    Puppet.notice("Package[#{package_name}] USE flag #{invalid_use.inspect} has been removed") unless invalid_use.empty?

    should_positive = present[:use_valid] & use_neutral(resource_tok(should['use']))
    should_negative = present[:use_valid] & use_negative(resource_tok(should['use']))

    use_conflict = should_positive & should_negative
    unless use_conflict.empty?
      Puppet.warning("Package[#{package_name}] contains conflicting instructions for USE flag #{use_conflict.inspect}")
      return true
    end

    # If the build timestamps match
    # we didn't make changes because of the config
    old_query[:build_time] == present[:build_time]
  end

  # void (hash)
  def package_settings=(_settings)
    # Do nothing
  end

  # void (void)
  def install
    # Do nothing
  end

  # void (void)
  def uninstall
    # Do nothing
  end

  # void (void)
  def update
    install
  end

  # Returns the currently installed version
  # hash (void)
  def query
    old_query
  end

  # Returns the currently installed version
  # hash (void)
  def _query
    slots = {}
    categories = Set.new

    _package_glob.each do |directory|
      %w[SLOT PF CATEGORY repository USE BUILD_TIME].each do |expected|
        raise Puppet::Error, "The metadata file \"#{expected}\" was not found in #{directory}" unless File.exist?("#{directory}/#{expected}")
      end

      slot = _strip_subslot(File.read("#{directory}/SLOT").rstrip)
      next if package_slot && slot != package_slot

      category = File.read("#{directory}/CATEGORY").rstrip
      categories << category

      repository = File.read("#{directory}/repository").rstrip
      build_time = File.read("#{directory}/BUILD_TIME").to_i

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
        build_time: build_time,
        use_valid: use_valid,
        ensure: version
      }
    end

    # Disambiguation errors
    raise Puppet::Error, "Package[#{@resource[:name]}] is ambiguous, specify a category: #{categories.to_a.join(', ')}" if categories.length > 1
    raise Puppet::Error, "Package[#{@resource[:name]}] is ambiguous, specify a slot: #{slots.keys.join(', ')}" if slots.length > 1

    slots.values.first
  end

  # Returns the string for the newest version of a package available
  # string (void)
  def latest
    _query[:ensure]
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
