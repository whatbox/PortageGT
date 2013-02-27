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
		environment => "EPYTHON=python2.7",
		ensure   => "2.2.2-r1";
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