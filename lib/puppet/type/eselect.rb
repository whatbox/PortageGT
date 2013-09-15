# Encoding: utf-8

module Puppet
  newtype(:eselect) do
    newparam(:name) do
      desc 'identifier for use throughout puppet manifests'
      isnamevar
    end

    @doc = 'Switches versions & settings accross slots & programs'

    newparam(:module) do
      desc 'eselect module'

      validate do |value|
        raise Puppet::Error, 'module may not contain whitespace' if value =~ /\s/
      end
    end

    newparam(:submodule) do
      desc 'eselect submodule'

      validate do |value|
        raise Puppet::Error, 'submodule may not contain whitespace' if value =~ /\s/
      end
    end

    newparam(:listcmd) do
      desc 'list command'
    end

    newparam(:setcmd) do
      desc 'set command'
    end

    newproperty(:ensure) do
      desc 'non-standard ensure'
    end
  end
end
