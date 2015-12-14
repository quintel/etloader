var TreeGraph = (function () {
    var _self, container, dragListener, zoomListener, node, baseSvg, tree, diagonal,
        svgGroup;

    var maxLabelLength = 0,
        maxViewerHeight = 500,
        viewerHeight = 570,
        viewerWidth = 500,
        duration = 250,
        nodeSize = 50,
        ease = 'cubic-out',
        levelWidth = [1];

    TreeGraph.prototype = {
        showGraph: function(treeData) {
            if (!!treeData) this.treeData = treeData;

            if (this.initialCallDone && this.initialStrategyCallDone) {
                $("a.dropdown-toggle").first().removeClass("disabled");

                buildBase();
                transformData.call(this);

                window.localSettings = new LocalSettings($(".testing_ground_id").text());

                ETHelper.eachNode([this.root], setAltLoad.bind(this));

                this.strategyToggler.addOnChangeListener();

                // Layout the tree initially and center on the root node.
                this.update(this.root);

                // Center the diagram with an offset such that *children* of the root will
                // appear to be in the center.
                centerNode(this.root);

                setLastClickedNode.call(this);

                this.reloadLast();
            };
        },

        applyStrategies: function(data) {
            this.strategyLoads = ETHelper.loadsFromTree(data.networks.electricity);
            this.strategyGasLoads = ETHelper.loadsFromTree(data.networks.gas);
            this.strategyLoads = {};

            LoadChartHelper.forceReload = true

            if (this.root) {
                ETHelper.eachNode([this.root], setAltLoad.bind(this));
                this.update(this.root);
                this.reloadLast();
            };
        },

        reloadLast: function() {
            if (this.lastClicked) {
                this.showChart(this.lastClicked);
            };
        },

        showChart: function(d) {
            new ChartShower(this, d).reload().show();
        },

        update: function(source) {
            // Compute the new height, function counts total children of root node
            // and sets tree height accordingly. This prevents the layout looking
            // squashed when new nodes are made visible or looking sparse when nodes
            // are removed. This makes the layout more consistent.
            //
            _self = this;

            var nodeIds = 0;
            var newHeight, nodes, links, nodeEnter, nodeUpdate, nodeExit, link;

            // Fills the levelWidth area with all the nodes child counts
            childCount(0, this.root);

            // Compute the new tree layout.
            nodes = tree.nodes(this.root).reverse();
            links = tree.links(nodes);

            // Set widths between levels based on maxLabelLength.
            nodes.forEach(function(d) {
                // alternatively to keep a fixed scale one can set a fixed depth per
                // level. Normalize for fixed-depth by commenting out below line>
                // d.y = (d.depth * 175); //175px per level.
                d.y = (d.depth * (maxLabelLength * 8));
            });

            // Update the nodes…
            node = svgGroup.selectAll('g.node').data(nodes, function(d) {
                return d.id || (d.id = ++nodeIds);
            });

            node.classed('collapsed', function(d) {
                return d._children;
            });

            // Enter any new nodes at the parent's previous position.
            nodeEnter = node.enter().append('g')
                .call(dragListener)
                .attr('class', setNodeClass)
                .classed('collapsed', function(d) {
                    // We have to run the "collapsed" function again (it is already
                    // defined above), as the above version does not run the first
                    // time the update() function is called.
                    return d._children;
                })
                .attr('transform', function(d) {
                    return 'translate(' + source.x0 + ',' + source.y0 + ')';
                })
                .on('dblclick', dblClick)
                .on('click', click);

            node.classed('exceedance', overCapacity);

            nodeEnter.append('circle')
                .attr('class', 'nodeCircle')
                .attr('r', 0)

            nodeEnter.append('text')
                .attr('y', setNodeLabelY)
                .attr('dy', '.38em')
                .attr('class', 'nodeText')
                .style('fill-opacity', 0)
                .attr('text-anchor', 'middle')
                .text(function(d) {
                    return d.name;
                });

            // Update the text to reflect whether node has children or not.
            node.select('text')
                .attr('y', setNodeLabelY)
                .attr('text-anchor', 'middle')
                .text(function(d) {
                    return d.name;
                });

            // Change the circle fill depending on whether it has children and is collapsed
            node.select('circle.nodeCircle').attr('r', 7.5);

            // Transition nodes to their new position.
            nodeUpdate = node.transition()
                .duration(duration).ease(ease)
                .attr('transform', function(d) {
                    return 'translate(' + d.x + ',' + d.y + ')';
                });

            // Fade the text in
            nodeUpdate.select('text').style('fill-opacity', 1);

            // Transition exiting nodes to the parent's new position.
            nodeExit = node.exit().transition()
                .duration(duration).ease(ease)
                .attr('transform', function(d) {
                    return 'translate(' + source.x + ',' + source.y + ')';
                })
                .remove();

            nodeExit.select('circle').attr('r', 0);
            nodeExit.select('text').style('fill-opacity', 0);

            // Update the links…
            link = svgGroup.selectAll('path.link').data(links, function(d) {
                return d.target.id;
            });

            // Enter any new links at the parent's previous position.
            link.enter().insert('path', 'g')
                .attr('class', 'link')
                .attr('d', function(d) {
                    var o = {
                        x: source.x0,
                        y: source.y0
                    };
                    return diagonal({
                        source: o,
                        target: o
                    });
                });

            // Transition links to their new position.
            link.transition()
                .duration(duration).ease(ease)
                .attr('d', diagonal);

            // Transition exiting nodes to the parent's new position.
            link.exit().transition()
                .duration(duration).ease(ease)
                .attr('d', function(d) {
                    var o = {
                        x: source.x,
                        y: source.y
                    };
                    return diagonal({
                        source: o,
                        target: o
                    });
                })
                .remove();

            // Stash the old positions for transition.
            nodes.forEach(function(d) {
                d.x0 = d.x;
                d.y0 = d.y;
            });
        },

        root: undefined,
        lastClicked: undefined,
        strategyLoads: false,
        strategyShown: false,
        initialCallDone: false,
        initialStrategyCallDone: false
    };

    function setAltLoad(node) {
        this.strategyShown = true;
        if (this.strategyLoads) {
            if (this.strategyToggler.clear()) {
                this.strategyShown = false;
                delete node.altLoad;
                delete node.altGasLoad;
            } else {
                node.altLoad = this.strategyLoads[node.name];

                if (this.strategyGasLoads.hasOwnProperty(node.name)) {
                    node.altGasLoad = this.strategyGasLoads[node.name];
                }
            }
        };
    };

    function setNodeLabelY(d) {
        return d.children ? -20 : 20;
    };

    function buildBase() {
        $('.loading').remove();

        baseSvg = createBaseSvg();
        svgGroup = baseSvg.append('g');
    };

    function createBaseSvg() {
        return d3.select(container).append('svg')
            .attr('width', viewerWidth)
            .attr('height', viewerHeight)
            .attr('class', 'overlay')
            .call(zoomListener)
            .on('wheel.zoom', null)
            .on('dblclick.zoom', null);
    };

    function transformData() {
        // Show nodes from the top-most two levels of the tree; nodes beneath will
        // be hidden until the user chooses to view them.
        establishMaxLabelLength.call(this);
        updateTreeData.call(this);
        recurseToggle(this.treeData);

        // Define the root
        this.root = this.treeData;
        this.root.x0 = viewerHeight / 2;
        this.root.y0 = 0;

        ETHelper.eachNode([this.root], function(node) {
            node.loads = {};
            node.loads[false] = node.load;
        });
    };

    function childCount(level, n) {
        if (n.children && n.children.length > 0) {
            if (levelWidth.length <= level + 1) levelWidth.push(0);

            levelWidth[level + 1] += n.children.length;
            n.children.forEach(function(d) {
                childCount(level + 1, d);
            });
        }
    };

    function overCapacity(d) {
        var load = (d.altLoad || d.load),
            // add 1e-5 so that we don't wrongly highlight nodes whose load has tiny
            // variations due to floating-point arithmetic.
            capacity = d.capacity + 1e-5;

        return d.capacity && (d3.max(load) > capacity || d3.min(load) < -capacity);
    };

    function setNodeClass(data) {
        var nodeClass = ("node " + data.stakeholder + " n" + data.id);
        if (data.node_selected) {
            nodeClass += " selected"
        }
        return nodeClass;
    };

    function recurseToggle(n) {
        toggleChildren(n)
        if (n.children && n.children.length > 0) {
            n.children.forEach(recurseToggle);
        };
    };

    function establishMaxLabelLength() {
        // Call visit function to establish maxLabelLength
        visit(this.treeData,
            function(d) {
                maxLabelLength = Math.max(d.name.length, maxLabelLength);

                if (d.children && d.children.length === 0) {
                    d.children = null;
                }
            },
            function(d) {
                return d.children && d.children.length > 0 ? d.children : null;
            }
        );
    };

    function updateTreeData() {
        visit(this.treeData, toggleChildren, function(n) {
            return n._children
        });
    };

    // Shows or hides children depending on the current state.
    function toggleChildren(d) {
        if (d.children) {
            d._children = d.children;
            d.children = null;
        } else if (d._children) {
            d.children = d._children;
            d._children = null;
        }

        return d;
    };

    function visit(parent, visitFn, childrenFn) {
        if (!parent) return;

        var children, count, i;

        visitFn(parent);
        children = childrenFn(parent);

        if (children) {
            count = children.length;

            for (i = 0; i < count; i++) {
                visit(children[i], visitFn, childrenFn);
            }
        }
    };

    // Function to center node when clicked/dropped so node doesn't get lost
    // when collapsing/moving with large amount of children.
    function centerNode(source) {
        var scale = zoomListener.scale(),
            x = source.x + 250
        y = 50;

        d3.select('g').transition()
            .duration(duration).ease(ease)
            .attr('transform', 'translate(' + x + ',' + y + ')' +
                'scale(' + scale + ')');

        zoomListener.scale(scale);
        zoomListener.translate([x, y]);
    };

    // Toggle children on click.
    function click(d) {
        if (d3.event && d3.event.defaultPrevented) return; // click suppressed

        localSettings.set('current_chart_id', d.id);

        _self.lastClicked = d;
        _self.showChart(d);
    };

    function showTechnologies(d) {
        var techTab = $('#technologies .row-fluid[data-node="' + d.name + '"]');
        if (techTab.length > 0) {
            techTab.show();
            $(".technologies-button").parent().removeClass("disabled");
            $(".nav-tabs li a[href='#technologies']").removeClass("disabled-tab");
        } else {
            $(".technologies-button").parent().addClass("disabled");
            $(".nav-tabs li a[href='#technologies']").addClass("disabled-tab");
        };
    };

    function setHeader(d) {
        $("h1 span").removeClass("hidden");
        $("h1 span.current-chart").text(d.name);

        enableCsvDownloadCurveButton(d);
    };

    function enableCsvDownloadCurveButton(d) {
        var downloadBtn = $('li a.download-curve')
        downloadBtn.parent().removeClass("disabled");
        downloadBtn.text("Download curve for '" + d.name + "'");

        downloadBtn.off('click').on('click', function(event) {
            event.preventDefault();

            var loads = d.load.map(function(value, index) {
                return "" + value + "," + (d.altLoad ? d.altLoad[index] : '');
            });

            if (d.altLoad) {
                loads.unshift('Strategies On,Strategies Off');
            } else {
                loads.unshift('Strategies Off,');
            }

            CSV.download(loads.join("\n"), (d.name + ' Curve.csv'), "data:text/csv;charset=utf-8");
        });
    };

    function dblClick(d) {
        if (d3.event.defaultPrevented) return; // click suppressed

        if (d._children || d.children) {
            toggleChildren(d);
            _self.update(d);
            centerNode(d);
        }
    };

    function resetStyle() {
        if (d3.event.target.className.baseVal == "overlay") {
            d3.selectAll(".overlay circle, .overlay text").style("opacity", 1.0);
            d3.selectAll(".overlay text").style({
                "font-weight": "normal"
            });
        };
    };

    function createD3Tree() {
        var tree = d3.layout.tree().nodeSize([nodeSize, nodeSize]);

        return tree.sort(function(a, b) {
            return b.name.toLowerCase() < a.name.toLowerCase() ? 1 : -1;
        });
    };

    function createD3Diagonal() {
        return d3.svg.diagonal().projection(function(d) {
            return [d.x, d.y];
        });
    };

    // Define the zoomListener which calls the zoom function on the "zoom"
    // event constrained within the scaleExtents
    function createZoomListener() {
        return d3.behavior.zoom()
            .scaleExtent([0.1, 3]).on('zoom', function() {
                svgGroup.attr('transform',
                    'translate(' + d3.event.translate + ')' +
                    'scale(' + d3.event.scale + ')');
            });
    }

    // Listener which prevents the drag movement of the diagram when clicking on
    // a node.
    function createDragListener() {
        return d3.behavior.drag().on('dragstart', function(d) {
            d3.event.sourceEvent.stopPropagation();
        });
    }

    function setLastClickedNode() {
        var settings = window.localSettings.getAll();
        if (settings && settings.current_chart_id) {
            var currentNode;
            ETHelper.eachNode([this.root], function(node) {
                if (node.id == settings.current_chart_id) {
                    currentNode = node;
                    return false;
                }
            });
            this.lastClicked = currentNode;
        };
    }

    function TreeGraph(_url, _container) {
        this.strategyToggler = new StrategyToggler(this, _url)

        container = _container;
        tree = createD3Tree();
        diagonal = createD3Diagonal();
        zoomListener = createZoomListener();
        dragListener = createDragListener();
    }

    return TreeGraph;
}());
