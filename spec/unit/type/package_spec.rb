#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

describe Puppet::Type.type(:package) do
  before :all do
    @class = described_class.provider(:portagegt)
  end

  it 'should have :name as its keyattribute' do
    described_class.key_attributes.should == [:name]
  end

  [:name, :provider, :use, :keywords, :category, :slot].each do |param|
    it "should have a #{param} parameter" do
      described_class.attrtype(param).should == :param
    end
  end

  [:ensure].each do |param|
    it "should have a #{param} property" do
      described_class.attrtype(param).should == :property
    end
  end

  context 'name' do
    before :each do
      @class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

      Puppet.expects(:warning).never
    end

    it 'should behave properly' do
      expect { @class.new(name: 'foo', ensure: :present) }.not_to raise_error
    end

    it 'should allow categories' do
      expect { @class.new(name: 'foo/bar', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo-blah/bar-baz', ensure: :present) }.not_to raise_error
    end
  end

  context 'slot' do
    # it 'should allow category'
    #   expect { @class.new(name: 'bar', category: 'foo', ensure: :present) }.not_to raise_error
    #   expect { @class.new(name: 'bar-foo', category: 'foo-test', ensure: :present) }.not_to raise_error
    # end

    it 'should allow slots' do
      expect { @class.new(name: 'bar:12', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'bar:1.2', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'bar', slot: '2', ensure: :present) }.not_to raise_error
    end

    it 'should allow word slots' do
      expect { @class.new(name: 'bar', slot: 'ruby19', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'bar:ruby19', ensure: :present) }.not_to raise_error
    end

    it 'should allow numeric slots' do
      expect { @class.new(name: 'bar', slot: 2, ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'bar', slot: 2.2, ensure: :present) }.not_to raise_error
    end

    it 'should allow any combination of name, category & slot' do
      expect { @class.new(name: 'foo/bar:12', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'bar:1.2', category: 'foo', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'bar', slot: '2', category: 'foo', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo/bar', slot: '2', ensure: :present) }.not_to raise_error
    end

    it 'should forbid whitespace' do
      expect { described_class.new(name: 'foo bar', ensure: :present) }.to raise_error(Puppet::Error, /name may not contain whitespace/)
    end

    it 'should enfore sensible categories' do
      expect { described_class.new(name: 'foo/', ensure: :present) }.to raise_error(Puppet::Error, /name may not end with category boundary/)
      expect { described_class.new(name: '/foo', ensure: :present) }.to raise_error(Puppet::Error, /name may not start with category boundary/)
      expect { described_class.new(name: 'bar//foo', ensure: :present) }.to raise_error(Puppet::Error, /name may not contain multiple category boundaries/)
      expect { described_class.new(name: 'bar/blah/foo', ensure: :present) }.to raise_error(Puppet::Error, /name may not contain multiple category boundaries/)
    end

    it 'should enfore sensible slots' do
      expect { described_class.new(name: 'foo:', ensure: :present) }.to raise_error(Puppet::Error, /name may not end with slot boundary/)
      expect { described_class.new(name: ':foo', ensure: :present) }.to raise_error(Puppet::Error, /name may not start with slot boundary/)
      expect { described_class.new(name: 'bar::2', ensure: :present) }.to raise_error(Puppet::Error, /name may not contain repository/)
      expect { described_class.new(name: 'bar:blah:foo', ensure: :present) }.to raise_error(Puppet::Error, /name may not contain multiple slot boundaries/)
    end

    it 'should disalow repositories' do
      expect { described_class.new(name: 'foo::overlay', ensure: :present) }.to raise_error
    end
  end

  describe 'keywords' do
    it 'should behave properly' do
      expect { @class.new(name: 'foo', keywords: '**', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo', keywords: '~amd64', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo', keywords: 'x86', ensure: :present) }.not_to raise_error
    end

    it 'should allow multiple values' do
      expect { @class.new(name: 'foo', keywords: '~amd64 ~arm', ensure: :present) }.not_to raise_error
    end

    it 'should allow array values' do
      expect { @class.new(name: 'foo', keywords: ['*', '-blah'], ensure: :present) }.not_to raise_error
    end
  end

  describe 'use' do
    it 'should behave properly' do
      expect { @class.new(name: 'foo', use: 'foo', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo', use: '-bar', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo', use: '*', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo', use: '-*', ensure: :present) }.not_to raise_error
    end

    it 'should allow multiple values' do
      expect { @class.new(name: 'foo', use: '* -blah', ensure: :present) }.not_to raise_error
    end

    it 'should allow array values' do
      expect { @class.new(name: 'foo', use: ['*', '-blah'], ensure: :present) }.not_to raise_error
    end
  end

  describe 'ensure' do
    it 'should be optional' do
      expect { @class.new(name: 'foo') }.not_to raise_error
    end

    it 'should allow present' do
      expect { @class.new(name: 'foo', ensure: :present) }.not_to raise_error
      expect { @class.new(name: 'foo', ensure: :installed) }.not_to raise_error
    end

    it 'should allow absent' do
      expect { @class.new(name: 'foo', ensure: :absent) }.not_to raise_error
    end

    it 'should allow latest' do
      expect { @class.new(name: 'foo', ensure: :latest) }.not_to raise_error
    end

    it 'should allow a version string' do
      expect { @class.new(name: 'foo', ensure: '1.2.4') }.not_to raise_error
      expect { @class.new(name: 'foo', ensure: '1.2.4-r2') }.not_to raise_error
    end
  end
end
