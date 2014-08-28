#!/usr/bin/env rspec
# Encoding: utf-8

require 'set'
require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe 'private: _package_glob', fakefs: true do
    before :each do
      Puppet.expects(:warning).never
    end

    # dev-db/mysql and virtual/mysql
    def simulate_mysql_installed
    end

    # media-libs/libpng "0" & 1.2 (obsolete)
    # The IUSE was left empty here, might be worth populating
    def simulate_libpng_obsolete_multislot_installed
    end

    it 'simple' do
      FileUtils.mkdir_p('/var/db/pkg/dev-vcs/git-1.9.1')

      provider = provider_class.new(pkg(name: 'dev-vcs/git'))
      provider.send(:_package_glob).to_set.should == ['/var/db/pkg/dev-vcs/git-1.9.1'].to_set
    end

    it 'multiple categories' do
      FileUtils.mkdir_p('/var/db/pkg/virtual/mysql-5.5')
      FileUtils.mkdir_p('/var/db/pkg/dev-db/mysql-5.5.32')

      provider = provider_class.new(pkg(name: 'mysql'))
      provider.send(:_package_glob).to_set.should == ['/var/db/pkg/virtual/mysql-5.5', '/var/db/pkg/dev-db/mysql-5.5.32'].to_set
    end

    it 'mulitple slots 1' do
      FileUtils.mkdir_p('/var/db/pkg/dev-lang/python-3.4.0')
      FileUtils.mkdir_p('/var/db/pkg/dev-lang/python-2.7.6')

      provider = provider_class.new(pkg(name: 'dev-lang/python'))
      provider.send(:_package_glob).to_set.should == ['/var/db/pkg/dev-lang/python-2.7.6', '/var/db/pkg/dev-lang/python-3.4.0'].to_set
    end

    it 'multiple slots 2' do
      FileUtils.mkdir_p('/var/db/pkg/media-libs/libpng-1.2.51')
      FileUtils.mkdir_p('/var/db/pkg/media-libs/libpng-1.6.9')

      provider = provider_class.new(pkg(name: 'media-libs/libpng'))
      provider.send(:_package_glob).to_set.should == ['/var/db/pkg/media-libs/libpng-1.6.9', '/var/db/pkg/media-libs/libpng-1.2.51'].to_set
    end

    it 'not installled' do
      provider = provider_class.new(pkg(name: 'www-browsers/firefox'))
      provider.send(:_package_glob).to_set.should == [].to_set
    end
  end
end
