class HeatSourceList::SourceListFetcher
  def initialize(testing_ground)
    @testing_ground = testing_ground
  end

  # create an array with set attributes
  #
  # [ { part_type: '', units: '', etc. } ]
  def fetch
    technologies.each_with_index.map do |tech, priority|
      tech.merge(priority: priority)
    end
  end

  private

  def technologies
    (default_heat_sources + central_heat_network).sort_by do |tech|
      tech['marginal_costs'] || -1
    end
  end

  def central_heat_network
    Import::CentralHeatNetworkBuilder.build(@testing_ground.scenario_id)
  end

  def default_heat_sources
    response.each_pair.map do |key, attributes|
      Import::HeatSourceBuilder.build(key, attributes)
    end
  end

  def response
    @response ||= EtEngineConnector.new(keys: heat_source_keys)
                  .stats(@testing_ground.scenario_id)['nodes']
  end

  def heat_source_keys
    Technology.for('heat').map do |heat_source|
      Hash[heat_source.key, heat_source.importable_attributes]
    end
  end
end
