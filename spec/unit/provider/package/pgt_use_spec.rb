#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do

	before :each do
		Puppet.expects(:warning).never
	end

	describe "only changes" do
		it 'is empty' do
			dir = provider_class.cfg(:useDir)

			Dir.stubs(:entries).with(dir).returns([]).once
			Dir.expects(:mkdir).never
			File.expects(:read).never
			File.expects(:open).never
			FileUtils.expects(:rm_rf).never
			provider_class.setPortage({}, dir, 'package_use')
		end

		it 'single file, contents match' do
			dir = provider_class.cfg(:useDir)
			optDir = File.join(dir, 'dev-db')
			optFile = File.join(optDir, 'mysql')

			# Implement what we're simulating
			provider = stub 'provider'
			provider.stubs(:package_name).returns("mysql")
			provider.stubs(:package_category).returns("dev-db")
			provider.stubs(:package_slot).returns(nil)
			provider.stubs(:package_use).returns(['bar','baz','foo'])

			# Don't need to do much, here, as we're overriding the method abstractions above
			resource = stub 'resource'
			resource.stubs(:provider).returns(provider)

			# Put it into a comparable structure
			resources = {"dev-db/mysql" => resource}

			# Stub file stuff
			File.stubs(:directory?).with(optDir).returns(true)
			File.stubs(:file?).with(optFile).returns(true)
			File.stubs(:read).with(optFile).returns("dev-db/mysql bar baz foo\n")
			Dir.stubs(:entries).with(dir).returns(['dev-db']).once
			Dir.stubs(:entries).with(optDir).returns(['mysql']).once
			
			# Explicitly state what shouldn't be necessary
			Dir.expects(:mkdir).never
			File.expects(:open).never
			FileUtils.expects(:rm_rf).never
			File.stubs(:write).never

			# Execute
			provider_class.setPortage(resources, dir, 'package_use')
		end

		it 'single file, contents mismatch' do
			dir = provider_class.cfg(:useDir)
			optDir = File.join(dir, 'dev-db')
			optFile = File.join(optDir, 'mysql')

			# Implement what we're simulating
			provider = stub 'provider'
			provider.stubs(:package_name).returns("mysql")
			provider.stubs(:package_category).returns("dev-db")
			provider.stubs(:package_slot).returns(nil)
			provider.stubs(:package_use).returns(['bar','baz','foo'])

			# Don't need to do much, here, as we're overriding the method abstractions above
			resource = stub 'resource'
			resource.stubs(:provider).returns(provider)

			# Put it into a comparable structure
			resources = {"dev-db/mysql" => resource}

			#One fake file
			contents = stub 'file-handle'

			# Stub file stuff
			File.stubs(:directory?).with(optDir).returns(true)
			File.stubs(:file?).with(optFile).returns(true)
			File.stubs(:read).with(optFile).returns("dev-db/mysql bar baz\n")
			Dir.stubs(:entries).with(dir).returns(['dev-db']).once
			Dir.stubs(:entries).with(optDir).returns(['mysql']).once
			File.stubs(:open).with(optFile, 'w').yields(contents).once

			# Explicitly state what shouldn't be necessary
			Dir.expects(:mkdir).never
			FileUtils.expects(:rm_rf).never
			contents.expects(:write).with("dev-db/mysql bar baz foo\n").once
			contents.expects(:write).never

			# Execute
			provider_class.setPortage(resources, dir, 'package_use')
		end
	end #onlyChanges

	describe "excess category removal" do
		it 'is empty' do
			dir = provider_class.cfg(:useDir)

			Dir.stubs(:entries).with(dir).returns(['fooblah','random']).once
			Dir.expects(:mkdir).never
			File.expects(:read).never
			File.expects(:open).never
			FileUtils.expects(:rm_rf).with(File.join(dir,'fooblah')).once
			FileUtils.expects(:rm_rf).with(File.join(dir,'random')).once
			FileUtils.expects(:rm_rf).never
			provider_class.setPortage({}, dir, 'package_use')
		end

		it 'single file, contents match' do
			dir = provider_class.cfg(:useDir)
			optDir = File.join(dir, 'dev-db')
			optFile = File.join(optDir, 'mysql')

			# Implement what we're simulating
			provider = stubs 'provider'
			provider.stubs(:package_name).returns("mysql")
			provider.stubs(:package_category).returns("dev-db")
			provider.stubs(:package_slot).returns(nil)
			provider.stubs(:package_use).returns(['bar','baz','foo'])

			# Don't need to do much, here, as we're overriding the method abstractions above
			resource = stub 'resource'
			resource.stubs(:provider).returns(provider)

			# Put it into a comparable structure
			resources = {"dev-db/mysql" => resource}

			# Stub file stuff
			File.stubs(:directory?).with(optDir).returns(true)
			File.stubs(:file?).with(optFile).returns(true)
			File.stubs(:read).with(optFile).returns("dev-db/mysql bar baz foo\n")
			Dir.stubs(:entries).with(dir).returns(['dev-db','something-else']).once
			Dir.stubs(:entries).with(optDir).returns(['mysql']).once
			
			# Explicitly state what shouldn't be necessary
			Dir.expects(:mkdir).never
			File.expects(:open).never
			FileUtils.expects(:rm_rf).with(File.join(dir, 'something-else')).once
			FileUtils.expects(:rm_rf).never
			File.stubs(:write).never

			# Execute
			provider_class.setPortage(resources, dir, 'package_use')
		end

		it 'single file, content mismatch' do
			dir = provider_class.cfg(:useDir)
			optDir = File.join(dir, 'dev-db')
			optFile = File.join(optDir, 'mysql')

			# Implement what we're simulating
			provider = stub 'provider'
			provider.stubs(:package_name).returns("mysql")
			provider.stubs(:package_category).returns("dev-db")
			provider.stubs(:package_slot).returns(nil)
			provider.stubs(:package_use).returns(['bar','baz','foo'])

			# Don't need to do much, here, as we're overriding the method abstractions above
			resource = stub 'resource'
			resource.stubs(:provider).returns(provider)

			# Put it into a comparable structure
			resources = {"dev-db/mysql" => resource}

			#One fake file
			contents = stub 'file-handle'

			# Stub file stuff
			File.stubs(:directory?).with(optDir).returns(true)
			File.stubs(:file?).with(optFile).returns(true)
			File.stubs(:read).with(optFile).returns("dev-db/mysql bar baz\n")
			Dir.stubs(:entries).with(dir).returns(['dev-db','blarg']).once
			Dir.stubs(:entries).with(optDir).returns(['mysql']).once
			File.stubs(:open).with(optFile, 'w').yields(contents).once
			File.stubs(:open).never

			# Explicitly state what shouldn't be necessary
			Dir.expects(:mkdir).never
			FileUtils.expects(:rm_rf).with(File.join(dir, 'blarg'))
			FileUtils.expects(:rm_rf).never
			contents.expects(:write).with("dev-db/mysql bar baz foo\n").once
			contents.expects(:write).never

			# Execute
			provider_class.setPortage(resources, dir, 'package_use')
		end

	end #excessCategoryRemoval

	describe "mult-slot packages" do
		it 'php 5.3 & 5.4' do
			dir = provider_class.cfg(:useDir)
			optDir = File.join(dir, 'dev-lang')
			optFile = File.join(optDir, 'php')

			# Implement what we're simulating
			provider1 = stub 'provider'
			provider1.stubs(:package_name).returns("php")
			provider1.stubs(:package_category).returns("dev-lang")
			provider1.stubs(:package_slot).returns("5.4")
			provider1.stubs(:package_use).returns(['something','-without'])

			# Don't need to do much, here, as we're overriding the method abstractions above
			resource1 = stub 'resource'
			resource1.stubs(:provider).returns(provider1)

			# Implement what we're simulating
			provider2 = stub 'provider'
			provider2.stubs(:package_name).returns("php")
			provider2.stubs(:package_category).returns("dev-lang")
			provider2.stubs(:package_slot).returns("5.3")
			provider2.stubs(:package_use).returns(['alternate','-other'])

			# Don't need to do much, here, as we're overriding the method abstractions above
			resource2 = stub 'resource'
			resource2.stubs(:provider).returns(provider2)

			# Put it into a comparable structure
			resources = {"dev-lang/php" => resource1, "dev-lang/php:5.3" => resource2}

			# Stub file stuff
			File.stubs(:directory?).with(optDir).returns(true)
			File.stubs(:file?).with("#{optFile}:5.4").returns(true)
			File.stubs(:file?).with("#{optFile}:5.3").returns(true)
			File.stubs(:read).with("#{optFile}:5.4").returns("dev-lang/php:5.4 something -without\n")
			File.stubs(:read).with("#{optFile}:5.3").returns("dev-lang/php:5.3 alternate -other\n")
			Dir.stubs(:entries).with(dir).returns(['dev-lang']).once
			Dir.stubs(:entries).with(optDir).returns(['php:5.4','php:5.3']).once
			File.stubs(:open).never

			# Explicitly state what shouldn't be necessary
			Dir.expects(:mkdir).never
			FileUtils.expects(:rm_rf).never

			# Execute
			provider_class.setPortage(resources, dir, 'package_use')
		end
	end

	describe "failure cases" do
		it 'use without category' do

			# Implement what we're simulating
			provider = stub 'provider'
			provider.stubs(:package_name).returns("mysql")
			provider.stubs(:package_category).returns(nil)
			provider.stubs(:package_use).returns(['someflag'])

			# Don't need to do much, here, as we're overriding the method abstractions above
			resource = stub 'resource'
			resource.stubs(:provider).returns(provider)

			# Put it into a comparable structure
			resources = {"mysql" => resource}

			# Stub file stuff
			File.stubs(:directory?).never
			File.stubs(:file?).never
			File.stubs(:read).never
			Dir.stubs(:entries).returns([]).once
			File.stubs(:open).never
			Dir.expects(:mkdir).never
			FileUtils.expects(:rm_rf).never

			Puppet.expects(:warning).with('Cannot apply package_use for Package[mysql] without a category').once

			# Execute
			provider_class.setPortage(resources, provider_class.cfg(:useDir), 'package_use')
		end
	end #failureCases
end