require 'spec_helper'

describe Puppet::Type.type(:eselect) do
  before :all do
    @class = described_class.provider(:eselect)
  end

  it 'should have :name as its keyattribute' do
    expect(described_class.key_attributes).to eq([:name])
  end

  %i[name module submodule listcmd setcmd].each do |param|
    it "should have a #{param} parameter" do
      expect(described_class.attrtype(param)).to eq(:param)
    end
  end

  [:ensure].each do |param|
    it "should have a #{param} property" do
      expect(described_class.attrtype(param)).to eq(:property)
    end
  end
end
