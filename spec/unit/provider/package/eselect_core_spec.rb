#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:eselect).provider(:eselect)

describe provider_class do
	before :each do
		Puppet.expects(:warning).never
	end

	def pkg(args = {})
		defaults = { :provider => 'eselect' }
		Puppet::Type.type(:eselect).new(defaults.merge(args))
	end

	describe "when validating provider functions" do
		[:ensure].each do |param|
			it "should have a #{param} function" do
				provider = provider_class.new
				provider.should respond_to(param)
			end
		end

		["eselect_list"].each do |param|
			it "should have a #{param} internal function" do
				provider = provider_class.new
				provider.should respond_to(param)
			end
		end
	end

	# TODO: fill this out with a proper test suite
end