#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  before :each do
    Puppet.expects(:warning).never
  end

  it 'should be versionable' do
    provider_class.should be_versionable
  end
  it 'should be installable' do
    provider_class.should be_installable
  end
  it 'should be uninstallable' do
    provider_class.should be_uninstallable
  end
  it 'should be upgradeable' do
    provider_class.should be_upgradeable
  end
end
