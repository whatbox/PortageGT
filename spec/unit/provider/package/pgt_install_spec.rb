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

	describe 'installing plain' do
		it 'plain package' do
			provider = provider_class.new(pkg({ :name => "mysql" }))
			provider.expects(:emerge).with('mysql')
			provider.install
		end
	end

	describe 'installing plain with slot' do
		it 'in name' do
			provider = provider_class.new(pkg({ :name => "mysql:2" }))
			provider.expects(:emerge).with('mysql:2')
			provider.install
		end

		it 'attribute' do
			provider = provider_class.new(pkg({ :name => "mysql", :slot => "2" }))
			provider.expects(:emerge).with('mysql:2')
			provider.install
		end

		it 'in name & attribute' do
			provider = provider_class.new(pkg({ :name => "mysql:2", :slot => "2" }))
			provider.expects(:emerge).with('mysql:2')
			provider.install
		end
	end

	describe 'installing with category' do
		it 'in name' do
			provider = provider_class.new(pkg({ :name => "dev-db/mysql" }))
			provider.expects(:emerge).with('dev-db/mysql')
			provider.install
		end

		it 'attribute' do
			provider = provider_class.new(pkg({ :name => "mysql", :category => "floomba" }))
			provider.expects(:emerge).with('floomba/mysql')
			provider.install
		end

		it 'in name & attribute' do
			provider = provider_class.new(pkg({ :name => "bumbling/fool", :category => "bumbling" }))
			provider.expects(:emerge).with('bumbling/fool')
			provider.install
		end
	end

	describe 'installing from repository' do
		it 'latest version' do
			provider = provider_class.new(pkg({ :name => "dev-db/mysql", :repository => "company-overlay" }))
			provider.expects(:emerge).with('dev-db/mysql::company-overlay')
			provider.install
		end

		it 'with slot' do
			provider = provider_class.new(pkg({ :name => "dev-db/mysql", :slot => 2, :repository => "company-overlay" }))
			provider.expects(:emerge).with('dev-db/mysql:2::company-overlay')
			provider.install
		end

		it 'exact version' do
			provider = provider_class.new(pkg({ :name => "mysql", :repository => "other-overlay", :category => "floomba", :ensure => "7.0.2" }))
			provider.expects(:emerge).with('=floomba/mysql-7.0.2::other-overlay')
			provider.install
		end
	end


	describe 'installing with category mismatch' do
		it 'plain' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql", :category => "foobar" }))
				provider.install
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end

		it 'with name slot' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :category => "foobar" }))
				provider.install
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end


		it 'with attr slot' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql", :category => "foobar", :slot => "2" }))
				provider.install
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end


		it 'with name & attribute slot' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :category => "foobar", :slot => "2" }))
				provider.install
			}.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
		end

	end

	describe 'installing with slot mismatch' do
		it 'plain' do
			proc {
				provider = provider_class.new(pkg({ :name => "mysql:2", :slot => "3" }))
				provider.install
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end

		it 'name category' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :slot => "3" }))
				provider.install
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end
		it 'name category' do
			proc {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql:2", :slot => "3", :category => "dev-db" }))
				provider.install
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end

		it 'attribute category' do
			proc {
				provider = provider_class.new(pkg({ :name => "mysql:2", :category => "dev-db", :slot => "3" }))
				provider.install
			}.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
		end
	end

	describe 'deluxe install' do
		it 'plain package' do
			provider = provider_class.new(pkg({ :name => "dev-db/mysql", :slot => "2"}))
			provider.expects(:emerge).with('dev-db/mysql:2')
			provider.install
		end
	end
end