#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:eselect).provider(:eselect)

describe provider_class do
  before :each do
    Puppet.expects(:warning).never
  end

  def pkg(args = {})
    defaults = { provider: 'eselect' }
    Puppet::Type.type(:eselect).new(defaults.merge(args))
  end

  [:ensure].each do |param|
    it "should have a #{param} function" do
      provider = provider_class.new
      provider.should respond_to(param)
    end
  end

  # TODO: fill this out with a proper test suite
end
