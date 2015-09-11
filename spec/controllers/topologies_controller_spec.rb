require 'rails_helper'

RSpec.describe TopologiesController do
  let(:user){ FactoryGirl.create(:user) }

  describe "creating a topology" do
    let!(:sign_in_user){ sign_in(:user, user) }
    let(:perform_post){
      post :create, "topology"=>{
        "name"=>"Hello",
        "graph"=>"---\r\nname: HV Network\r\nchildren:\r\n- name: MV Network\r\n  children:\r\n  - name: \"LV #1\"\r\n  - name: \"LV #2\"\r\n  - name: \"LV #3\"\r\n"
      }
    }

    it 'creates a topology' do
      perform_post

      expect(Topology.count).to eq(1)
    end

    it "topology belongs to the user" do
      perform_post

      expect(Topology.last.user).to eq(user)
    end
  end

  describe "creating a topology with hard tabs" do
    let!(:sign_in_user){ sign_in(:user, user) }
    let(:perform_post){
      post :create, "topology" =>{
        "name"=>"Liander testen met Hans",
        "public"=>"false",
        "graph"=>"---\r\nname: \"UHV Network\"\r\nstakeholder: system operator\r\nchildren:\r\n- name: \"HV network 150_kV\"\r\n  units: 54\r\n  stakeholder: system operator\r\n  capacity: 208000\r\n  children:\r\n  - name:  \"MS klanten van 150 kV\"\r\n\tunits: 213\r\n\tcapacity: 1000 \r\n\tstakeholder: customer\r\n  - name: \"MSR van 150_kV\"\r\n\tunits: 759\r\n\tstakeholder: system operator\r\n\tcapacity: 417\r\n\tchildren:\r\n\t- name: \"huishoudens van 150_kV\"\r\n\t  units: 61\r\n\t  stakeholder: customer\r\n    - name: \"bedrijven van 150 kV\"\r\n\t  units: 3\r\n\t  stakeholder: customer \r\n- name: \"HV network 110_kV\"\r\n  units: 14\r\n  stakeholder: system operator\r\n  capacity: 95000\r\n  children:\r\n  - name: \"MS klanten van 110 kV\"\r\n\tunits: 97\r\n\tcapacity: 1000\r\n\tstakeholder: customer \r\n  - name: \"MSR van 110_kV\"\r\n\tunits: 346\r\n\tstakeholder: system operator\r\n\tcapacity: 417\r\n\tchildren:\r\n\t- name: \"huishoudens van 110_kV\"\r\n\t  units: 61\r\n\t  stakeholder: customer\r\n    - name: \"bedrijven van 110 kV\"\r\n\t  units: 3\r\n\t  stakeholder: customer "
      }
    }

    it 'creates a topology' do
      perform_post

      expect(Topology.count).to eq(1)
    end
  end

  describe "creating a topology with stakeholders" do
    let!(:sign_in_user){ sign_in(:user, user) }
    let(:perform_post){
      post :create, "topology"=>{
        "name"=>"Hello",
        "graph"=> YAML::dump(graph)
      }
    }

    describe 'wrongly' do
      let(:graph){
        {'name' => "HV Network", 'children' => [
          { 'name' => 'MV Network', 'children' => [
            {'name' => "LV #1", 'stakeholder' => 'not_a_stakeholder'}
          ]}
        ]}
      }

      it 'does not create a topology' do
        perform_post

        expect(Topology.count).to eq(0)
      end
    end

    describe 'correctly' do
      let(:graph){
        {'name' => "HV Network", 'children' => [
          { 'name' => 'MV Network', 'children' => [
            {'name' => "LV #1", 'stakeholder' => 'customer'}
          ]}
        ]}
      }

      it "does create a topology" do
        perform_post

        expect(Topology.count).to eq(1)
      end
    end
  end

  describe "#clone somebody else's topology" do
    let!(:sign_in_user){ sign_in(:user, user) }
    let(:topology){ FactoryGirl.create(:topology, graph: YAML::dump(graph)) }
    let(:perform_clone){
      patch :clone, format: :js, id: topology.id, "topology"=>{
        "name"=>"Hello",
        "graph"=> YAML::dump(graph)
      }
    }

    let(:graph){
      {'name' => "HV Network", 'children' => [
        { 'name' => 'MV Network', 'children' => [
          {'name' => "lv1", 'stakeholder' => 'customer'},
          {'name' => "lv2", 'stakeholder' => 'customer'}
        ]}
      ]}
    }

    let!(:testing_ground){
      testing_ground = FactoryGirl.create(:testing_ground, topology: topology)

      controller.session[:testing_ground_id] = testing_ground.id
    }

    describe "with other LES's" do
      let!(:another_testing_ground){
        FactoryGirl.create(:testing_ground, topology: topology)
      }

      it 'creates a 2nd topology' do
        perform_clone

        expect(Topology.count).to eq(2)
      end

      it 'makes a cloned topology private' do
        perform_clone

        expect(Topology.last.public).to eq(false)
      end

      it "belongs to the current user" do
        perform_clone

        expect(Topology.last.user).to eq(user)
      end
    end

    describe "with no other LES's" do
      it 'does not create a 2nd topology' do
        perform_clone

        expect(Topology.count).to eq(1)
      end
    end
  end
end
