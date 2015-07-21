FactoryGirl.define do
  factory :topology do
    name "Topology"
    graph { YAML.load(<<-YML.strip_heredoc) }
      ---
      name: :hv
      children:
      - name: :mv
        children:
        - name: :lv1
        - name: :lv2
    YML
  end

  factory :large_topology, class: Topology do
    name "Large Topology"
    graph { YAML.load(<<-YML.strip_heredoc) }
      ---
      name: :hv
      children:
      - name: :mv
        children:
        - name: :lv1
        - name: :lv2
        - name: :lv3
        - name: :lv4
    YML
  end

  factory :topology_with_stakeholders, class: Topology do
    name "Topology stakeholders"
    graph { YAML.load(<<-YML.strip_heredoc) }
      ---
      name: :hv
      children:
      - name: :mv
        children:
        - name: :lv1
          stakeholder: customer
        - name: :lv2
          stakeholder: system operator
    YML
  end
end
