#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
	before :each do
		provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

		Puppet.expects(:warning).never
	end

	def pkg(args = {})
		defaults = { :provider => 'portagegt' }
		Puppet::Type.type(:package).new(defaults.merge(args))
	end

	# We have skipped testing disambiugation because that should be handled at the package 
	# level, if there's an ambiguous case, it will never make it to the uninstall function

	describe '#uninstall' do
		context "when using a package name with no category" do
			it {
				provider = provider_class.new(pkg({ :name => "mysql" }))
				provider.expects(:emerge).with('--unmerge','mysql')
				provider.uninstall
			}
		end

		context 'when using a package name with no category and a slot' do
			it {
				provider = provider_class.new(pkg({ :name => "mysql:2" }))
				provider.expects(:emerge).with('--unmerge','mysql:2')
				provider.uninstall
			}

			it {
				provider = provider_class.new(pkg({ :name => "mysql", :slot => "2" }))
				provider.expects(:emerge).with('--unmerge','mysql:2')
				provider.uninstall
			}

			it {
				provider = provider_class.new(pkg({ :name => "mysql:2", :slot => "2" }))
				provider.expects(:emerge).with('--unmerge','mysql:2')
				provider.uninstall
			}
		end

		context "when using a category/name for the package" do
			it {
				provider = provider_class.new(pkg({ :name => "dev-db/mysql" }))
				provider.expects(:emerge).with('--unmerge','dev-db/mysql')
				provider.uninstall
			}

			it {
				provider = provider_class.new(pkg({ :name => "mysql", :category => "floomba" }))
				provider.expects(:emerge).with('--unmerge','floomba/mysql')
				provider.uninstall
			}

			it {
				provider = provider_class.new(pkg({ :name => "bumbling/fool", :category => "bumbling" }))
				provider.expects(:emerge).with('--unmerge','bumbling/fool')
				provider.uninstall
			}
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