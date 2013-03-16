Using PortageGT should be pretty familiar to anyone already using puppet on Gentoo, the only differences are in the added attributes that may be included in the manifests. The simplest case is the same as it is with existing puppet setups.

	package { "vnstat":
		ensure => "1.11-r2";
	}


# Categories
## Name based

	package { "net-analyzer/vnstat":
		ensure => "1.11-r2";
	}

## Attribute based

	package { "vnstat":
		category => "net-analyzer",
		ensure => "1.11-r2";
	}

# Slots
## Name based

	package { "dev-lang/php:5.4":
		ensure => latest;
	}

	package { "dev-lang/php:5.3":
		ensure => absent;
	}

## Attribute based

	package { "dev-lang/python":
		slot   => "2.7",
		ensure => latest;
	}

	package { "dev-lang/python:3.1":
		slot   => "3.1",
		ensure => latest;
	}

# Keywords

	package { "sys-boot/grub":
		slot     => "2",
		keywords => "~amd64",
		ensure   => "2.00";
	}

# Custom Environment variables

	package { "dev-db/mongodb":
		keywords => "~amd64",
		environment => {
			"EPYTHON" => "python2.7",
		},
		ensure   => "2.2.2-r1";
	}

# Repository/Overlay
Specify the latest version of a specific overlay available on your systems, to ensure you don't accidentally build code from the wrong overlay.

	package { "www-servers/nginx":
		repository => "company-overlay",
		ensure => latest;
	}

# Use flags
## String

	package { "www-servers/apache2":
		use    => "apache2_modules_alias apache2_modules_auth_basic",
		ensure => latest;
	}

# Array

	package { "www-servers/apache2":
		use    => [
			"apache2_modules_alias",
			"-ssl",
		],
		ensure => latest;
	}

# Tuning behavior

A `CONFIG` variable found in lib/puppet/provider/package/portagegt.rb alows tuning of some basic variables. It has been pre-populated with sensible defaults for most cases, but may be customized easily.

# eselect
eselect is useful when selecting specific versions from between several slots

## PHP

	eselect { "php-fpm":
		module => "php",
		submodule => "fpm",
		ensure => "php5.4";
	}

## GCC

	eselect { "gcc":
		listcmd => "gcc-config -l",
		setcmd => "gcc-config",
		ensure => "x86_64-pc-linux-gnu-4.5.3";
	}

## Ruby

	eselect { "ruby":
		ensure => "ruby19";
	}

## Python

	eselect { "python":
		ensure => "python3.2";
	}

	eselect { "python2":
		module => "python",
		submodule => "--python2",
		ensure => "python2.7";
	}

	eselect { "python3":
		module => "python",
		submodule => "--python3",
		ensure => "python3.2";
	}

## Profile

	eselect { "profile":
		ensure => "default/linux/amd64/13.0";
	}


## kernel (/usr/src/linux)
	eselect { "kernel":
		ensure => "linux-3.7.0-hardened";
	}

## locale

	eselect { "locale":
		ensure => "en_US.UTF-8";
	}