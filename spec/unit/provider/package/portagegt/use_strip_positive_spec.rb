# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe 'private: use_strip_positive' do
    it 'single, entry no positive flag' do
      provider = provider_class.new(pkg(name: 'mysql'))
      expect(provider.send(:use_strip_positive, ['hpn'])).to eq(['hpn'])
    end

    it 'single entry, positive flag' do
      provider = provider_class.new(pkg(name: 'mysql'))
      expect(provider.send(:use_strip_positive, ['+hpn'])).to eq(['hpn'])
    end
  end
end
