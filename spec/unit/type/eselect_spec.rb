#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

describe Puppet::Type.type(:eselect) do
  before :all do
    @class = described_class.provider(:eselect)
  end

  it 'should have :name as its keyattribute' do
    described_class.key_attributes.should == [:name]
  end

  [:name, :module, :submodule, :listcmd, :setcmd].each do |param|
    it "should have a #{param} parameter" do
      described_class.attrtype(param).should == :param
    end
  end

  [:ensure].each do |param|
    it "should have a #{param} property" do
      described_class.attrtype(param).should == :property
    end
  end
end
