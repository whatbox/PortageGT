#!/usr/bin/env rspec
# Encoding: utf-8

require 'yaml'
require 'spec_helper'

# TODO: rewrite this whole damn file

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  before :each do
    provider_class.stubs(:command).with(:eix).returns('/usr/bin/eix')

    Puppet.expects(:warning).never
  end

  it 'should have an #latest method' do
    provider = provider_class.new
    provider.should respond_to('latest')
  end

  describe '#latest' do
    it 'when multiple categories avaliable and a package definition is ambiguous' do
      fh = File.open('spec/unit/provider/package/eix/mysql_loose.xml', 'rb')
      mysql_loose = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--name', 'mysql').returns(mysql_loose)

      provider = provider_class.new(pkg(name: 'mysql', ensure: :latest))
      expect { provider.latest }.to raise_error(Puppet::Error, /Multiple categories .* available for package .*/)
    end

    it 'when package is specified explicitly' do
      fh = File.open('spec/unit/provider/package/eix/mysql.xml', 'rb')
      mysql = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'dev-db/mysql').returns(mysql)

      provider = provider_class.new(pkg(name: 'dev-db/mysql', ensure: :latest))
      provider.latest.should be == '5.1.62-r1'
    end

    it 'when hard and keyword are masked and only keyword is unmasked' do
      fh = File.open('spec/unit/provider/package/eix/boost_multi_mask.xml', 'rb')
      boost = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'dev-libs/boost').returns(boost)

      provider = provider_class.new(pkg(name: 'dev-libs/boost', ensure: :latest))
      provider.latest.should == '1.52.0-r6'
    end

    it 'when hard and keyword are masked and both are unmasked' do
      fh = File.open('spec/unit/provider/package/eix/boost_full_unmasked.xml', 'rb')
      boost = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'dev-libs/boost').returns(boost)

      provider = provider_class.new(pkg(name: 'dev-libs/boost', ensure: :latest))
      provider.latest.should == '1.53.0'
    end

    it 'when hard and keyword are masked and only hard is unmasked' do
      fh = File.open('spec/unit/provider/package/eix/boost_unmasked_keyworded.xml', 'rb')
      boost = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'dev-libs/boost').returns(boost)

      provider = provider_class.new(pkg(name: 'dev-libs/boost', ensure: :latest))
      provider.latest.should == '1.49.0-r2'
    end

    it 'when hard and keyword are masked and only hard is unmasked but a keyworded package is already installed' do
      fh = File.open('spec/unit/provider/package/eix/boost_unmasked_keyworded_installed.xml', 'rb')
      boost = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'dev-libs/boost').returns(boost)

      provider = provider_class.new(pkg(name: 'dev-libs/boost', ensure: :latest))
      provider.latest.should == '1.52.0-r6'
    end

    it 'when packages are masked in different ways (alien_unstable)' do
      fh = File.open('spec/unit/provider/package/eix/portage_alien_unstable.xml', 'rb')
      portage = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'sys-apps/portage').returns(portage)

      provider = provider_class.new(pkg(name: 'sys-apps/portage', ensure: :latest))
      provider.latest.should == '2.1.11.63'
    end

    it 'when packages are masked in different ways (missing_keyword)' do
      fh = File.open('spec/unit/provider/package/eix/file_missing_keyword.xml', 'rb')
      file = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'sys-apps/file').returns(file)

      provider = provider_class.new(pkg(name: 'sys-apps/file', ensure: :latest))
      provider.latest.should == '5.12-r1'
    end

    it 'when several versions are masked and some are unmasked by keywords' do
      fh = File.open('spec/unit/provider/package/eix/gnome_themes_standard.xml', 'rb')
      file = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'x11-themes/gnome-themes-standard').returns(file)

      provider = provider_class.new(pkg(name: 'x11-themes/gnome-themes-standard', ensure: :latest))
      provider.latest.should == '3.6.5'
    end

    it 'when specify a slot and the package includes a subslot' do
      fh = File.open('spec/unit/provider/package/eix/libpng_subslot.xml', 'rb')
      file = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'media-libs/libpng').returns(file)

      provider = provider_class.new(pkg(name: 'media-libs/libpng', ensure: :latest, package_settings: { slot: '0' }))
      provider.latest.should == '1.6.8'
    end

    it 'when obsolete slots are available' do
      fh = File.open('spec/unit/provider/package/eix/libpng_subslot.xml', 'rb')
      file = fh.read
      fh.close

      provider_class.stubs(:eix).with('--xml', '--pure-packages', '--exact', '--category-name', 'media-libs/libpng').returns(file)

      provider = provider_class.new(pkg(name: 'media-libs/libpng', ensure: :latest))
      provider.latest.should == '1.6.8'
    end

  end # xml parse check
end
