# frozen_string_literal: true

require 'set'
require 'spec_helper'

describe Puppet::Type.type(:package).provider(:portagegt) do
  describe 'private: _package_glob', :fakefs do
    # dev-db/mysql and virtual/mysql
    def simulate_mysql_installed; end

    # media-libs/libpng "0" & 1.2 (obsolete)
    # The IUSE was left empty here, might be worth populating
    def simulate_libpng_obsolete_multislot_installed; end

    it 'simple' do
      FileUtils.mkdir_p('/var/db/pkg/dev-vcs/git-1.9.1')

      resource = Puppet::Type.type(:package).new(name: 'dev-vcs/git', provider: 'portagegt')
      provider = described_class.new(resource)
      expect(provider.send(:_package_glob).to_set).to eq(['/var/db/pkg/dev-vcs/git-1.9.1'].to_set)
    end

    it 'multiple categories' do
      FileUtils.mkdir_p('/var/db/pkg/virtual/mysql-5.5')
      FileUtils.mkdir_p('/var/db/pkg/dev-db/mysql-5.5.32')

      resource = Puppet::Type.type(:package).new(name: 'mysql', provider: 'portagegt')
      provider = described_class.new(resource)
      expect(provider.send(:_package_glob).to_set).to eq(['/var/db/pkg/virtual/mysql-5.5', '/var/db/pkg/dev-db/mysql-5.5.32'].to_set)
    end

    it 'mulitple slots 1' do
      FileUtils.mkdir_p('/var/db/pkg/dev-lang/python-3.4.0')
      FileUtils.mkdir_p('/var/db/pkg/dev-lang/python-2.7.6')

      resource = Puppet::Type.type(:package).new(name: 'dev-lang/python', provider: 'portagegt')
      provider = described_class.new(resource)
      expect(provider.send(:_package_glob).to_set).to eq(['/var/db/pkg/dev-lang/python-2.7.6', '/var/db/pkg/dev-lang/python-3.4.0'].to_set)
    end

    it 'multiple slots 2' do
      FileUtils.mkdir_p('/var/db/pkg/media-libs/libpng-1.2.51')
      FileUtils.mkdir_p('/var/db/pkg/media-libs/libpng-1.6.9')

      resource = Puppet::Type.type(:package).new(name: 'media-libs/libpng', provider: 'portagegt')
      provider = described_class.new(resource)
      expect(provider.send(:_package_glob).to_set).to eq(['/var/db/pkg/media-libs/libpng-1.6.9', '/var/db/pkg/media-libs/libpng-1.2.51'].to_set)
    end

    it 'not installled' do
      resource = Puppet::Type.type(:package).new(name: 'www-browsers/firefox', provider: 'portagegt')
      provider = described_class.new(resource)
      expect(provider.send(:_package_glob).to_set).to eq([].to_set)
    end
  end
end
