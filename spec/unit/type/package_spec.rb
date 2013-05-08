#!/usr/bin/env rspec

require 'spec_helper'

describe Puppet::Type.type(:package) do
	before :all do
		@class = described_class.provider(:portagegt)
	end


	it "should have :name as its keyattribute" do
		described_class.key_attributes.should == [:name]
	end


	describe "when validating attributes" do
		[:name, :provider, :use, :keywords, :category, :slot].each do |param|
			it "should have a #{param} parameter" do
				described_class.attrtype(param).should == :param
			end
		end

		[:ensure].each do |param|
			it "should have a #{param} property" do
				described_class.attrtype(param).should == :property
			end
		end
	end


	describe "when validating attribute input" do
		describe "name" do
			it "it allows categories" do
				proc { @class.new(:name => "foo/bar", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "bar", :category => 'foo', :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo-blah/bar-baz", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "bar-foo", :category => 'foo-test', :ensure => :present) }.should_not raise_error
			end

			it "it allows slots" do
				proc { @class.new(:name => "bar:12", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "bar:1.2", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "bar", :slot => "2", :ensure => :present) }.should_not raise_error
			end

			it "it allows any combination of name, category & slot" do
				proc { @class.new(:name => "foo/bar:12", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "bar:1.2", :category => "foo", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "bar", :slot => "2", :category => "foo", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo/bar", :slot => "2", :ensure => :present) }.should_not raise_error
			end

			it "it forbids whitespace" do
				proc { described_class.new(:name => "foo bar", :ensure => :present) }.should raise_error(Puppet::Error, /name may not contain whitespace/)
			end

			it "it enforces sensible categories" do			
				proc { described_class.new(:name => "foo/", :ensure => :present) }.should raise_error(Puppet::Error, /name may not end with category boundary/)
				proc { described_class.new(:name => "/foo", :ensure => :present) }.should raise_error(Puppet::Error, /name may not start with category boundary/)
				proc { described_class.new(:name => "bar//foo", :ensure => :present) }.should raise_error(Puppet::Error, /name may not contain multiple category boundaries/)
				proc { described_class.new(:name => "bar/blah/foo", :ensure => :present) }.should raise_error(Puppet::Error, /name may not contain multiple category boundaries/)
			end

			it "it enforces sensible slots" do
				proc { described_class.new(:name => "foo:", :ensure => :present) }.should raise_error(Puppet::Error, /name may not end with slot boundary/)
				proc { described_class.new(:name => ":foo", :ensure => :present) }.should raise_error(Puppet::Error, /name may not start with slot boundary/)
				proc { described_class.new(:name => "bar::2", :ensure => :present) }.should raise_error(Puppet::Error, /name may not contain multiple slot boundaries/)
				proc { described_class.new(:name => "bar:blah:foo", :ensure => :present) }.should raise_error(Puppet::Error, /name may not contain multiple slot boundaries/)
			end

			it "it disallows repositories" do
				proc { described_class.new(:name => "foo::overlay", :ensure => :present) }.should raise_error
			end
		end #name

		describe "keywords" do
			it "it accepts basic values" do
				proc { @class.new(:name => "foo", :keywords => "**", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo", :keywords => "~amd64", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo", :keywords => "x86", :ensure => :present) }.should_not raise_error
			end

			it "it allows multiple values" do
				proc { @class.new(:name => "foo", :keywords => "~amd64 ~arm", :ensure => :present) }.should_not raise_error
			end
		end #keywords

		describe "use" do
			it "it accepts basic values" do
				proc { @class.new(:name => "foo", :keywords => "foo", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo", :keywords => "-bar", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo", :keywords => "*", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo", :keywords => "-*", :ensure => :present) }.should_not raise_error
			end

			it "it allows multiple values" do
				proc { @class.new(:name => "foo", :keywords => "* -blah", :ensure => :present) }.should_not raise_error
			end

			it "it allows array values" do
				proc { @class.new(:name => "foo", :keywords => ["*","-blah"], :ensure => :present) }.should_not raise_error
			end
		end #keywords

		describe "ensure" do
			it "it allows present" do
				proc { @class.new(:name => "foo", :ensure => :present) }.should_not raise_error
				proc { @class.new(:name => "foo", :ensure => :installed) }.should_not raise_error
			end

			it "it allows absent" do
				proc { @class.new(:name => "foo", :ensure => :absent) }.should_not raise_error
			end

			it "it allows latest" do
				proc { @class.new(:name => "foo", :ensure => :latest) }.should_not raise_error
			end

			it "it allows a version string" do
				proc { @class.new(:name => "foo", :ensure => "1.2.4") }.should_not raise_error
				proc { @class.new(:name => "foo", :ensure => "1.2.4-r2") }.should_not raise_error
			end
		end #ensure
	end #


end
