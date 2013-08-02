#!/usr/bin/env rspec
# Encoding: utf-8

# TODO: rewrite

# require 'yaml'
# require 'spec_helper'

# provider_class = Puppet::Type.type(:package).provider(:portagegt)

# describe provider_class, :fakefs => true do
# 	def pkg(args = {})
# 		defaults = { :provider => 'portagegt' }
# 		Puppet::Type.type(:package).new(defaults.merge(args))
# 	end

# 	it 'when removing a package no longer in the portage tree' do
# 		Puppet.expects(:warning).never
# 		FileUtils.mkdir_p('/var/db/pkg/sys-apps/slocate')
# 		Dir.chdir('/var/db/pkg/sys-apps/slocate') do
# 			File.open('repository', 'w') { |fh| fh.write("gentoo\n") }
# 			File.open('PF', 'w') { |fh| fh.write("slocate-3.1-r1\n") }
# 			File.open('SLOT', 'w') { |fh| fh.write("0\n") }
# 			File.open('CATEGORY', 'w') { |fh| fh.write("sys-apps\n") }
# 		end
# 		provider = provider_class.new(pkg({ :name => 'slocate' }))
# 		provider.query
# 	end
# end