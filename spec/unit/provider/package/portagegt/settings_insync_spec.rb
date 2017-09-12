# Encoding: utf-8

require 'spec_helper'

provider_class = Puppet::Type.type(:package).provider(:portagegt)

describe provider_class do
  describe '#package_settings_insync?' do
    before :each do
      # Stub some provider methods to avoid needing the actual software
      # installed, so we can test on whatever platform we want.
      provider_class.stubs(:command).with(:emerge).returns('/usr/bin/emerge')

      Puppet.expects(:warning).never
    end

    describe 'repository' do
      it 'using overlay, and not specifying a repository' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'company-overlay',
          use_positive: [],
          use_valid: []
        }
        goal = {}
        expect(provider.package_settings_insync?(goal, have)).to be true
      end

      it 'using overlay, and specifying a repository' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'company-overlay',
          use_positive: [],
          use_valid: []
        }
        goal = {
          'repository' => 'gentoo'
        }
        expect(provider.package_settings_insync?(goal, have)).to be false
      end

      it 'using default, and specifying a repository' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'gentoo',
          use_positive: [],
          use_valid: []
        }
        goal = {
          'repository' => 'company-overlay'
        }
        expect(provider.package_settings_insync?(goal, have)).to be false
      end
    end

    describe 'use' do
      it 'positive use flag already used' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'gentoo',
          use_positive: %w[want],
          use_valid: %w[want dontwant dontcare]
        }
        goal = {
          'use' => 'want'
        }
        expect(provider.package_settings_insync?(goal, have)).to be true
      end

      it 'negative use flag already absent' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'gentoo',
          use_positive: %w[want],
          use_valid: %w[want dontwant dontcare]
        }
        goal = {
          'use' => '-dontwant'
        }
        expect(provider.package_settings_insync?(goal, have)).to be true
      end

      it 'positive and negative use flags as they should be' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'gentoo',
          use_positive: %w[want],
          use_valid: %w[want dontwant dontcare]
        }
        goal = {
          'use' => 'want -dontwant'
        }
        expect(provider.package_settings_insync?(goal, have)).to be true
      end

      it 'positive use flag missing' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'gentoo',
          use_positive: %w[],
          use_valid: %w[want dontwant dontcare]
        }
        goal = {
          'use' => 'want'
        }
        expect(provider.package_settings_insync?(goal, have)).to be false
      end

      it 'negative use flag included' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'gentoo',
          use_positive: %w[dontwant dontcare],
          use_valid: %w[want dontwant dontcare]
        }
        goal = {
          'use' => '-dontwant'
        }
        expect(provider.package_settings_insync?(goal, have)).to be false
      end

      it 'doesn\'t care about unspecified' do
        provider = provider_class.new(pkg(name: 'app-admin/puppet'))
        have = {
          ensure: '3.5.0',
          repository: 'gentoo',
          use_positive: %w[dontcare],
          use_valid: %w[want dontwant dontcare]
        }
        goal = {
          'use' => '-dontwant'
        }
        expect(provider.package_settings_insync?(goal, have)).to be true
      end
    end
  end
end
