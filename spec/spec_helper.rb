# Fix ruby 1.8
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require 'fakefs/spec_helpers'
RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, :fakefs => true
end

require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require_relative '../lib/puppet/provider/package/portagegt'
require_relative '../lib/puppet/type/package'

