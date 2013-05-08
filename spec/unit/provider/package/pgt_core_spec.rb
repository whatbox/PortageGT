#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
	before :each do
		Puppet.expects(:warning).never
	end

	describe "when validating provider features" do
		it "should be versionable" do
			provider_class.should be_versionable
		end
		it "should be installable" do
			provider_class.should be_installable
		end
		it "should be uninstallable" do
			provider_class.should be_uninstallable
		end
		it "should be upgradeable" do
			provider_class.should be_upgradeable
		end
	end

	describe "when validating provider functions" do
		[:install, :uninstall, :update, :latest, :query].each do |param|
			it "should have a #{param} function" do
				provider = provider_class.new
				provider.should respond_to(param)
			end
		end

		["package_name", "package_category", "package_slot", "package_use", "package_keywords"].each do |param|
			it "should have a #{param} internal function" do
				provider = provider_class.new
				provider.should respond_to(param)
			end
		end
	end

	describe 'when updating' do
		it 'should use install to update' do
			provider = provider_class.new
			provider.expects(:install)
			provider.update
		end
	end
end