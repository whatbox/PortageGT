#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class, fakefs: true do
  before :each do
    Puppet.expects(:warning).never
    FileUtils.mkdir_p('/etc/portage/package.use')
  end

  it 'should have a .set_portage method' do
    expect(provider_class).to respond_to('set_portage')
  end

  describe '.set_portage' do
    def package_stub_mysql
      provider = stub 'provider'
      provider.stubs(:package_name).returns('mysql')
      provider.stubs(:package_category).returns('dev-db')
      provider.stubs(:package_slot).returns(nil)
      provider.stubs(:package_use).returns(%w(bar baz foo))
      provider.stubs(:package_keywords).returns('~amd64')

      # Don't need to do much, here, as we're overriding the method abstractions above
      resource = stub 'resource'
      resource.stubs(:provider).returns(provider)

      { 'dev-db/mysql' => resource }
    end

    def validate_structure_mysql
      Dir.chdir('/etc/portage/package.use') do
        expect(Dir.glob('*')).to eq(%w(dev-db))
        expect(Dir.glob('dev-db/*')).to eq(%w(dev-db/mysql))
        expect(File.read('dev-db/mysql')).to eq("dev-db/mysql bar baz foo\n")
      end
    end

    def validate_empty_structure
      Dir.chdir('/etc/portage/package.use') do
        expect(Dir.glob('*')).to eq([])
      end
    end
    context 'when package.use should be empty, and is empty' do
      it 'should behave properly' do
        provider_class.set_portage({}, '/etc/portage/package.use', 'package_use')

        validate_empty_structure
      end
    end

    context 'when package.use should have files, and is empty' do
      it 'should behave properly' do
        provider_class.set_portage(package_stub_mysql, '/etc/portage/package.use', 'package_use')

        validate_structure_mysql
      end
    end

    context 'when package.use has files, and should be empty' do
      it 'should behave properly' do
        FileUtils.mkdir_p('/etc/portage/package.use/dev-db')
        File.open('/etc/portage/package.use/dev-db/mysql', 'w') do |fh|
          fh.write("dev-db/mysql bar baz foo\n")
        end

        provider_class.set_portage({}, '/etc/portage/package.use', 'package_use')

        validate_empty_structure
      end
    end

    context 'when package.use has files and no changes are needed' do
      it 'should behave properly' do
        FileUtils.mkdir_p('/etc/portage/package.use/dev-db')
        File.open('/etc/portage/package.use/dev-db/mysql', 'w') do |fh|
          fh.write("dev-db/mysql bar baz foo\n")
        end

        provider_class.set_portage(package_stub_mysql, '/etc/portage/package.use', 'package_use')

        validate_structure_mysql
      end
    end

    context 'when package.use has correct files but incorrect contents' do
      it 'should behave properly' do
        FileUtils.mkdir_p('/etc/portage/package.use/dev-db')
        File.open('/etc/portage/package.use/dev-db/mysql', 'w') do |fh|
          fh.write("dev-db/mysql bar\n")
        end

        provider_class.set_portage(package_stub_mysql, '/etc/portage/package.use', 'package_use')

        validate_structure_mysql
      end
    end

    context 'when package.use has category folders but should be empty' do
      it 'should behave properly' do
        FileUtils.mkdir_p('/etc/portage/package.use/fooblah')
        FileUtils.mkdir_p('/etc/portage/package.use/random')

        provider_class.set_portage({}, '/etc/portage/package.use', 'package_use')

        validate_empty_structure
      end
    end

    context 'when package.use has files (in the wrong place) but should be empty' do
      it 'should behave properly' do
        File.open('/etc/portage/package.use/somefile', 'w') do |fh|
          fh.write("irrelevant contents\n")
        end

        provider_class.set_portage({}, '/etc/portage/package.use', 'package_use')

        validate_empty_structure
      end
    end

    context 'when package.use has files but should be empty' do
      it 'should behave properly' do
        FileUtils.mkdir_p('/etc/portage/package.use/foo')
        File.open('/etc/portage/package.use/foo/bar', 'w') do |fh|
          fh.write("irrelevant contents\n")
        end

        provider_class.set_portage({}, '/etc/portage/package.use', 'package_use')

        validate_empty_structure
      end
    end

    context 'when package.use has a mix of correct and incorrect files' do
      it 'should behave properly' do
        FileUtils.mkdir_p('/etc/portage/package.use/dev-db')
        File.open('/etc/portage/package.use/dev-db/mysql', 'w') do |fh|
          fh.write("dev-db/mysql bar baz foo\n")
        end

        FileUtils.mkdir_p('/etc/portage/package.use/foo')
        File.open('/etc/portage/package.use/foo/bar', 'w') do |fh|
          fh.write("irrelevant contents\n")
        end

        provider_class.set_portage(package_stub_mysql, '/etc/portage/package.use', 'package_use')

        validate_structure_mysql
      end
    end

    context 'when separate slots have different options' do
      it 'should behave properly' do
        provider53 = stub 'provider'
        provider53.stubs(:package_name).returns('php')
        provider53.stubs(:package_category).returns('dev-lang')
        provider53.stubs(:package_slot).returns('5.3')
        provider53.stubs(:package_use).returns(%w(something -without))

        resource53 = stub 'resource'
        resource53.stubs(:provider).returns(provider53)

        provider54 = stub 'provider'
        provider54.stubs(:package_name).returns('php')
        provider54.stubs(:package_category).returns('dev-lang')
        provider54.stubs(:package_slot).returns('5.4')
        provider54.stubs(:package_use).returns(%w(-bar -seven))

        resource54 = stub 'resource'
        resource54.stubs(:provider).returns(provider54)

        resources = {
          'dev-lang/php:5.3' => resource53,
          'dev-lang/php:5.4' => resource54
        }

        provider_class.set_portage(resources, '/etc/portage/package.use', 'package_use')

        Dir.chdir('/etc/portage/package.use') do
          expect(Dir.glob('*')).to eq(%w(dev-lang))
          expect(Dir.glob('dev-lang/*')).to eq(%w(dev-lang/php:5.3 dev-lang/php:5.4))
          expect(File.read('dev-lang/php:5.3')).to eq("dev-lang/php:5.3 -without something\n")
          expect(File.read('dev-lang/php:5.4')).to eq("dev-lang/php:5.4 -bar -seven\n")
        end
      end
    end

    context 'when attempting to use it without a category' do
      it 'should behave properly' do
        provider = stub 'provider'
        provider.stubs(:package_name).returns('mysql')
        provider.stubs(:package_category).returns(nil)
        provider.stubs(:package_use).returns(%w(someflag))

        resource = stub 'resource'
        resource.stubs(:provider).returns(provider)

        resources = {
          'mysql' => resource
        }

        Puppet.expects(:warning).with('Cannot apply package_use for Package[mysql] without a category').once

        provider_class.set_portage(resources, '/etc/portage/package.use', 'package_use')

        validate_empty_structure
      end
    end

    context 'when attempting to use it without a category, and other files still need creation' do
      it 'should behave properly' do
        provider53 = stub 'provider'
        provider53.stubs(:package_name).returns('php')
        provider53.stubs(:package_category).returns('dev-lang')
        provider53.stubs(:package_slot).returns('5.3')
        provider53.stubs(:package_use).returns(%w(something -without))

        resource53 = stub 'resource'
        resource53.stubs(:provider).returns(provider53)

        provider = stub 'provider'
        provider.stubs(:package_name).returns('mysql')
        provider.stubs(:package_category).returns(nil)
        provider.stubs(:package_use).returns(%w(someflag))

        resource = stub 'resource'
        resource.stubs(:provider).returns(provider)

        resources = {
          'mysql' => resource,
          'dev-lang/php:5.3' => resource53
        }

        Puppet.expects(:warning).with('Cannot apply package_use for Package[mysql] without a category').once

        provider_class.set_portage(resources, '/etc/portage/package.use', 'package_use')

        Dir.chdir('/etc/portage/package.use') do
          expect(Dir.glob('*')).to eq(%w(dev-lang))
          expect(Dir.glob('dev-lang/*')).to eq(%w(dev-lang/php:5.3))
          expect(File.read('dev-lang/php:5.3')).to eq("dev-lang/php:5.3 -without something\n")
        end
      end
    end
  end
end
