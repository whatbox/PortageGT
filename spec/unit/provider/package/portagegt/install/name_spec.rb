require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#install' do
    describe 'name' do
      before :each do
        # Stub some provider methods to avoid needing the actual software
        # installed, so we can test on whatever platform we want.
        provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

        Puppet.expects(:warning).never
      end

      # Good
      [
        {
          options: { name: 'mysql' },
          command: ['/usr/bin/emerge', 'mysql']
        },
        {
          options: { name: 'dev-perl/Crypt-Blowfish' },
          command: ['/usr/bin/emerge', 'dev-perl/Crypt-Blowfish']
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
          options: { name: '' },
          error: 'name must be specified'
        },
        {
          options: { name: ' mysql' },
          error: 'name may not contain whitespace'
        },
        {
          options: { name: 'mysql ' },
          error: 'name may not contain whitespace'
        },
        {
          options: { name: 'my sql' },
          error: 'name may not contain whitespace'
        },
        {
          options: { name: 'dev-lang/' },
          error: 'name may not end with category boundary'
        },
        {
          options: { name: '/php' },
          error: 'name may not start with category boundary'
        },
        {
          options: { name: 'dev/lang/php' },
          error: 'name may not contain multiple category boundaries'
        },
        {
          options: { name: ':lang/php' },
          error: 'name may not start with slot boundary'
        },
        {
          options: { name: 'lang/php:' },
          error: 'name may not end with slot boundary'
        },
        {
          options: { name: 'dev-lang/php::overlay' },
          error: 'name may not contain repository'
        },
        {
          options: { name: 'dev-lang/php:5.6::overlay' },
          error: 'name may not contain repository'
        },
        {
          options: { name: 'dev-lang/php:5.6:another' },
          error: 'name may not contain multiple slot boundaries'
        }
      ].each do |c|
        it c[:options].inspect + ' fails' do
          expect do
            provider = provider_class.new(pkg(c[:options]))
            provider.install
          end.to raise_error(Puppet::ResourceError, c[:error])
        end
      end
    end
  end
end
