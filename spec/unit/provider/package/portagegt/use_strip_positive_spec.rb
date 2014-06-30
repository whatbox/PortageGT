#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe 'private: use_strip_positive' do
    it 'single, entry no positive flag' do
      provider = provider_class.new(pkg(name: 'mysql'))
      provider.send(:use_strip_positive, ['hpn']).should == ['hpn']
    end

    it 'single entry, positive flag' do
      provider = provider_class.new(pkg(name: 'mysql'))
      provider.send(:use_strip_positive, ['+hpn']).should == ['hpn']
    end
  end
end
