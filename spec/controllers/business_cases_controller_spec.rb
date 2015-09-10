require 'rails_helper'

RSpec.describe BusinessCasesController do
  let(:user){ FactoryGirl.create(:user) }
  let!(:sign_in_user){ sign_in(:user, user) }
  let(:market_model){ FactoryGirl.create(:market_model) }
  let(:testing_ground){
    FactoryGirl.create(:testing_ground, user: user, market_model: market_model)
  }
  let(:testing_ground_without_mm){
    FactoryGirl.create(:testing_ground, user: user)
  }

  describe "#create" do
    let(:create_business_case){
      post :create, testing_ground_id: testing_ground.id, format: :js
    }

    it 'creates a business case' do
      create_business_case

      expect(BusinessCase.count).to eq(1)
    end

    it "does not create an extra business case" do
      BusinessCase.create!(testing_ground: testing_ground)

      create_business_case

      expect(BusinessCase.count).to eq(1)
    end

    it "sets financials to table" do
      create_business_case

      expect(BusinessCase.last.financials).to eq(
        [ {"aggregator"=>[nil, nil, nil, nil, nil, nil, nil]},
          {"cooperation"=>[nil, nil, nil, nil, nil, nil, nil]},
          {"customer"=>[nil, nil, nil, nil, nil, nil, nil]},
          {"government"=>[nil, nil, nil, nil, nil, nil, nil]},
          {"producer"=>[nil, nil, nil, nil, nil, nil, nil]},
          {"supplier"=>[nil, nil, nil, nil, nil, nil, nil]},
          {"system operator"=>[nil, nil, nil, nil, nil, nil, nil]}
        ])
    end
  end

  describe "#update" do
    let(:business_case){
      FactoryGirl.create(:business_case, testing_ground: testing_ground)
    }

    it 'updates the current business case' do
      put :update, testing_ground_id: testing_ground.id, id: business_case.id,
                   business_case: {
                     financials: JSON.dump([{row: 'customer', tariff: 123 }])
                   },
                   format: :js

      expect(business_case.reload.financials).to eq([{
        "row" => 'customer', "tariff" => 123
      }])
    end
  end

  describe "illegal update" do
    let(:business_case){
      FactoryGirl.create(:business_case)
    }

    it 'updates the current business case' do
      put :update, testing_ground_id: testing_ground.id, id: business_case.id,
                   business_case: {
                     financials: JSON.dump([{row: 'customer', tariff: 123 }])
                   }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "#show" do
    let(:business_case){
      FactoryGirl.create(:business_case)
    }

    it 'visits show page' do
      get :show, testing_ground_id: testing_ground.id, id: business_case.id

      expect(response).to be_success
    end
  end

  describe "#compare_with" do
    let(:comparing_testing_ground){
      FactoryGirl.create(:testing_ground)
    }

    let(:business_case){
      FactoryGirl.create(:business_case, testing_ground: testing_ground)
    }

    let!(:other_business_case){
      FactoryGirl.create(:business_case, testing_ground: comparing_testing_ground)
    }

    it "visits compare path (to compare business cases) and failing" do
      get :compare_with, testing_ground_id: testing_ground.id, id: business_case.id

      expect(response.status).to eq(422)
    end

    it "visits compare path (to compare business cases)" do
      get :compare_with, testing_ground_id: testing_ground.id,
                         comparing_testing_ground_id: comparing_testing_ground.id,
                         id: business_case.id

      expect(JSON.parse(response.body)).to eq(
        [ [0, 0, 0, 0], [0, 0, 0, 0],
          [0, 0, 0, 0], [0, 0, 0, 0],
          [0, 0, 0, 0], [0, 0, 0, 0],
          [0, 0, 0, 0]]
      )
    end
  end
end
