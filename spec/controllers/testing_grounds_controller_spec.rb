require 'rails_helper'

RSpec.describe TestingGroundsController do
  let(:user){ FactoryGirl.create(:user) }

  it "visits the import path" do
    sign_in(user)

    get :import

    expect(response.status).to eq(200)
  end

  describe "#perform_import" do
    let!(:topology){ FactoryGirl.create(:topology, name: "Default topology")}
    let!(:technology){ FactoryGirl.create(:importable_technology,
                        key: "magical_technology") }

    before do
      sign_in(user)

      stub_et_engine_request
      stub_scenario_request

      expect_any_instance_of(Import).to receive(:buildings)
        .at_least(1).times.and_return([])

      post :perform_import, import: { scenario_id: 1, market_model_id: 5 }
    end

    it "renders the new template after performs an import" do
      expect(response).to render_template(:new)
    end

    it "assigns a market model id to the testing ground" do
      expect(assigns(:testing_ground).market_model_id).to eq(5)
    end
  end

  describe "#create" do
    let(:topology){ FactoryGirl.create(:topology) }
    let(:market_model) { FactoryGirl.create(:market_model) }
    let!(:sign_in_user){ sign_in(user) }
    let!(:valid_testing_ground){
      expect_any_instance_of(TestingGround).to receive(:valid?)
        .at_least(:once).and_return(true)
    }

    it "creates a testing ground" do
      post :create, TestingGroundsControllerTest.create_hash(topology.id, market_model.id)

      expect(TestingGround.count).to eq(1)
    end

    it "creates a selected strategy" do
      post :create, TestingGroundsControllerTest.create_hash(topology.id, market_model.id)

      expect(SelectedStrategy.last.testing_ground).to eq(TestingGround.last)
    end

    it "creates a business case" do
      post :create, TestingGroundsControllerTest.create_hash(topology.id, market_model.id)

      expect(BusinessCase.last.testing_ground).to eq(TestingGround.last)
    end

    it "creates a gas asset list" do
      post :create, TestingGroundsControllerTest.create_hash(topology.id, market_model.id)

      expect(GasAssetList.last.testing_ground).to eq(TestingGround.last)
    end

    it "redirects to show page" do
      post :create, TestingGroundsControllerTest.create_hash(topology.id, market_model.id)

      expect(response).to redirect_to(testing_ground_path(TestingGround.last))
    end

    it "assings the testing ground to the current user" do
      post :create, TestingGroundsControllerTest.create_hash(topology.id, market_model.id)

      expect(TestingGround.last.user).to eq(controller.current_user)
    end
  end

  describe "#update_strategies.json" do
    let(:strategies) {
      {
        "ev_capacity_constrained"=>true,
        "ev_excess_constrained"=>true,
        "ev_storage"=>true,
        "battery_storage"=>false,
        "solar_power_to_heat"=>false,
        "solar_power_to_gas"=>false,
        "hp_capacity_constrained"=>false,
        "postponing_base_load"=>false,
        "saving_base_load"=>false,
        "capping_solar_pv"=>false,
        "capping_fraction"=>1.0
      }
    }

    describe "not signed in" do
      it "does not update strategies of les" do
        testing_ground = FactoryGirl.create(:testing_ground, user: user, technology_profile: {})

        post :update_strategies, strategies: strategies, format: :json, id: testing_ground.id

        expect(SelectedStrategy.last.ev_storage).to eq(false)
      end
    end

    describe "signed in" do
      it "updates strategies of les" do
        sign_in(user)

        testing_ground = FactoryGirl.create(:testing_ground, user: user, technology_profile: {})

        post :update_strategies, strategies: strategies, format: :json, id: testing_ground.id

        expect(SelectedStrategy.last.ev_storage).to eq(true)
      end
    end
  end

  describe "#data.json" do
    describe "while signed in" do
      let!(:sign_in_user){ sign_in(user) }

      it "shows the data of a testing ground" do
        testing_ground = FactoryGirl.create(:testing_ground, technology_profile: {})

        get :data, calculation: {}, format: :json, id: testing_ground.id

        expect(response.status).to eq(200)
      end

      it "denies permission for the data of a private testing grounds" do
        testing_ground = FactoryGirl.create(:testing_ground, public: false)

        get :data, format: :json, id: testing_ground.id

        expect(response.status).to eq(403)
      end
    end

    describe "while not signed in" do
      it "shows the data of a testing ground" do
        testing_ground = FactoryGirl.create(:testing_ground, technology_profile: {})

        get :data, calculation: {}, format: :json, id: testing_ground.id

        expect(response.status).to eq(200)
      end

      it "shows the data of a testing ground" do
        testing_ground = FactoryGirl.create(:testing_ground, technology_profile: {}, public: false)

        get :data, format: :json, id: testing_ground.id

        expect(response.status).to eq(403)
      end
    end
  end

  describe "#show" do
    it "shows a testing ground" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground)

      get :show, id: testing_ground.id

      expect(response.status).to eq(200)
    end

    it "doesn't show a testing ground when it's private" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground, public: false)

      get :show, id: testing_ground.id

      expect(response).to redirect_to(root_path)
    end

    it "shows a testing ground when it's private and you're an admin" do
      user.update_attribute(:admin, true)

      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground, public: false)

      get :show, id: testing_ground.id

      expect(response.status).to eq(200)
    end

    it "shows a testing ground when it's private and yours" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                          user: user, public: false)

      get :show, id: testing_ground.id

      expect(response.status).to eq(200)
    end

    it 'shows a public testing ground' do
      testing_ground = FactoryGirl.create(:testing_ground, public: true)

      get :show, id: testing_ground.id

      expect(response.status).to eq(200)
    end

    it "doesn't show a LES with a private market model" do
      market_model = FactoryGirl.create(:market_model, public: false)
      testing_ground = FactoryGirl.create(:testing_ground, public: true, market_model: market_model)

      get :show, id: testing_ground.id

      expect(response).to redirect_to(new_user_session_path)
    end

    it "doesn't show a LES with a private topology" do
      topology = FactoryGirl.create(:topology, public: false)
      testing_ground = FactoryGirl.create(:testing_ground, public: true, topology: topology)

      get :show, id: testing_ground.id

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "#export" do
    it "visits export path" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground)

      get :export, id: testing_ground.id

      expect(response.status).to eq(200)
    end
  end

  describe "#technology_profile" do
    it "exports csv file" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                           technology_profile: {"lv1" => []})

      get :technology_profile, id: testing_ground.id, format: :csv

      expect(response.status).to eq(200)
    end
  end

  describe "#edit" do
    it "visits edit path of owned testing ground" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                           user: user,
                                           technology_profile: {"lv1" => []})

      get :edit, id: testing_ground.id

      expect(response.status).to eq(200)
    end

    it "visits edit path of another users testing ground" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                           technology_profile: {"lv1" => []})

      get :edit, id: testing_ground.id

      expect(response).to redirect_to(root_path)
    end

    it "doesn't show the edit page of a testing ground when it's private" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground, public: false)

      get :edit, id: testing_ground.id

      expect(response).to redirect_to(root_path)
    end

    it "shows the edit page of a testing ground when it's private" do
      sign_in(user)

      testing_ground = FactoryGirl.create(:testing_ground,
                                          user: user, public: false)

      get :edit, id: testing_ground.id

      expect(response.status).to eq(200)
    end
  end

  describe "#update" do
    let(:topology){
      FactoryGirl.create(:large_topology)
    }

    let(:testing_ground){
      FactoryGirl.create(:testing_ground, name: "Hello world",
                                          user: user,
                                          topology: topology,
                                          technology_profile: {"lv1" => []}) }

    let(:private_testing_ground){
      testing_ground.update_attributes(public: false, user_id: 999999)
      testing_ground
    }

    let(:profile){
      FactoryGirl.create(:load_profile, key: 'profile_1')
    }

    let(:update_hash){
      TestingGroundsControllerTest.update_hash(profile)
    }

    let!(:sign_in_user){ sign_in(user) }

    it "updates testing ground" do
      patch :update, id: testing_ground.id,
                   testing_ground: update_hash

      expect(testing_ground.reload.name).to eq("2015-08-02 - Test123")
    end

    it "doesn't update a private testing ground" do
      patch :update, id: private_testing_ground.id,
                     testing_ground: update_hash

      expect(response).to redirect_to(root_path)
    end

    it "sets the correct technology profile" do
      patch :update, id: testing_ground.id,
                     testing_ground: update_hash

      result = testing_ground.reload.technology_profile.as_json['lv1'][0]

      expect(result.slice(:profile, :profile_key)).to eq({
        :profile=>profile.id,
        :profile_key=>"profile_1",
      })
    end

    it "updates testing ground with a csv" do
      stub_et_engine_request(
        %w(households_solar_pv_solar_radiation transport_car_using_electricity base_load))

      patch :update, id: testing_ground.id,
        testing_ground: update_hash.merge({
          technology_profile_csv: fixture_file_upload("technology_profile.csv",
                                                      "text/csv")
        })

      expect(testing_ground.reload.technology_profile["lv1"][0].profile).to eq("solar_tv_zwolle")
    end
  end

  describe "#save_as" do
    let!(:admin) { FactoryGirl.create(:user, admin: true) }
    let!(:sign_in_user){ sign_in(admin) }
    let(:testing_ground){ FactoryGirl.create(:testing_ground) }

    it "counts 2 testing grounds" do
      post :save_as, format: :js, id: testing_ground.id, testing_ground: { name: "Test" }

      expect(TestingGround.count).to eq(2)
    end

    it "saves as a new name" do
      post :save_as, format: :js, id: testing_ground.id, testing_ground: { name: "New name" }

      expect(TestingGround.last.name).to eq("New name")
      expect(TestingGround.first.name).to eq("My Testing Ground")
    end

    it "changes user" do
      post :save_as, format: :js, id: testing_ground.id, testing_ground: { name: "New name" }

      expect(TestingGround.last.user).to eq(admin)
    end

    describe "selected strategies" do
      it "counts 2 selected strategies" do
        post :save_as, format: :js, id: testing_ground.id, testing_ground: { name: "Test" }

        expect(SelectedStrategy.count).to eq(2)
      end

      it "last selected strategy belongs to the last created testing ground" do
        post :save_as, format: :js, id: testing_ground.id, testing_ground: { name: "Test" }

        expect(SelectedStrategy.last.testing_ground).to eq(TestingGround.last)
      end
    end
  end

  describe "fetch etm values" do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:sign_in_user){ sign_in(user) }
    let!(:stub_et_engine) {
      stub_et_engine_request(keys = ['households_solar_pv_solar_radiation'])
    }

    let!(:fetch_values) {
      post :fetch_etm_values, scenario_id: 1,
            key: "households_solar_pv_solar_radiation", format: :json
    }

    it "fetches the correct type" do
      expect(JSON.parse(response.body)["type"]).to eq("households_solar_pv_solar_radiation")
    end

    it "fetches the correct performance coefficient" do
      expect(JSON.parse(response.body)["performance_coefficient"]).to eq(1.0)
    end
  end
end
