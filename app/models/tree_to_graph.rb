class TreeToGraph
  # Public: Creates a Turbine graph to represent the given hash structure.
  #
  # nodes - An array of nodes to be added to the graph. Each element in the
  #         array should have a unique :name key to identify the node, and an
  #         optional :children key containing an array of child nodes.
  # techs - A hash where each key matches the key of a node, and each value is
  #         an array of technologies connected to the node. Optional.
  #
  # Returns a Turbine::Graph.
  def self.convert(tree, techs = TechnologyList.new, frame = 0)
    new(tree, techs, frame).to_graph
  end

  # Internal: Converts the tree and technologies into a Turbine::Graph.
  def to_graph
    @graph ||= build_graph
  end

  private

  def initialize(tree, techs, frame = 0)
    @tree  = tree || {}
    @techs = techs
    @frame = frame
  end

  # Internal: Creates a new graph using the tree and technologies hash given to
  # the TreeToGraph.
  def build_graph
    graph = Turbine::Graph.new
    build_node(@tree, nil, graph)
    graph
  end

  # Internal: Builds a single node from the tree hash, and recurses through and
  # child nodes.
  def build_node(attrs, parent = nil, graph = Turbine::Graph.new)
    return unless valid_node?(attrs)

    attrs    = attrs.symbolize_keys
    children = attrs.delete(:children) || []
    node     = graph.add(Network::Node.new(attrs.delete(:name), attrs))

    node.set(:installed_techs, @techs[node.key])

    if node.get(:capacity) && node.get(:units)
      node.set(:capacity, node.get(:capacity) * node.get(:units))
    end

    parent.connect_to(node, :energy) if parent
    children.each { |c| build_node(c, node, graph) }
  end

  # Internal: Determines if the given node attributes are sufficient to add a
  # new node to the graph.
  def valid_node?(attrs)
    attrs.key?(:name) || attrs.key?('name'.freeze)
  end
end # TreeToGraph
