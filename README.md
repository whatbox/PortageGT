# PortageGT
[![Build Status](https://travis-ci.org/whatbox/PortageGT.png?branch=master)](https://travis-ci.org/whatbox/PortageGT)

## Overview
PortageGT (short for "Portage using Gentoo") is a replacement Package Provider for Puppet. It was written by [Whatbox Inc.](http://whatbox.ca/) to improve server management, and released as on Open Source project under the Apache 2 license. Patches and bug reports are welcome, please see our [CLA](http://whatbox.ca/policies/contributions).

I will also warn you that this module is not completely compatible with the existing Portage Provider. Rather than making assumptions, this provider will throw errors in the event of ambiguity, preferring developer clarification over the possibility of performing an unintended action.


## Dependencies
The following packages are necessary for this module.
* `dev-lang/ruby >= 1.9.0`
* `app-admin/puppet >= 3.5.0`
* `sys-apps/portage`
* `app-portage/eix`
* `dev-ruby/xml-simple`


## Environment
The following things are assumed:
* `/etc/portage/package.use` is a directory
* `/etc/portage/package.keywords` is a directory
* Both of the above are free for modification by puppet
* __WARNING:__ Folders contained within either of these will be automatically removed by this plugin


## Usage
Using PortageGT should be pretty familiar to anyone already using puppet on Gentoo, the only differences are in the added attributes that may be included in the manifests. The simplest case is the same as it is with existing puppet setups.

	package { "vnstat":
		ensure => "1.11-r2";
	}


### Categories
#### Name based

	package { "net-analyzer/vnstat":
		ensure => "1.11-r2";
	}

### Attribute based

	package { "vnstat":
		ensure   => "1.11-r2",
		category => "net-analyzer";
	}

### Slots
#### Name based

	package { "dev-lang/php:5.4":
		ensure => latest;
	}

	package { "dev-lang/php:5.3":
		ensure => absent;
	}

#### Attribute based

	package { "dev-lang/python":
		ensure           => latest,
		package_settings => {
			slot => "2.7",
		};
	}

	package { "dev-lang/python:3.1":
		ensure           => latest,
		package_settings => {
			slot => "3.1",
		};
	}

### Keywords

	package { "sys-boot/grub":
		ensure           => "2.00",
		package_settings => {
			slot     => "2",
			keywords => "~amd64",
		};
	}

### Repository/Overlay
Specify the latest version of a specific overlay available on your systems, to ensure you don't accidentally build code from the wrong overlay.

	package { "www-servers/nginx":
		ensure => latest,
		package_settings => {
			repository => "company-overlay",
		};
	}

### Use flags
#### String

	package { "www-servers/apache2":
		ensure => latest,
		package_settings => {
			use    => "apache2_modules_alias apache2_modules_auth_basic",
		};
	}

### Array

	package { "www-servers/apache2":
		ensure           => latest,
		package_settings => {
			use => [
				"apache2_modules_alias",
				"-ssl",
			],
		};
	}

### Additional emerge options

	package { "media-libs/libpng":
		ensure          => latest;
		install_options => ["--oneshot"],
	}

### Keywords & Use flags on dependencies
If you need to keyword or add use flags to a package without wanting to manage it's version directly.

	package { "dev-libs/boost":
		package_settings => {
			use => ["icu", "threads"],
		}
	}

### eselect
eselect is useful when selecting specific versions from between several slots

#### PHP

	eselect { "php-fpm":
		ensure    => "php5.4",
		module    => "php",
		submodule => "fpm";
	}

#### GCC

	eselect { "gcc":
		listcmd => "gcc-config -l",
		setcmd  => "gcc-config",
		ensure  => "x86_64-pc-linux-gnu-4.5.3";
	}

#### Ruby

	eselect { "ruby":
		ensure => "ruby19";
	}

#### Python

	eselect { "python":
		ensure => "python3.2";
	}

	eselect { "python2":
		module    => "python",
		submodule => "--python2",
		ensure    => "python2.7";
	}

	eselect { "python3":
		module    => "python",
		submodule => "--python3",
		ensure    => "python3.2";
	}

#### Profile

	eselect { "profile":
		ensure => "default/linux/amd64/13.0";
	}


#### kernel (/usr/src/linux)
	eselect { "kernel":
		ensure => "linux-3.7.0-hardened";
	}

#### locale

	eselect { "locale":
		ensure => "en_US.UTF-8";
	}

## Tuning behavior

Some configuration opetions can be found near the start of lib/puppet/provider/package/portagegt.rb that allow tuning of the modules behavior. The defaults cause explict use flag changes to recompile packages, and eix-sync to be run if it has been more than 48 hours since the last sync.


## Testing

To install dependencies necessary for running the tests use `bundle install`, tests can be run with `bundle exec rspec`. This project attempts to adhere to the [Ruby Stile Guide](https://github.com/bbatsov/ruby-style-guide/blob/master/README.md), you can verify your changes are in adhere to this guide using `bundle exec rubocop`.

**Note:** eix *must* be installed to test successfully on Gentoo, this is not necessary when running tests from other operating systems.

## Roadmap
* Using first-class parameters ([PUP-1183](https://tickets.puppetlabs.com/browse/PUP-1183))
* More extensive unit testing
* Easier configuration of provider options


## Features Omitted
These are features we're not implementing at this time
* package mask
    * using puppet `ensure => :held`
* package unmask
