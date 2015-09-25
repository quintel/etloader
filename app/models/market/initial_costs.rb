module Market
  # Calculates the costs to stakeholders of the technologies and infrastructure
  # for which they are responsible.
  #
  # Topology nodes belonging to a stakeholder with an investment_cost and
  # technical_lifetime will incur a cost to the stakeholder. Similarly,
  # technologies on endpoints with an initial_investment and technical_lifetime
  # will be billable to the stakeholder who owns the endpoint.
  class InitialCosts
    TOPOLOGY_REQUIRED   = %i(investment_cost technical_lifetime stakeholder)
    TECHNOLOGY_REQUIRED = %i(initial_investment technical_lifetime)

    def initialize(network)
      @network = network
    end

    def calculate
      technology_costs.merge(topology_costs) do |_, tech_cost, topology_cost|
        tech_cost + topology_cost
      end
    end

    private

    def topology_costs
      group_sum(topology_nodes) do |node|
        node.get(:investment_cost).to_f / node.get(:technical_lifetime)
      end
    end

    def technology_costs
      group_sum(technology_nodes) do |node|
        node.techs.map(&:installed).sum do |tech|
          if calculable_tech?(tech)
            tech.initial_investment.to_f / tech.technical_lifetime * tech.units
          else
            0.0
          end
        end
      end
    end

    def group_sum(nodes)
      nodes.each_with_object(Hash.new(0.0)) do |node, data|
        data[node.get(:stakeholder)] += yield(node)
      end
    end

    def technology_nodes
      @network.nodes.select do |node|
        node.techs.map(&:installed).any? { |tech| calculable_tech?(tech) }
      end
    end

    def topology_nodes
      @network.nodes.select do |node|
        TOPOLOGY_REQUIRED.all? { |attr| node.get(attr) }
      end
    end

    def calculable_tech?(tech)
      TECHNOLOGY_REQUIRED.all? { |attr| tech.public_send(attr) }
    end
  end
end