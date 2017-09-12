# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#install' do
    # Bad
    [
      {
        options: { name: 'dev-lang/php', package_settings: 'string' },
        error: 'Parameter package_settings failed on Package[dev-lang/php]: Must be a hash'
      },
      {
        options: { name: 'app-admin/puppet', package_settings: ['list', 4] },
        error: 'Parameter package_settings failed on Package[app-admin/puppet]: Must be a hash'
      },
      {
        options: { name: 'app-admin/puppet', package_settings: 3 },
        error: 'Parameter package_settings failed on Package[app-admin/puppet]: Must be a hash'
      }
    ].each do |c|
      it c[:options].inspect + ' fails' do
        expect do
          provider_class.new(pkg(c[:options]))
        end.to raise_error(Puppet::ResourceError, c[:error])
      end
    end
  end
end
