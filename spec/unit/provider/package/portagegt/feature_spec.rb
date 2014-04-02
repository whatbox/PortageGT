#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  before :each do
    Puppet.expects(:warning).never
  end

  it 'versionable' do
    provider_class.should be_versionable
  end

  it 'installable' do
    provider_class.should be_installable
  end

  it 'uninstallable' do
    provider_class.should be_uninstallable
  end

  it 'upgradeable' do
    provider_class.should be_upgradeable
  end

  it 'support install_options' do
    provider_class.should be_install_options
  end

  it 'support package_settings' do
    provider_class.should be_package_settings
  end
end
