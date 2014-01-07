# Encoding: utf-8

require 'fakefs/spec_helpers'
RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end

require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

require 'puppet/type/package'
require 'puppet/provider/package/portagegt'
