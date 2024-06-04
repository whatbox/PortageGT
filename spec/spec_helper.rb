# frozen_string_literal: true

require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end

require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

require 'puppet/type/package'
require 'puppet/provider/package/portagegt'

def pkg(args = {})
  defaults = { provider: 'portagegt' }
  Puppet::Type.type(:package).new(defaults.merge(args))
end

# Stop at first error
# RSpec.configure do |c|
#   c.fail_fast = true
# end
