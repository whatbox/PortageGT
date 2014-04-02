#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#install' do
    describe 'slot' do
      before :each do
        # Stub some provider methods to avoid needing the actual software
        # installed, so we can test on whatever platform we want.
        provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

        Puppet.expects(:warning).never
      end

      # Good
      [
        {
          options: { name: 'mysql:2' },
          command: ['/usr/bin/emerge', 'mysql:2']
        },
        {
          options: { name: 'mysql:2.2' },
          command: ['/usr/bin/emerge', 'mysql:2.2']
        },
        {
          options: { name: 'mysql', package_settings: { 'slot' => '2' } },
          command: ['/usr/bin/emerge', 'mysql:2']
        },
        {
          options: { name: 'mysql', package_settings: { 'slot' => '2.2' } },
          command: ['/usr/bin/emerge', 'mysql:2.2']
        },
        {
          options: { name: 'mysql', package_settings: { 'slot' => 2 } },
          command: ['/usr/bin/emerge', 'mysql:2']
        },
        {
          options: { name: 'mysql', package_settings: { 'slot' => 2.2 } },
          command: ['/usr/bin/emerge', 'mysql:2.2']
        },
        {
          options: { name: 'mysql', package_settings: { 'slot' => 'word' } },
          command: ['/usr/bin/emerge', 'mysql:word']
        },
        {
          options: { name: 'mysql:word', package_settings: { 'slot' => 'word' } },
          command: ['/usr/bin/emerge', 'mysql:word']
        },
        {
          options: { name: 'mysql:word' },
          command: ['/usr/bin/emerge', 'mysql:word']
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
          options: { name: 'dev-lang/php:5.6', package_settings: { 'slot' => 5.5 } },
          error: 'Slot disagreement on Package[dev-lang/php:5.6]'
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
