#!/usr/bin/env rspec
# Encoding: utf-8

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
	end
end