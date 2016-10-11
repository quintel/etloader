require 'rails_helper'

RSpec.describe TechnologyList do
  let(:hash) { YAML.load(<<-YML.strip_heredoc) }
    ---
    lv1:
    - type: one
      capacity: 1.2
      profile_key: 'profile_1'
    - type: two
      capacity: -0.3
      profile_key: 'profile_1'
    lv2:
    - type: three
      capacity: 3.2
      profile_key: 'profile_1'
    - type: four
      capacity: 0.1
      profile_key: 'profile_1'
      components:
      - type: Five
        capacity: 0.5
      - type: Six
        capacity: 0.5
  YML

  let!(:mock_presentables){
    stub_const("InstalledTechnology::PRESENTABLES", %i(type capacity profile_key))
  }

  describe '#to_csv' do
    let(:csv)    { TechnologyList.load(JSON.dump(hash)).to_csv }
    let(:parsed) { CSV.parse(csv, headers: true) }

    it 'includes headers' do
      expect(csv.lines.first).to include('connection')
    end

    it 'includes technologies' do
      expect(parsed.detect { |row| row['type'] == 'one' }).to be
      expect(parsed.detect { |row| row['type'] == 'two' }).to be
      expect(parsed.detect { |row| row['type'] == 'three' }).to be
      expect(parsed.detect { |row| row['type'] == 'four' }).to be
    end

    it 'includes technology attributes' do
      tech = parsed.detect { |row| row['type'] == 'two' }

      expect(tech['connection']).to eq('lv1')
      expect(tech['capacity']).to eq('-0.3')
    end
  end # to_csv

  describe '.from_csv with 2x2 connections' do
    let(:csv)  { TechnologyList.load(JSON.dump(hash)).to_csv }
    let(:list) { TechnologyList.from_csv(csv) }
    let!(:load_profile) { FactoryGirl.create(:load_profile, key: 'profile_1') }

    it 'returns a TechnologyList' do
      expect(list).to be_a(TechnologyList)
    end

    it 'adds each connection' do
      expect(list.keys).to eq(%w( lv1 lv2 ))
    end

    it 'adds technologies to the first connection' do
      expect(list['lv1'].length).to eq(2)

      expect(list['lv1'][0].capacity).to eq(1.2)

      expect(list['lv1'][1].capacity).to eq(-0.3)
      expect(list['lv1'][1].profile_key).to eq('profile_1')
      expect(list['lv1'][1].profile).to eq(load_profile.id)
    end

    it 'adds technologies to the second connection' do
      expect(list['lv2'].length).to eq(2)

      expect(list['lv2'][0].capacity).to eq(3.2)
      expect(list['lv2'][1].capacity).to eq(0.1)
    end
  end # .from_csv

  describe '.load' do
    it 'returns an empty list when given nil' do
      list = TechnologyList.load(nil)

      expect(list).to be_a(TechnologyList)
      expect(list).to be_empty
    end

    it 'returns a TechnologyList with the parsed techs' do
      list = TechnologyList.load(JSON.dump(hash))

      expect(list).to be_a(TechnologyList)

      expect(list['lv1']).to be_a(Array)
      expect(list['lv2']).to be_a(Array)

      expect(list['lv1'].length).to eq(2)
      expect(list['lv2'].length).to eq(2)
    end
  end # .load

  describe '.from_hash' do
    let(:list) { TechnologyList.from_hash(hash) }

    it 'includes the defined nodes' do
      expect(list['lv1']).to be_a(Array)
      expect(list['lv2']).to be_a(Array)
    end

    it 'includes the defined technologies' do
      expect(list['lv1'][0].type).to eq('one')
      expect(list['lv1'][1].type).to eq('two')

      expect(list['lv2'][0].type).to eq('three')
      expect(list['lv2'][1].type).to eq('four')
    end
  end # .from_hash

  describe '.dump' do
    let(:dump) { TechnologyList.dump(TechnologyList.from_hash(hash)) }

    it 'returns a string' do
      expect(dump).to be_a(String)
    end

    it 'is a JSON document when there are some techs' do
      expect(dump).to start_with('{')
      expect(dump).to end_with('}')

      expect(dump.length > 2).to be
    end

    it 'is an empty JSON string when there are no techs' do
      expect(TechnologyList.dump(TechnologyList.new)).to eq('{}')
    end
  end # .dump
end # TechnologyList
