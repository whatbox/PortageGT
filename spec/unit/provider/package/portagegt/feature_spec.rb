#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  before :each do
    Puppet.expects(:warning).never
  end

  it 'versionable' do
    expect(provider_class).to be_versionable
  end

  it 'installable' do
    expect(provider_class).to be_installable
  end

  it 'uninstallable' do
    expect(provider_class).to be_uninstallable
  end

  it 'upgradeable' do
    expect(provider_class).to be_upgradeable
  end

  it 'support install_options' do
    expect(provider_class).to be_install_options
  end

  it 'support package_settings' do
    expect(provider_class).to be_package_settings
  end
end
