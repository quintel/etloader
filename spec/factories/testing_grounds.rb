FactoryGirl.define do
  factory :testing_ground do
    name 'My Testing Ground'

    topology

    market_model

    selected_strategy

    scenario_id 1

    user

    cache_updated_at DateTime.now

    technology_profile { YAML.load(<<-YML.strip_heredoc) }
      ---
      lv1:
      - name: One
        capacity: 1.2
      - name: Two
        capacity: -0.3
      lv2:
      - name: Three
        capacity: 3.2
      - name: Four
        capacity: 0.1
    YML
  end
end
