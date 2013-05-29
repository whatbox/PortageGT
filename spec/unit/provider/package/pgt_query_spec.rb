#!/usr/bin/env rspec
# Encoding: utf-8

require 'yaml'
require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class, :fakefs => true do
	def pkg(args = {})
		defaults = { :provider => 'portagegt' }
		Puppet::Type.type(:package).new(defaults.merge(args))
	end

	describe '#query' do
		context 'when removing a package no longer in the portage tree' do
			it  {
				Puppet.expects(:warning).never
				FileUtils.mkdir_p('/var/db/pkg/sys-apps/slocate')
				Dir.chdir('/var/db/pkg/sys-apps/slocate') do |fh|
					File.open('repository', 'w') do |fh|
						fh.write("gentoo\n")
					end
					File.open('PF', 'w') do |fh|
						fh.write("slocate-3.1-r1\n")
					end
					File.open('SLOT', 'w') do |fh|
						fh.write("0\n")
					end
					File.open('CATEGORY', 'w') do |fh|
						fh.write("sys-apps\n")
					end
				end
				provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

				#TODO: finish this
			}
		end
	end
end