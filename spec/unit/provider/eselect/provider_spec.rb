# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:eselect).provider(:eselect) do
  before do
    expect(Puppet).not_to receive(:warning)
  end

  def pkg(args = {})
    defaults = { provider: 'eselect' }
    Puppet::Type.type(:eselect).new(defaults.merge(args))
  end

  [:ensure].each do |param|
    it "has a #{param} function" do
      provider = described_class.new
      expect(provider).to respond_to(param)
    end
  end

  # TODO: fill this out with a proper test suite
end
