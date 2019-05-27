# frozen_string_literal: true

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

  it 'support package_settings' do
    expect(provider_class).to be_package_settings
  end
end
