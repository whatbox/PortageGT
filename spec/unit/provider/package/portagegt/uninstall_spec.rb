#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  before :each do
    provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

    Puppet.expects(:warning).never
  end

  it 'should have an #uninstall method' do
    provider = provider_class.new
    provider.should respond_to('uninstall')
  end

  # We have skipped testing disambiugation because that should be handled at the package
  # level, if there's an ambiguous case, it will never make it to the uninstall function

  describe '#uninstall' do
    it 'with no paremeters' do
      provider = provider_class.new(pkg(name: 'mysql'))
      provider.expects(:emerge).with('--unmerge', 'mysql')
      provider.uninstall
    end

    context 'with slot parameter' do
      it 'in the name' do
        provider = provider_class.new(pkg(name: 'mysql:2'))
        provider.expects(:emerge).with('--unmerge', 'mysql:2')
        provider.uninstall
      end

      it 'in the params' do
        provider = provider_class.new(pkg(name: 'mysql', package_settings: { 'slot' => '2' }))
        provider.expects(:emerge).with('--unmerge', 'mysql:2')
        provider.uninstall
      end

      it 'in the name & params' do
        provider = provider_class.new(pkg(name: 'mysql:2', package_settings: { 'slot' => '2' }))
        provider.expects(:emerge).with('--unmerge', 'mysql:2')
        provider.uninstall
      end

      it 'mismatched between the name & params' do
        expect do
          provider = provider_class.new(pkg(name: 'dev-db/mysql:2', package_settings: { 'slot' => '3' }))
          provider.uninstall
        end.to raise_error(Puppet::Error, 'Slot disagreement on Package[dev-db/mysql:2]')
      end
    end

    context 'with category parameter' do
      it 'in the name' do
        provider = provider_class.new(pkg(name: 'dev-db/mysql'))
        provider.expects(:emerge).with('--unmerge', 'dev-db/mysql')
        provider.uninstall
      end

      it 'in the params' do
        provider = provider_class.new(pkg(name: 'mysql', category: 'dev-db'))
        provider.expects(:emerge).with('--unmerge', 'dev-db/mysql')
        provider.uninstall
      end

      it 'in the name & params' do
        provider = provider_class.new(pkg(name: 'foobar/mysql', category: 'foobar'))
        provider.expects(:emerge).with('--unmerge', 'foobar/mysql')
        provider.uninstall
      end

      it 'mismatched between the name & params' do
        expect do
          provider = provider_class.new(pkg(name: 'dev-db/mysql', category: 'nope'))
          provider.uninstall
        end.to raise_error(Puppet::Error, 'Category disagreement on Package[dev-db/mysql]')
      end
    end

    context 'with repository parameter' do
      it 'in the params' do
        provider = provider_class.new(pkg(name: 'mysql', package_settings: { 'repository' => 'awesome-overlay' }))
        provider.expects(:emerge).with('--unmerge', 'mysql::awesome-overlay')
        provider.uninstall
      end
    end

    context 'with category & slot' do
      it 'in the name' do
        provider = provider_class.new(pkg(name: 'dev-db/mysql:2'))
        provider.expects(:emerge).with('--unmerge', 'dev-db/mysql:2')
        provider.uninstall
      end

      it 'in the params' do
        provider = provider_class.new(pkg(name: 'mysql', category: 'dev-db', package_settings: { 'slot' => '5.5' }))
        provider.expects(:emerge).with('--unmerge', 'dev-db/mysql:5.5')
        provider.uninstall
      end

      it 'in the name & params' do
        provider = provider_class.new(pkg(name: 'foo/bar:baz', category: 'foo', package_settings: { 'slot' => 'baz' }))
        provider.expects(:emerge).with('--unmerge', 'foo/bar:baz')
        provider.uninstall
      end
    end

    context 'with category & repository' do
      it 'in the params' do
        provider = provider_class.new(pkg(name: 'php', category: 'dev-lang', package_settings: { 'repository' => 'internal' }))
        provider.expects(:emerge).with('--unmerge', 'dev-lang/php::internal')
        provider.uninstall
      end
    end

    context 'with slot & repository' do
      it 'in the params' do
        provider = provider_class.new(pkg(name: 'program', package_settings: { 'slot' => 'ruby18',  'repository' => 'internal' }))
        provider.expects(:emerge).with('--unmerge', 'program:ruby18::internal')
        provider.uninstall
      end
    end

    context 'with category, slot & repository' do
      it 'in the params' do
        provider = provider_class.new(pkg(name: 'python', category: 'dev-lang', package_settings: { 'slot' => '3.3', 'repository' => 'gentoo' }))
        provider.expects(:emerge).with('--unmerge', 'dev-lang/python:3.3::gentoo')
        provider.uninstall
      end
    end
  end
end
