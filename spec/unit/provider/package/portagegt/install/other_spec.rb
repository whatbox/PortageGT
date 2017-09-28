# Tests from reported bugs, and combinations of features

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#install' do
    describe 'other' do
      before :each do
        # Stub some provider methods to avoid needing the actual software
        # installed, so we can test on whatever platform we want.
        provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

        Puppet.expects(:warning).never
      end

      # Good
      [
        {
          options: { name: 'dev-db/mysql', package_settings: { 'repository' => 'company-overlay' } },
          command: ['/usr/bin/emerge', 'dev-db/mysql::company-overlay']
        },
        {
          options: { name: 'sqlite', category: 'dev-db', package_settings: { 'repository' => 'testing-overlay', 'slot' => '3.8' } },
          command: ['/usr/bin/emerge', 'dev-db/sqlite:3.8::testing-overlay']
        },
        {
          options: { name: 'mysql', package_settings: { 'repository' => 'other-overlay' }, category: 'floomba', ensure: '7.0.2' },
          command: ['/usr/bin/emerge', '=floomba/mysql-7.0.2::other-overlay']
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
