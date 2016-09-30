Topology.EditorGraph = (function () {
    'use strict';

    function plusPath(size) {
        return 'M0,-' + size + ' V' + size +' M-' + size + ',0 H' + size;
    }

    EditorGraph.prototype = $.extend({}, Topology.Base.prototype, {
        draw: function () {
            this.data    = this.graphData.toGraph();
            this.svg     = this.buildBaseSVG();
            this.group   = this.svg.append('g');
            this.nodeIds = this.maxId();

            this.group.attr('transform', "translate(0, 40)");

            this.tree  = d3.layout.tree().nodeSize([80, 0]);

            this.update();

            this.center(this.data);
        },

        update: function () {
            var node,
                nodeEnter,
                link,
                addSize = 6,
                data    = this.graphData.toGraph(),
                nodes   = this.tree.nodes(data),
                links   = this.tree.links(nodes);

            nodes.forEach(function (d) {
                d.y = d.depth * this.lineSpace;
            }.bind(this));

            this.group.selectAll("g.node, path.link").remove();

            node = this.group.selectAll("g.node").data(nodes, function (d) {
                return d.id || (d.id = ++this.nodeIds);
            }.bind(this));

            nodeEnter = node.enter().append("g")
                .attr("class", function (d) {
                    if (d.focus) {
                        window.TopologyEditor.graphEditor.focusId = d.id;
                        return "node focus";
                    } else {
                        return "node";
                    }
                })
                .attr("transform", function (d) {
                    return "translate(" + d.x + "," + d.y + ")";
                })
                .classed('collapsed', function (d) {
                    return d._children;
                });

            // append a + button
            nodeEnter.append("path")
                .attr("class", "add-button")
                .attr('d', plusPath(addSize))
                .attr('stroke', 'green')
                .attr('stroke-width', 3)
                .attr('fill', 'none')
                .attr('transform', 'translate(25, 0)')
                .on('click', function (d) {
                    window.TopologyEditor.graphEditor
                        .addNode.call(window.TopologyEditor.graphEditor, d);
                })
                .on("mouseover", function (d) {
                    d3.select(this).style("cursor", "pointer");
                })
                .on("mouseout", function (d) {
                    d3.select(this).style("cursor", "default");
                });

            nodeEnter.append("circle")
                .attr("r", this.radius)
                .on('click', function (d) {
                    window.TopologyEditor.focusNode(d);

                    d3.selectAll('g.node').attr("class", "node");
                    d3.select(this.parentNode).attr("class", "node focus");
                })
                .on("mouseover", function (d) {
                    d3.select(this).style("cursor", "pointer");
                })
                .on("mouseout", function (d) {
                    d3.select(this).style("cursor", "default");
                });

            link = this.group.selectAll("path.link")
                .data(links, function (d) {
                    return d.target.id;
                });

            link.enter().insert("path", "g")
                .attr("class", "link")
                .attr("fill", "none")
                .attr("stroke", "#ccc")
                .attr("stroke-width", "2px")
                .attr("d", this.diagonal);

            // Load top point in form
            window.TopologyEditor.form.show(data);
        },

        zoomListener: function () {
            return d3.behavior.zoom()
                .scaleExtent([0.1, 3]).on('zoom', function () {
                    this.group.attr('transform',
                        'translate(' + d3.event.translate + ')' +
                        'scale(' + d3.event.scale + ')');
                }.bind(this));
        }
    });

    function EditorGraph(scope, graphData) {
        Topology.Base.call(this, scope);

        this.width     = 684;
        this.height    = 500;
        this.lineSpace = 80;
        this.radius    = 10;
        this.graphData = graphData;
    }

    return EditorGraph;
}());
