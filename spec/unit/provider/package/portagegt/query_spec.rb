#!/usr/bin/env rspec
# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#query', fakefs: true do
    before :each do
      Puppet.expects(:warning).never
    end

    # dev-vcs/git
    def simulate_git_installed
      FileUtils.mkdir_p('/var/db/pkg/dev-vcs/git-1.9.1')

      File.open('/var/db/pkg/dev-vcs/git-1.9.1/SLOT', 'w') do |fh|
        fh.write("0\n")
      end
      File.open('/var/db/pkg/dev-vcs/git-1.9.1/CATEGORY', 'w') do |fh|
        fh.write("dev-vcs\n")
      end
      File.open('/var/db/pkg/dev-vcs/git-1.9.1/PF', 'w') do |fh|
        fh.write("git-1.9.1\n")
      end
      File.open('/var/db/pkg/dev-vcs/git-1.9.1/IUSE', 'w') do |fh|
        fh.write("+blksha1 +curl cgi doc emacs gnome-keyring +gpg gtk highlight +iconv mediawiki +nls +pcre +perl +python ppcsha1 tk +threads +webdav xinetd cvs subversion test python_targets_python2_6 python_targets_python2_7 python_single_target_python2_6 python_single_target_python2_7\n")
      end
      File.open('/var/db/pkg/dev-vcs/git-1.9.1/USE', 'w') do |fh|
        fh.write("amd64 blksha1 curl elibc_glibc gnome-keyring gpg gtk iconv kernel_linux nls pcre perl python python_single_target_python2_7 python_targets_python2_7 threads userland_GNU webdav\n")
      end
      File.open('/var/db/pkg/dev-vcs/git-1.9.1/repository', 'w') do |fh|
        fh.write("gentoo\n")
      end
    end

    # dev-db/mysql and virtual/mysql
    def simulate_mysql_installed
      FileUtils.mkdir_p('/var/db/pkg/virtual/mysql-5.5')
      File.open('/var/db/pkg/virtual/mysql-5.5/SLOT', 'w') do |fh|
        fh.write("0\n")
      end
      File.open('/var/db/pkg/virtual/mysql-5.5/CATEGORY', 'w') do |fh|
        fh.write("virtual\n")
      end
      File.open('/var/db/pkg/virtual/mysql-5.5/PF', 'w') do |fh|
        fh.write("mysql-5.5\n")
      end
      File.open('/var/db/pkg/virtual/mysql-5.5/IUSE', 'w') do |fh|
        fh.write("embedded minimal static\n")
      end
      File.open('/var/db/pkg/virtual/mysql-5.5/USE', 'w') do |fh|
        fh.write("abi_x86_64 amd64 elibc_glibc kernel_linux multilib userland_GNU\n")
      end
      File.open('/var/db/pkg/virtual/mysql-5.5/repository', 'w') do |fh|
        fh.write("gentoo\n")
      end

      FileUtils.mkdir_p('/var/db/pkg/dev-db/mysql-5.5.32')
      File.open('/var/db/pkg/dev-db/mysql-5.5.32/SLOT', 'w') do |fh|
        fh.write("0\n")
      end
      File.open('/var/db/pkg/dev-db/mysql-5.5.32/CATEGORY', 'w') do |fh|
        fh.write("dev-db\n")
      end
      File.open('/var/db/pkg/dev-db/mysql-5.5.32/PF', 'w') do |fh|
        fh.write("mysql-5.5.32\n")
      end
      File.open('/var/db/pkg/dev-db/mysql-5.5.32/IUSE', 'w') do |fh|
        fh.write("debug embedded minimal +perl selinux ssl static test latin1 extraengine cluster max-idx-128 +community profiling jemalloc tcmalloc systemtap\n")
      end
      File.open('/var/db/pkg/dev-db/mysql-5.5.32/USE', 'w') do |fh|
        fh.write("abi_x86_64 amd64 community elibc_glibc kernel_linux multilib perl ssl userland_GNU\n")
      end
      File.open('/var/db/pkg/dev-db/mysql-5.5.32/repository', 'w') do |fh|
        fh.write("gentoo\n")
      end
    end

    # dev-lang/python 2.7 & 3.4
    def simulate_python_installed
      FileUtils.mkdir_p('/var/db/pkg/dev-lang/python-3.4.0')
      File.open('/var/db/pkg/dev-lang/python-3.4.0/SLOT', 'w') do |fh|
        fh.write("3.4\n")
      end
      File.open('/var/db/pkg/dev-lang/python-3.4.0/CATEGORY', 'w') do |fh|
        fh.write("dev-lang\n")
      end
      File.open('/var/db/pkg/dev-lang/python-3.4.0/PF', 'w') do |fh|
        fh.write("python-3.4.0\n")
      end
      File.open('/var/db/pkg/dev-lang/python-3.4.0/IUSE', 'w') do |fh|
        fh.write("build elibc_uclibc examples gdbm hardened ipv6 +ncurses +readline sqlite +ssl +threads tk wininst +xml\n")
      end
      File.open('/var/db/pkg/dev-lang/python-3.4.0/USE', 'w') do |fh|
        fh.write("abi_x86_64 amd64 elibc_glibc gdbm ipv6 kernel_linux ncurses readline sqlite ssl threads userland_GNU xml\n")
      end
      File.open('/var/db/pkg/dev-lang/python-3.4.0/repository', 'w') do |fh|
        fh.write("gentoo\n")
      end

      FileUtils.mkdir_p('/var/db/pkg/dev-lang/python-2.7.6')
      File.open('/var/db/pkg/dev-lang/python-2.7.6/SLOT', 'w') do |fh|
        fh.write("2.7\n")
      end
      File.open('/var/db/pkg/dev-lang/python-2.7.6/CATEGORY', 'w') do |fh|
        fh.write("dev-lang\n")
      end
      File.open('/var/db/pkg/dev-lang/python-2.7.6/PF', 'w') do |fh|
        fh.write("python-2.7.6\n")
      end
      File.open('/var/db/pkg/dev-lang/python-2.7.6/IUSE', 'w') do |fh|
        fh.write("-berkdb build doc elibc_uclibc examples gdbm hardened ipv6 +ncurses +readline sqlite +ssl +threads tk +wide-unicode wininst +xml\n")
      end
      File.open('/var/db/pkg/dev-lang/python-2.7.6/USE', 'w') do |fh|
        fh.write("abi_x86_64 amd64 elibc_glibc gdbm ipv6 kernel_linux multilib ncurses readline sqlite ssl threads userland_GNU wide-unicode xml\n")
      end
      File.open('/var/db/pkg/dev-lang/python-2.7.6/repository', 'w') do |fh|
        fh.write("gentoo\n")
      end
    end

    # media-libs/libpng "0" & 1.2 (obsolete)
    # The IUSE was left empty here, might be worth populating
    def simulate_libpng_obsolete_multislot_installed
      FileUtils.mkdir_p('/var/db/pkg/media-libs/libpng-1.6.9')
      File.open('/var/db/pkg/media-libs/libpng-1.6.9/SLOT', 'w') do |fh|
        fh.write("0/16\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.6.9/CATEGORY', 'w') do |fh|
        fh.write("media-libs\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.6.9/PF', 'w') do |fh|
        fh.write("libpng-1.6.9\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.6.9/IUSE', 'w') do |fh|
        fh.write("apng neon static-libs abi_x86_32 abi_x86_64 abi_x86_x32 abi_mips_n32 abi_mips_n64 abi_mips_o32\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.6.9/USE', 'w') do |fh|
        fh.write("abi_x86_64 amd64 apng elibc_glibc kernel_linux userland_GNU\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.6.9/repository', 'w') do |fh|
        fh.write("gentoo\n")
      end

      FileUtils.mkdir_p('/var/db/pkg/media-libs/libpng-1.2.51')
      File.open('/var/db/pkg/media-libs/libpng-1.2.51/SLOT', 'w') do |fh|
        fh.write("1.2\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.2.51/CATEGORY', 'w') do |fh|
        fh.write("media-libs\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.2.51/PF', 'w') do |fh|
        fh.write("libpng-1.2.51\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.2.51/PF', 'w') do |fh|
        fh.write("libpng-1.2.51\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.2.51/IUSE', 'w') do |fh|
        fh.write("abi_x86_32 abi_x86_64 abi_x86_x32 abi_mips_n32 abi_mips_n64 abi_mips_o32\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.2.51/USE', 'w') do |fh|
        fh.write("abi_x86_64 amd64 elibc_glibc kernel_linux userland_GNU\n")
      end
      File.open('/var/db/pkg/media-libs/libpng-1.2.51/repository', 'w') do |fh|
        fh.write("gentoo\n")
      end
    end

    it 'simple' do
      simulate_git_installed

      provider = provider_class.new(pkg(name: 'dev-vcs/git'))
      expect(provider.query[:ensure]).to eq('1.9.1')
    end

    it 'disambugated category' do
      simulate_mysql_installed

      provider = provider_class.new(pkg(name: 'mysql', category: 'dev-db'))
      provider.query
    end

    it 'ambiguous category fails' do
      simulate_mysql_installed

      expect do
        provider = provider_class.new(pkg(name: 'mysql'))
        provider.query
      end.to raise_error(Puppet::Error, 'Package[mysql] is ambiguous, specify a category: dev-db, virtual')
    end

    it 'disambugated slot' do
      simulate_python_installed

      provider = provider_class.new(pkg(name: 'dev-lang/python', package_settings: { 'slot' => '3.4' }))
      provider.query
    end

    it 'ambiguous slot fails' do
      simulate_python_installed

      expect do
        provider = provider_class.new(pkg(name: 'dev-lang/python'))
        provider.query
      end.to raise_error(Puppet::Error, 'Package[dev-lang/python] is ambiguous, specify a slot: 2.7, 3.4')
    end

    it 'disambugated slot' do
      simulate_libpng_obsolete_multislot_installed

      provider = provider_class.new(pkg(name: 'media-libs/libpng', package_settings: { 'slot' => '0' }))
      provider.query
    end

    # This should fail only because the obsolete version is installed
    # the latest_spec should use the default slot in these cases
    it 'ambiguous slot fails' do
      simulate_libpng_obsolete_multislot_installed

      expect do
        provider = provider_class.new(pkg(name: 'media-libs/libpng'))
        provider.query
      end.to raise_error(Puppet::Error, 'Package[media-libs/libpng] is ambiguous, specify a slot: 1.2, 0')
    end

    it 'not installled' do
      provider = provider_class.new(pkg(name: 'www-browsers/firefox'))
      expect(provider.query).to be_nil
    end
  end
end
