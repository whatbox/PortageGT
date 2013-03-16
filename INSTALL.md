The easiest way to begin using PortageGT is to install it as a ["plugin in a module"](http://docs.puppetlabs.com/guides/plugins_in_modules.html).

# Installing
Copy `lib/puppet/provider/package/portagegt.rb` & `lib/puppet/type/package.rb` into the root of any of your module directories, after this, the module will contain `manifests`, `files` & `lib`. You can do this in any module, and it is only necessary to do it in one module.

# Enabling
Update the global package definition to use portagegt as the default provider for your Gentoo system.

	Package {
		provider => "portagegt"
	}
