#!/usr/bin/env rspec
# Encoding: utf-8

# TODO: remove this, it's no longer our job to test the package type

require 'spec_helper'

describe Puppet::Type.type(:package) do
  before :all do
    @class = described_class.provider(:portagegt)
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
