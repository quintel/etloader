module NetworkCache
  class Writer
    include CacheHelper

    def self.from(testing_ground, opts = {})
      new(testing_ground, **opts)
    end

    #
    # Writes a load calculation to cache
    def write(networks = tree_scope)
      networks.each do |network|
        write_network(file_path, network)
      end

      networks
    end

    private

    def write_network(path, network)
      directory = path.join(network.carrier.to_s, time_frame)

      FileUtils.mkdir_p(directory) unless directory.directory?

      network.nodes.each do |node|
        File.write(
          file_name(network.carrier, node.key),
          node.get(:load).to_msgpack,
          mode: 'wb'
        )
      end
    end
  end
end
