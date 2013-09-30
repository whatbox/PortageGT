#Dependencies (Gentoo)

* `app-portage/eix` (Puppet can fail to setup correctly on a Gentoo system without it)
* `dev-ruby/bundler`
* `dev-ruby/rspec`
* `dev-ruby/fakefs`
* `app-admin/puppet`
* `dev-ruby/xml-simple`
* `https://github.com/puppetlabs/puppetlabs_spec_helper` (via rubygems)

# Dependencies (Other - via rubygems)

* `bundler`
* `rspec`
* `fakefs`
* `puppet`
* `xml-simple`
* `puppetlabs_spec_helper`

# Running Tests
From the root of the working directory: `rspec spec`