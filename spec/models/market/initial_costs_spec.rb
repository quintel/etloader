require 'rails_helper'

RSpec.describe Market::InitialCosts do
  let(:network){ Network::Builders::Electricity.build(tree) }
  let(:gas_asset_list){ FactoryGirl.create(:gas_asset_list) }

  describe "calculates the initial costs" do
    let(:tree){
      {
        "name"               => "A node",
        "stakeholder"        => "system operator",
        "technical_lifetime" => 1,
        "investment_cost"    => 50
      }
    }

    it "calculates" do
      expect(Market::InitialCosts.new(network, gas_asset_list).calculate).to eq({
        "system operator" => 50.0
      })
    end
  end

  describe "it takes units into account" do
    let(:tree){
      {
        "name"               => "A node",
        "stakeholder"        => "system operator",
        "technical_lifetime" => 1,
        "investment_cost"    => 50,
        "units"              => 2
      }
    }

    it "calculates" do
      expect(Market::InitialCosts.new(network, gas_asset_list).calculate).to eq({
        "system operator" => 100.0
      })
    end
  end
end
