#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  def pkg(args = {})
    defaults = { provider: 'portagegt' }
    Puppet::Type.type(:package).new(defaults.merge(args))
  end

  before :each do
    # Stub some provider methods to avoid needing the actual software
    # installed, so we can test on whatever platform we want.
    provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

    Puppet.expects(:warning).never
  end

  it 'should have an #install method' do
    provider = provider_class.new
    provider.should respond_to('install')
  end

  describe '#install' do
    Case = Struct.new(:hash, :expected)
    success = [
      Case.new(
        { name: 'mysql' },
        'mysql'
      ),
      Case.new(
        { name: 'mysql:2' },
        'mysql:2'
      ),
      Case.new(
        { name: 'mysql', slot: '2' },
        'mysql:2'
      ),
      Case.new(
        { name: 'mysql', slot: 2 },
        'mysql:2'
      ),
      Case.new(
        { name: 'mysql', slot: 2.2 },
        'mysql:2.2'
      ),
      Case.new(
        { name: 'mysql:2', slot: 2 },
        'mysql:2'
      ),
      Case.new(
        { name: 'mysql:2.2', slot: 2.2 },
        'mysql:2.2'
      ),
      Case.new(
        { name: 'mysql', slot: 'word' },
        'mysql:word'
      ),
      Case.new(
        { name: 'dev-db/mysql' },
        'dev-db/mysql'
      ),
      Case.new(
        { name: 'mysql', category: 'floomba' },
        'floomba/mysql'
      ),
      Case.new(
        { name: 'bumbling/fool', category: 'bumbling' },
        'bumbling/fool'
      ),
      Case.new(
        { name: 'dev-db/mysql', repository: 'company-overlay' },
        'dev-db/mysql::company-overlay'
      ),
      Case.new(
        { name: 'dev-db/mysql', slot: 2, repository: 'company-overlay' },
        'dev-db/mysql:2::company-overlay'
      ),
      Case.new(
        { name: 'mysql', repository: 'other-overlay', category: 'floomba', ensure: '7.0.2' },
        '=floomba/mysql-7.0.2::other-overlay'
      ),
    ]

    failure = [
      Case.new(
        { name: 'dev-db/mysql', category: 'foobar' },
        /Category disagreement on Package.*, please check the definition/
      ),
      Case.new(
        { name: 'dev-db/mysql:2', category: 'foobar' },
        /Category disagreement on Package.*, please check the definition/
      ),
      Case.new(
        { name: 'dev-db/mysql', category: 'foobar', slot: '2' },
        /Category disagreement on Package.*, please check the definition/
      ),
      Case.new(
        { name: 'dev-db/mysql:2', category: 'foobar', slot: '2' },
        /Category disagreement on Package.*, please check the definition/
      ),
      Case.new(
        { name: 'mysql:2', slot: '3' },
        /Slot disagreement on Package.*, please check the definition/
      ),
      Case.new(
        { name: 'dev-db/mysql:2', slot: '3', category: 'dev-db' },
        /Slot disagreement on Package.*, please check the definition/
      ),
      Case.new(
        { name: 'mysql:2', category: 'dev-db', slot: '3' },
        /Slot disagreement on Package.*, please check the definition/
      ),
    ]

    success.each do |c|
      context c.hash.inspect do
        it 'should behave properly' do
          provider = provider_class.new(pkg(c.hash))
          provider.expects(:emerge).with(c.expected)
          provider.install
        end
      end
    end

    failure.each do |c|
      context c.hash.inspect do
        it 'should error properly' do
          provider = provider_class.new(pkg(c.hash))
          expect { provider.install }.to raise_error(Puppet::Error, c.expected)
        end
      end
    end
  end
end
