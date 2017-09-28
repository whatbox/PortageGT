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
  def self.prefetch(_packages); end

  # string (void)
  def eselect_module
    if @resource[:name] =~ /^[a-z]+$/
      emodule = @resource[:name]
      name_module = true
    end

    if @resource[:module]
      raise Puppet::Error, "Module disagreement on eselect[#{name}], please check the definition" if name_module && emodule != @resource[:module]

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
      raise Puppet::Error, "module should not be specified if listcmd is in eselect[#{@resource[:name]}], please check the definition" if @resource[:module]
      raise Puppet::Error, "submodule should not be specified if listcmd is in eselect[#{@resource[:name]}], please check the definition" if @resource[:submodule]
      raise Puppet::Error, "listcmd is specified but setcmd is not in eselect[#{@resource[:name]}], please check the definition" if @resource[:setcmd].nil?

      return @resource[:listcmd]
    end

    return "eselect #{eselect_module} list #{eselect_submodule}" if @resource[:submodule]
    "eselect #{eselect_module} list"
  end

  # string (void)
  def eselect_set
    if @resource[:setcmd]
      raise Puppet::Error, "module should not be specified if setcmd is in eselect[#{@resource[:name]}], please check the definition" if @resource[:module]
      raise Puppet::Error, "submodule should not be specified if setcmd is in eselect[#{@resource[:name]}], please check the definition" if @resource[:submodule]
      raise Puppet::Error, "setcmd is specified but listcmd is not in eselect[#{@resource[:name]}], please check the definition" if @resource[:listcmd].nil?

      return @resource[:setcmd]
    end

    return "eselect #{eselect_module} set #{eselect_submodule}" if @resource[:submodule]
    "eselect #{eselect_module} set"
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

      if option.last == '*'
        raise Puppet::Error, "Multiple selected versions for eselect[#{@resource[:name]}]" unless selected.nil?

        selected = option[1]

      end

      options.push(option[1])
    end

    raise Puppet::Error, "Invalid option \"#{should}\", should be one of [#{options.join(' ')}] for eselect[#{@resource[:name]}]" unless options.include? should

    selected
  end

  # void (string)
  def ensure=(target)
    Puppet::Util::Execution.execute("#{eselect_set} #{target}")
  end
end
