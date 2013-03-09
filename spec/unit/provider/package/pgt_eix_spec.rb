#!/usr/bin/env rspec

require 'yaml'
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
		provider_class.stubs(:command).with(:eix).returns('/usr/bin/eix')
		provider_class.stubs(:command).with(:eix_update).returns('/usr/bin/eix-update')
		provider_class.stubs(:command).with(:eix_sync).returns('/usr/bin/eix-sync')

		Puppet.expects(:warning).never
	end

	it 'prefetch' do
		if !provider_class.cfg(:eixRunUpdate) && provider_class.cfg(:eixRunSync)
			proc {
				provider_class.runEix
			}.should raise_error(Puppet::Error, /eixRunUpdate must be true if eixRunSync is true/)
		elsif provider_class.cfg(:eixRunSync)
			provider_class.expects(:eix_sync)
			provider_class.runEix
		else
			provider_class.expects(:eix_update)
			provider_class.runEix
		end
	end #prefetch

	describe 'version string comparison' do

		it 'ambiguous manifest' do
			fh = File.open("spec/unit/provider/package/eix/mysql_loose.xml", "rb")
			mysql_loose = fh.read
			fh.close()

			proc {
				provider_class.stubs(:eix).with("--xml", "--pure-packages", "--exact", "--name", "mysql").returns(mysql_loose)

				provider = provider_class.new(pkg({ :name => "mysql", :ensure => :latest }))
				provider.query
			}.should  raise_error(Puppet::Error, /Multiple packages available for package .* please disambiguate with a category./)
		end

		it 'explicit manifest' do
			fh = File.open("spec/unit/provider/package/eix/mysql.xml", "rb")
			mysql = fh.read
			fh.close()

			provider_class.stubs(:eix).with("--xml", "--pure-packages", "--exact", "--category-name", "dev-db/mysql").returns(mysql)

			provider = provider_class.new(pkg({ :name => "dev-db/mysql", :ensure => :latest }))

			out = provider.query
			out[:ensure].should == :absent
			out[:maxVersion].should == "5.1.62-r1"
			out[:slot].should == nil
			out[:name].should == "mysql"
			out[:category].should == "dev-db"
		end

		it 'dev builds outside default interval' do
			fh = File.open("spec/unit/provider/package/eix/transmission_9999.xml", "rb")
			transmission = fh.read
			fh.close()

			# A time older than the default interval
			time = Time.now.to_i - 10000 - provider_class.cfg(:devInterval)
			transmission["{{TIMESTAMP}}"]= "#{time}"

			provider_class.stubs(:eix).with("--xml", "--pure-packages", "--exact", "--category-name", "net-p2p/transmission").returns(transmission)

			provider = provider_class.new(pkg({ :name => "net-p2p/transmission", :ensure => "9999" }))

			out = provider.query
			out[:ensure].should == "0"
			out[:maxVersion].should == "9999"
			out[:slot].should == nil
			out[:name].should == "transmission"
			out[:category].should == "net-p2p"
		end

		it 'dev builds within default interval' do
			fh = File.open("spec/unit/provider/package/eix/transmission_9999.xml", "rb")
			transmission = fh.read
			fh.close()

			# 5 seconds newer than the default interval
			time = Time.now.to_i - provider_class.cfg(:devInterval) + 5
			transmission["{{TIMESTAMP}}"]= "#{time}"

			provider_class.stubs(:eix).with("--xml", "--pure-packages", "--exact", "--category-name", "net-p2p/transmission").returns(transmission)

			provider = provider_class.new(pkg({ :name => "net-p2p/transmission", :ensure => "9999" }))

			out = provider.query
			out[:ensure].should == "9999"
			out[:maxVersion].should == "9999"
			out[:slot].should == nil
			out[:name].should == "transmission"
			out[:category].should == "net-p2p"
		end

		it 'dev builds outside package interval' do
			fh = File.open("spec/unit/provider/package/eix/transmission_9999.xml", "rb")
			transmission = fh.read
			fh.close()

			# 1 second too old by the custom interval
			time = Time.now.to_i - 215
			transmission["{{TIMESTAMP}}"]= "#{time}"

			provider_class.stubs(:eix).with("--xml", "--pure-packages", "--exact", "--category-name", "net-p2p/transmission").returns(transmission)

			provider = provider_class.new(pkg({ :name => "net-p2p/transmission", :ensure => "9999", :interval => 214 }))

			out = provider.query
			out[:ensure].should == "0"
			out[:maxVersion].should == "9999"
			out[:slot].should == nil
			out[:name].should == "transmission"
			out[:category].should == "net-p2p"
		end

		it 'dev builds within package interval' do
			fh = File.open("spec/unit/provider/package/eix/transmission_9999.xml", "rb")
			transmission = fh.read
			fh.close()

			# 1 second too old by the custom interval
			time = Time.now.to_i - 6
			transmission["{{TIMESTAMP}}"]= "#{time}"

			provider_class.stubs(:eix).with("--xml", "--pure-packages", "--exact", "--category-name", "net-p2p/transmission").returns(transmission)

			provider = provider_class.new(pkg({ :name => "net-p2p/transmission", :ensure => "9999", :interval => 8 }))

			out = provider.query
			out[:ensure].should == "9999"
			out[:maxVersion].should == "9999"
			out[:slot].should == nil
			out[:name].should == "transmission"
			out[:category].should == "net-p2p"
		end
	end #xml parse check
end