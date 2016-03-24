module NetworkCache
  class Validator
    include CacheHelper

    def self.from(testing_ground, opts = nil)
      new(testing_ground, opts)
    end

    def valid?
      Settings.cache.networks && cache_intact? &&
        identical_strategies? && identical_range? && fresh?
    end

    private

    def cache_intact?
      tree_scope.all? do |network|
        network.nodes.all? do |node|
          File.exists?(file_name(network.carrier, node.key))
        end
      end
    end

    def identical_strategies?
      @opts[:strategies].empty? || strategy_attributes == @opts[:strategies]
    end

    def identical_range?
      @opts[:range].nil? || (@testing_ground.range == @opts[:range])
    end

    def fresh?
      [ @testing_ground,
        @testing_ground.topology ].all? do |target|
        target && Time.at(target.updated_at.to_time.to_i) <= Time.at(cache_time.to_i)
      end
    end

    def cache_time
      tree_scope.map do |network|
        network.nodes.map do |node|
          File.mtime(file_name(network.carrier, node.key))
        end.min
      end.min
    end

    def strategy_attributes
      @testing_ground.selected_strategy.attributes.except("id", "testing_ground_id")
    end
  end
end
