#!/usr/bin/env rspec
# Encoding: utf-8

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
		it "with no paremeters" do
			provider = provider_class.new(pkg({ :name => 'mysql' }))
			provider.expects(:emerge).with('--unmerge', 'mysql')
			provider.uninstall
		end

		context 'with slot parameter' do
			it 'in the name' do
				provider = provider_class.new(pkg({ :name => 'mysql:2' }))
				provider.expects(:emerge).with('--unmerge', 'mysql:2')
				provider.uninstall
			end

			it 'in the params' do
				provider = provider_class.new(pkg({ :name => 'mysql', :slot => '2' }))
				provider.expects(:emerge).with('--unmerge', 'mysql:2')
				provider.uninstall
			end

			it 'in the name & params' do
				provider = provider_class.new(pkg({ :name => 'mysql:2', :slot => '2' }))
				provider.expects(:emerge).with('--unmerge', 'mysql:2')
				provider.uninstall
			end

			it 'mismatched between the name & params' do
				provider = provider_class.new(pkg({ :name => 'dev-db/mysql:2', :slot => '3' }))
				proc { provider.uninstall }.should raise_error(Puppet::Error, /Slot disagreement on Package.*, please check the definition/)
			end
		end

		context 'with category parameter' do
			it 'in the name' do
				provider = provider_class.new(pkg({ :name => 'dev-db/mysql' }))
				provider.expects(:emerge).with('--unmerge', 'dev-db/mysql')
				provider.uninstall
			end

			it 'in the params' do
				provider = provider_class.new(pkg({ :name => 'mysql', :category => 'dev-db' }))
				provider.expects(:emerge).with('--unmerge', 'dev-db/mysql')
				provider.uninstall
			end

			it 'in the name & params' do
				provider = provider_class.new(pkg({ :name => 'foobar/mysql', :category => 'foobar' }))
				provider.expects(:emerge).with('--unmerge', 'foobar/mysql')
				provider.uninstall
			end

			it 'mismatched between the name & params' do
				provider = provider_class.new(pkg({ :name => 'dev-db/mysql', :category => 'nope' }))
				proc { provider.uninstall }.should raise_error(Puppet::Error, /Category disagreement on Package.*, please check the definition/)
			end
		end

		context 'with repository parameter' do
			it 'in the params' do
				provider = provider_class.new(pkg({ :name => 'mysql', :repository => 'awesome-overlay' }))
				provider.expects(:emerge).with('--unmerge', 'mysql::awesome-overlay')
				provider.uninstall
			end
		end

		context 'with category & slot' do
			it 'in the name' do
				provider = provider_class.new(pkg({ :name => 'dev-db/mysql:2' }))
				provider.expects(:emerge).with('--unmerge', 'dev-db/mysql:2')
				provider.uninstall
			end

			it 'in the params' do
				provider = provider_class.new(pkg({ :name => 'mysql', :category => 'dev-db', :slot => '5.5' }))
				provider.expects(:emerge).with('--unmerge', 'dev-db/mysql:5.5')
				provider.uninstall
			end

			it 'in the name & params' do
				provider = provider_class.new(pkg({ :name => 'foo/bar:baz', :category => 'foo', :slot => 'baz' }))
				provider.expects(:emerge).with('--unmerge', 'foo/bar:baz')
				provider.uninstall
			end
		end

		context 'with category & repository' do
			it 'in the params' do
				provider = provider_class.new(pkg({ :name => 'php', :category => 'dev-lang', :repository => 'internal' }))
				provider.expects(:emerge).with('--unmerge', 'dev-lang/php::internal')
				provider.uninstall
			end
		end

		context 'with slot & repository' do
			it 'in the params' do
				provider = provider_class.new(pkg({ :name => 'program', :slot => 'ruby18', :repository => 'internal' }))
				provider.expects(:emerge).with('--unmerge', 'program:ruby18::internal')
				provider.uninstall
			end
		end

		context 'with category, slot & repository' do
			it 'in the params' do
				provider = provider_class.new(pkg({ :name => 'python', :category => "dev-lang", :slot => '3.3', :repository => 'gentoo' }))
				provider.expects(:emerge).with('--unmerge', 'dev-lang/python:3.3::gentoo')
				provider.uninstall
			end
		end
	end
end