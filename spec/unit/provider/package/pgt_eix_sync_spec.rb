#!/usr/bin/env rspec
# Encoding: utf-8

# TODO: rewrite

# require 'yaml'
# require 'spec_helper'

# provider_class = Puppet::Type.type(:package).provider(:portagegt)

# describe provider_class do
# 	def pkg(args = {})
# 		defaults = { :provider => 'portagegt' }
# 		Puppet::Type.type(:package).new(defaults.merge(args))
# 	end

# 	before :each do
# 		# Stub some provider methods to avoid needing the actual software
# 		# installed, so we can test on whatever platform we want.
# 		provider_class.stubs(:command).with(:eix).returns('/usr/bin/eix')
# 		provider_class.stubs(:command).with(:eix_update).returns('/usr/bin/eix-update')
# 		provider_class.stubs(:command).with(:eix_sync).returns('/usr/bin/eix-sync')

# 		Puppet.expects(:warning).never
# 	end

# 	it 'prefetch' do
# 		# puts YAML::dump(provider_class)
# 		if !provider_class.EIX_RUN_UPDATE && provider_class.EIX_RUN_SYNC
# 			proc {
# 				provider_class.run_eix
# 			}.should raise_error(Puppet::Error, /EIX_RUN_UPDATE must be true if EIX_RUN_SYNC is true/)
# 		elsif provider_class::EIX_RUN_SYNC
# 			provider_class.expects(:eix_sync)
# 			provider_class.run_eix
# 		else
# 			provider_class.expects(:eix_update)
# 			provider_class.run_eix
# 		end
# 	end
# end