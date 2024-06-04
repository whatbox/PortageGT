# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:package).provider(:portagegt) do
  describe 'private: use_strip_positive' do
    it 'single, entry no positive flag' do
      provider = described_class.new(pkg(name: 'mysql'))
      expect(provider.send(:use_strip_positive, ['hpn'])).to eq(['hpn'])
    end

    it 'single entry, positive flag' do
      provider = described_class.new(pkg(name: 'mysql'))
      expect(provider.send(:use_strip_positive, ['+hpn'])).to eq(['hpn'])
    end
  end
end
