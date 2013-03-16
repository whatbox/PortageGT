#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:eselect) do
	before :all do
		@class = described_class.provider(:eselect)
	end


	it "should have :name as its keyattribute" do
		described_class.key_attributes.should == [:name]
	end


	describe "when validating attributes" do
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
end