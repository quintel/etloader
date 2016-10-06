/*globals CSV,StrategyHelper*/

var ChartRenderer = (function () {
    'use strict';

    function toggleSelectedNode() {
        d3.selectAll(".overlay circle, .overlay text").style("opacity", 0.3);
        d3.selectAll(".overlay text").style({
            "font-weight": "normal",
            "text-decoration": "none"
        });

        d3.select(".overlay g.node.n" + this.id).select("circle").style("opacity", 1.0);
        d3.select(".overlay g.node.n" + this.id).select("text").style({
            "opacity": 1.0,
            "font-weight": "bold"
        });
    }

    function showTechnologies() {
        var techTab           = $('#technologies .row-fluid[data-node="' + this.name + '"]'),
            technologyButtons = $(".technologies-button").parent(),
            technologyNav     = $(".nav-tabs li a[href='#technologies']");

        if (techTab.length > 0) {
            techTab.show();
            technologyNav.removeClass("disabled-tab");
            technologyButtons
                .removeClass("disabled")
                .off("click.disabled");
        } else {
            technologyNav.addClass("disabled-tab");
            technologyButtons
                .addClass("disabled")
                .on("click.disabled", function (e) {
                    e.preventDefault();
                });
        }
    }

    function downloadLoad(loadType) {
        var loads = [];

        window.currentTree.availableCharts().forEach(function (chartType) {
            if (this[chartType]) {
                [chartType].concat(this[chartType][loadType]).forEach(function (value, i) {
                    if (loads[i]) {
                        loads[i] += (','  + value);
                    } else {
                        loads[i] = value;
                    }
                });
            }
        }.bind(this));

        CSV.download(loads.join("\n"), (this.name + ' Curve.csv'), "data:text/csv;charset=utf-8");
    }

    function enableCsvDownloadCurveButton() {
        var self = this,
            downloadBtn = $('li a.download-curve');

        downloadBtn.parent().removeClass("disabled");
        downloadBtn.text("Download curve for '" + this.name + "'");

        downloadBtn.off('click').on('click', function (event) {
            event.preventDefault();

            downloadLoad.call(self, 'total');
        });
    }

    function setHeader() {
        $("h1 span").removeClass("hidden");
        $("h1 span.current-chart").text(this.name);

        enableCsvDownloadCurveButton.call(this);
    }

    function changeViewOfD3(e) {
        var input      = $(e.target),
            d3Chart    = window.currentTree.d3Chart,
            attrName   = input.attr('name'),
            isCheckbox = (input.attr('type') === 'checkbox'),
            value      = isCheckbox ? input.prop('checked') : input.val();

        d3Chart.view(attrName, value).update();

        LoadChartInterface.update.call(this);
    }

    function toggleDomParts() {
        $('#technologies .row-fluid, p.info').hide();
        $(".load-graph-wrapper a[href='#load']").tab('show');
        $("select.load-date").removeClass("hidden");

        $('.chart-view').on('change', changeViewOfD3.bind(this));

        showTechnologies.call(this);
        setHeader.call(this);
        toggleSelectedNode.call(this);
    }

    function addNewLoadChartPlatform() {
        if (window.currentTree.d3Chart.isRendered()) {
            window.currentTree.d3Chart.update(this.nodeData);
        } else {
            window.currentTree.d3Chart.render(this.nodeData);
        }
    }

    function isValidNodeData() {
        var chart,
            d = this.nodeData;

        return window.currentTree.availableCharts().some(function (chartType) {
            chart = d[chartType];

            return chart && chart.total && chart.total.length;
        });
    }

    function renderLoadChart() {
        if (isValidNodeData.call(this)) {
            addNewLoadChartPlatform.call(this);
        } else {
            window.currentTree.update();
        }
    }

    ChartRenderer.prototype = {
        show: function () {
            if (this.nodeData === undefined) {
                return false;
            }

            // This is currently not desired due to the fact that
            // congestion is not showing up correctly.
            //
            // See: https://github.com/quintel/etmoses/issues/1026
            //
            // window.currentTree.addNode(this.nodeData.name);
            //
            renderLoadChart.call(this, this.nodeData);
            toggleDomParts.call(this.nodeData);
            LoadChartInterface.update.call(this.nodeData);
        }
    };

    function ChartRenderer(treeChart, nodeData) {
        this.treeChart = treeChart;
        this.nodeData  = nodeData;
    }

    return ChartRenderer;
}());
