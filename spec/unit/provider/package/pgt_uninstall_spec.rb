#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
	def pkg(args = {})
		defaults = { :provider => 'portagegt' }
		Puppet::Type.type(:package).new(defaults.merge(args))
	end

	before :each do
		# Stub some provider methods to avoid needing the actual software
		# installed, so we can test on whatever platform we want.
		provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

		Puppet.expects(:warning).never
	end

	describe 'uninstalling plain' do
		it 'plain package' do
			provider = provider_class.new(pkg({ :name => "mysql" }))
			provider.expects(:emerge).with('--unmerge','mysql')
			provider.uninstall
		end
	end

	describe 'uninstalling plain with slot' do
		it 'in name' do
			provider = provider_class.new(pkg({ :name => "mysql:2" }))
			provider.expects(:emerge).with('--unmerge','mysql:2')
			provider.uninstall
		end

		it 'attribute' do
			provider = provider_class.new(pkg({ :name => "mysql", :slot => "2" }))
			provider.expects(:emerge).with('--unmerge','mysql:2')
			provider.uninstall
		end

		it 'in name & attribute' do
			provider = provider_class.new(pkg({ :name => "mysql:2", :slot => "2" }))
			provider.expects(:emerge).with('--unmerge','mysql:2')
			provider.uninstall
		end
	end

	describe 'uninstalling with category' do
		it 'in name' do
			provider = provider_class.new(pkg({ :name => "dev-db/mysql" }))
			provider.expects(:emerge).with('--unmerge','dev-db/mysql')
			provider.uninstall
		end

		it 'attribute' do
			provider = provider_class.new(pkg({ :name => "mysql", :category => "floomba" }))
			provider.expects(:emerge).with('--unmerge','floomba/mysql')
			provider.uninstall
		end

		it 'in name & attribute' do
			provider = provider_class.new(pkg({ :name => "bumbling/fool", :category => "bumbling" }))
			provider.expects(:emerge).with('--unmerge','bumbling/fool')
			provider.uninstall
		end
	end

	describe 'uninstalling with category mismatch' do
		it 'plain' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql", :category => "foobar" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end

		it 'with name slot' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :category => "foobar" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end


		it 'with attr slot' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql", :category => "foobar", :slot => "2" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end


		it 'with name & attribute slot' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :category => "foobar", :slot => "2" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end
	end

	describe 'uninstalling with slot mismatch' do
		it 'plain' do
			proc {
				provider = provider_class.new(pkg({ :name => "mysql:2", :slot => "3" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end

		it 'name category' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :slot => "3" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end
		it 'name category' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :slot => "3", :category => "dev-db" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end

		it 'attribute category' do
			proc {
				provider = provider_class.new(pkg({ :name => "mysql:2", :category => "dev-db", :slot => "3" }))
				provider.uninstall
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end
	end

	describe 'deluxe install' do
		it 'plain package' do
			provider = provider_class.new(pkg({ :name => "dev-db/mysql", :slot => "2"}))
			provider.expects(:emerge).with('--unmerge','dev-db/mysql:2')
			provider.uninstall
		end
	end
end