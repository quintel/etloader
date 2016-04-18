/*globals Ajax*/

var D3StackedBarGraph = (function () {
    'use strict';

    var chartKeys,
        margin = {top: 20, right: 160, bottom: 30, left: 40},
        width  = 1000 - margin.left - margin.right,
        height = 500 - margin.top - margin.bottom,

        x = d3.scale.ordinal().rangeRoundBands([0, width], 0.1),
        y = d3.scale.linear().rangeRound([height, 0]),

        color = d3.scale.ordinal()
            .range(["#e1d146", "#4cb44a", "#508ac7"]),

        xAxis = d3.svg.axis()
            .scale(x)
            .orient("bottom"),

        yAxis = d3.svg.axis()
            .scale(y)
            .orient("left");

    function transformData(data) {
        var key,
            l = chartKeys.length;

        data.forEach(function (d) {
            var posBase = 0,
                negBase = 0;

            d.stacked_transformed = [];

            chartKeys.forEach(function (s, index) {
                var v = { size: Math.abs(d.stacked[s]), y0: 0, index: index };

                if (d.stacked[s] > 0) {
                    posBase += v.size;
                    v.y0 = posBase
                } else {
                    v.y0 = negBase;
                    negBase -= v.size;
                }

                d.stacked_transformed.push(v);
            });
        });

        data.extent = d3.extent(
            d3.merge(
                d3.merge(
                    data.map(function(e) {
                        return e.stacked_transformed.map(function(f) {
                            return [f.y0, f.y0 - f.size];
                        })
                    })
                )
            )
        )
    }

    function drawD3Graph(data) {
        var state, legend;

        chartKeys = Object.keys(data[0].stacked);

        this.svg = d3.select(this.scope).append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        color.domain(data);

        transformData(data);

        x.domain(data.map(function (d) { return d.pressure_level; }));
        y.domain(data.extent);

        this.svg.append("g")
            .attr("class", "x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis);

        this.svg.append("g")
            .attr("class", "y axis")
            .call(yAxis)
            .append("text")
            .attr("transform", "rotate(-90)")
            .attr("y", 6)
            .attr("dy", ".71em")
            .style("text-anchor", "end")
            .text("kWh");

        this.svg.append("line")
            .attr("class", "zero-line")
            .style("stroke", "#AAA")
            .attr("x1", 0)
            .attr("x2", width)
            .attr("y1", y(0))
            .attr("y2", y(0))

        state = this.svg.selectAll(".state")
            .data(data)
            .enter().append("g")
            .attr("class", "g")
            .attr("transform", function (d) {
                return "translate(" + x(d.pressure_level) + ",0)";
            });

        state.selectAll("rect")
            .data(function (d) { return d.stacked_transformed; })
            .enter().append("rect")
            .attr("width", x.rangeBand())
            .attr("y", function (d) { return y(d.y0); })
            .attr("height", function (d) { return y(0) - y(d.size); })
            .style("fill", function (d) { return color(d.index); });

        legend = this.svg.selectAll(".legend")
            .data(chartKeys)
            .enter().append("g")
            .attr("class", "legend")
            .attr("transform", function (d, i) {
                return "translate(20," + i * 20 + ")";
            });

        legend.append("rect")
            .attr("x", width - 18)
            .attr("width", 18)
            .attr("height", 18)
            .style("fill", color);

        legend.append("text")
            .attr("x", width + 4)
            .attr("y", 9)
            .attr("dy", ".35em")
            .style("text-anchor", "begin")
            .text(function (d) {
                return d;
            });
    }

    function reloadD3Graph() {
    }

    D3StackedBarGraph.prototype = {
        svg: null,
        line: null,
        draw: function () {
            Ajax.json(this.url, {}, drawD3Graph.bind(this));

            return this;
        },

        reload: function () {
            Ajax.json(this.url, {}, reloadD3Graph.bind(this));
        }
    };

    function D3StackedBarGraph(scope, data) {
        this.scope = scope;
        this.url   = data.url;
        this.title = data.title;
    }

    return D3StackedBarGraph;
}());

