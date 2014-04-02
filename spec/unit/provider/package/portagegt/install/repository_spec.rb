#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#install' do
    describe 'repository' do
      before :each do
        # Stub some provider methods to avoid needing the actual software
        # installed, so we can test on whatever platform we want.
        provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

        Puppet.expects(:warning).never
      end

      # Good
      [
        {
          options: { name: 'mysql', package_settings: { 'repository' => 'company-overlay' } },
          command: ['/usr/bin/emerge', 'mysql::company-overlay']
        },
        {
          options: { name: 'dev-lang/python', package_settings: { 'repository' => 'python-overlay' } },
          command: ['/usr/bin/emerge', 'dev-lang/python::python-overlay']
        }
      ].each do |c|
        it c[:options].inspect do
          provider = provider_class.new(pkg(c[:options]))
          provider.expects(:execute).with(c[:command])
          provider.install
        end
      end
    end
  end
end
