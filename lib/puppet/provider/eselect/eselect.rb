# Encoding: utf-8

Puppet::Type.type(:eselect).provide(:eselect) do
  include Puppet::Util::Execution

  ################
  # Puppet Setup #
  ################

  desc "Provides support for Gentoo's eselect system."
  confine operatingsystem: :gentoo

  # Because we allow custom list / set commands, it's cleaner not to use this
  # commands :eselect => '/usr/bin/eselect'

  ######################
  # Puppet self.* APIs #
  ######################

  # One of void self.prefetch(package[]) or package[] self.instances() must be used
  def self.prefetch(_packages)
  end

  # string (void)
  def eselect_module
    if @resource[:name] =~ /^[a-z]+$/
      emodule = @resource[:name]
      name_module = true
    end

    if @resource[:module]
      if name_module && emodule != @resource[:module]
        fail Puppet::Error, "Module disagreement on eselect[#{name}], please check the definition"
      end

      emodule = @resource[:module]
    end

    emodule
  end

  # string (void)
  def eselect_submodule
    submodule = nil

    submodule = @resource[:submodule] if @resource[:submodule]

    submodule
  end

  # string (void)
  def eselect_list
    if @resource[:listcmd]
      if @resource[:module]
        fail Puppet::Error, "module should not be specified if listcmd is in eselect[#{@resource[:name]}], please check the definition"
      end

      if @resource[:submodule]
        fail Puppet::Error, "submodule should not be specified if listcmd is in eselect[#{@resource[:name]}], please check the definition"
      end

      if @resource[:setcmd].nil?
        fail Puppet::Error, "listcmd is specified but setcmd is not in eselect[#{@resource[:name]}], please check the definition"
      end

      return @resource[:listcmd]
    end

    if @resource[:submodule]
      return "eselect #{eselect_module} list #{eselect_submodule}"
    else
      return "eselect #{eselect_module} list"
    end
  end

  # string (void)
  def eselect_set
    if @resource[:setcmd]
      if @resource[:module]
        fail Puppet::Error, "module should not be specified if setcmd is in eselect[#{@resource[:name]}], please check the definition"
      end

      if @resource[:submodule]
        fail Puppet::Error, "submodule should not be specified if setcmd is in eselect[#{@resource[:name]}], please check the definition"
      end

      if @resource[:listcmd].nil?
        fail Puppet::Error, "setcmd is specified but listcmd is not in eselect[#{@resource[:name]}], please check the definition"
      end

      return @resource[:setcmd]
    end

    if @resource[:submodule]
      return "eselect #{eselect_module} set #{eselect_submodule}"
    else
      return "eselect #{eselect_module} set"
    end
  end

  # string (void)
  def ensure
    should = @resource.should(:ensure)

    output = Puppet::Util::Execution.execute(eselect_list)

    selected = nil
    options = []
    output.split(/\r?\n/).each do |line|
      option = line.strip.split(/\s+/)

      next if option[0] !~ /\[\d+\]/

      if option[option.length - 1] == '*'
        fail Puppet::Error, "Multiple selected versions for eselect[#{@resource[:name]}]" unless selected.nil?

        selected = option[1]
      end

      options.push(option[1])
    end

    unless options.include? should
      available_options = options.join(' ')
      fail Puppet::Error, "Invalid option \"#{should}\", should be one of [#{available_options}] for eselect[#{@resource[:name]}]"
    end

    selected
  end

  # void (string)
  def ensure=(target)
    Puppet::Util::Execution.execute("#{eselect_set} #{target}")
  end
end
