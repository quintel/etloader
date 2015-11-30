module TestingGroundsHelper
  def import_topology_select_tag(form)
    topologies = Topology.named.map do |topo|
      [(topo.name || "No name specified"), topo.id]
    end

    topologies.unshift(['- - -', '-', { disabled: true }])
    topologies.unshift(['Default topology', Topology.default.id])

    form.select(:topology_id, topologies, {}, class: 'form-control')
  end

  def market_model_options
    MarketModel.all.map do |market_model|
      [market_model.name, market_model.id]
    end
  end

  def link_to_etm_scenario(title, scenario_id)
    link_to_etm(title, "scenarios/#{ scenario_id }")
  end

  def link_to_etm(title, link, options = {})
    link_to(title, "http://#{Settings.etmodel_host}/#{link}", target: "_blank")
  end

  # Public: Determines if the given testing ground has enough information to
  # permit exporting back to a national scenario.
  def can_export?(testing_ground)
    testing_ground.scenario_id.present?
  end

  def profile_table_options_for_name
    technologies = @technologies.visible.order(:name).map do |technology|
      [technology.name, technology.key, data: default_values(technology).merge(
        composite: technology.composite,
        includes:  technology.technologies.map(&:key).join(","))
      ]
    end

    options_for_select(technologies)
  end

  def maximum_concurrency?(technology_key, profile)
    technology = profile.as_json.values.flatten.detect{|t| t[:type] == technology_key }

    technology ? (technology[:concurrency] == "max") : true
  end

  def options_for_stakeholders
    options = @testing_ground.topology.each_node.map do |n|
      n[:stakeholder]
    end.compact.uniq.sort

    options_for_select options.uniq
  end

  def options_for_testing_grounds(testing_ground)
    testing_grounds = policy_scope(TestingGround)
                        .where("`testing_grounds`.`id` != ?", testing_ground.id)
                        .joins(:business_case)
                        .order(:name)

    options_for_select(testing_grounds.map{|tg| [tg.name, tg.id] })
  end

  def options_for_strategies
    options_for_select(Strategies.all.map do |strategy|
      [I18n.t("testing_grounds.strategies.#{strategy[:name]}"), strategy[:ajax_prop]]
    end)
  end

  def default_strategies
    Hash[Strategies.all.map{|s| [s[:ajax_prop], false] }].symbolize_keys
  end

  def save_all_button(testing_ground)
    link_to("Save all and view LES", "#",
      data: { url: testing_ground_path(testing_ground) },
      class: "btn btn-success save-all")
  end

  def end_point_filter_options(profile)
    options_for_select(profile.keys, profile.keys)
  end

  def column_filter_options(profile)
    editables = (%w(node) + InstalledTechnology::EDITABLES[0...-1])
    selected  = %w(node name profile electrical_capacity volume demand units)

    options_for_select(editables.map(&:to_s).map{|e| [e.humanize, e] }, selected)
  end
end
