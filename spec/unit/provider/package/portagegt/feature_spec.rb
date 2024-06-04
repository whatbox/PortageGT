# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:package).provider(:portagegt) do
  before do
    expect(Puppet).not_to receive(:warning)
  end

  describe 'provider features' do
    it { is_expected.to be_installable }
    it { is_expected.to be_uninstallable }
    it { is_expected.to be_upgradeable }
    it { is_expected.to be_versionable }
    it { is_expected.to be_package_settings }
  end
end
