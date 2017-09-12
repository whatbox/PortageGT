# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#install' do
    describe 'category' do
      before :each do
        # Stub some provider methods to avoid needing the actual software
        # installed, so we can test on whatever platform we want.
        provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

        Puppet.expects(:warning).never
      end

      # Good
      [
        {
          options: { name: 'dev-db/mysql' },
          command: ['/usr/bin/emerge', 'dev-db/mysql']
        },
        {
          options: { name: 'mysql', category: 'dev-db' },
          command: ['/usr/bin/emerge', 'dev-db/mysql']
        },
        {
          options: { name: 'app-admin/puppet', category: 'app-admin' },
          command: ['/usr/bin/emerge', 'app-admin/puppet']
        }
      ].each do |c|
        it c[:options].inspect do
          provider = provider_class.new(pkg(c[:options]))
          provider.expects(:execute).with(c[:command])
          provider.install
        end
      end

      # Bad
      [
        {
          options: { name: 'dev-db/mysql', category: 'app-admin' },
          error: 'Category disagreement on Package[dev-db/mysql]'
        }
      ].each do |c|
        it c[:options].inspect + ' fails' do
          expect do
            provider = provider_class.new(pkg(c[:options]))
            provider.install
          end.to raise_error(Puppet::Error, c[:error])
        end
      end
    end
  end
end
