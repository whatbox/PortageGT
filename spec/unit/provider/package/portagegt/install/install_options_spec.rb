require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#install' do
    describe 'install_options' do
      before :each do
        # Stub some provider methods to avoid needing the actual software
        # installed, so we can test on whatever platform we want.
        provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

        Puppet.expects(:warning).never
      end

      [
        {
          options: { name: 'mysql', install_options: ['--oneshot'] },
          command: ['/usr/bin/emerge', '--oneshot', 'mysql']
        },
        {
          options: { name: 'dev-db/mysql', install_options: ['--oneshot'] },
          command: ['/usr/bin/emerge', '--oneshot', 'dev-db/mysql']
        },
        {
          options: { name: 'dev-db/mysql', install_options: ['--oneshot'] },
          command: ['/usr/bin/emerge', '--oneshot', 'dev-db/mysql']
        },
        {
          options: { name: 'dev-lang/php', install_options: %w[--deep --changed-use] },
          command: ['/usr/bin/emerge', '--deep', '--changed-use', 'dev-lang/php']
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
