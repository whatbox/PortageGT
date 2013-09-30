#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  before :each do
    Puppet.expects(:warning).never
  end

  it 'should have an #update function' do
    provider = provider_class.new
    provider.should respond_to('update')
  end

  describe '#update' do
    it 'should invoke #install' do
      provider = provider_class.new
      provider.expects(:install)
      provider.update
    end
  end
end
