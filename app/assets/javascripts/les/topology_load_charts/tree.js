/*globals BusinessCaseTable,ErrorDisplayer,Les,StatusUpdater,
Strategies,TreeFetcher,LesGraph*/

var Tree = (function () {
    'use strict';

    function updateDomElements() {
        new StatusUpdater("Creating tree", 1).append();

        $("a.dropdown-toggle").first().addClass("disabled");
        $("#collapse-stakeholders select").prop('disabled', true);
    }

    function updateTree(data) {
        this.toggleLoading();

        this.treeGraph.reload(data);

        if (data.error) {
            $(".alert.alert-warning").removeClass("hidden")
                .find("span.error")
                .text(data.error);
        }
    }

    function displayError(error) {
        new ErrorDisplayer(
            error.responseJSON,
            $(".testing-ground-view")
        ).displayError();
    }

    function getTopology(callback) {
        $.ajax({
            type:        "GET",
            contentType: "application/json",
            dataType:    "json",
            url:         this.topologyUrl,
            success:     callback.bind(this),
            error:       displayError
        });
    }

    Tree.prototype = {
        nodes: [],
        basicCharts: [
            'electricity_basic', 'gas_basic', 'heat_basic'
        ],
        featureCharts: [
            'electricity_features', 'gas_features', 'heat_features'
        ],
        availableCharts: function () {
            return this.featureCharts.concat(this.basicCharts);
        },
        loading: false,
        create: function () {
            updateDomElements();

            this.treeGraph    = new Topology.LesGraph(this.target.selector);
            this.d3Chart      = new D3CarrierLoadChart(".load-graph .chart", this.basicCharts[0]);
            this.strategies   = new Strategies();
            this.lesses       = [ new Les(), new Les(this.strategies) ];

            getTopology.call(this, function (data) {
                $("#collapse-stakeholders select").prop('disabled', false);

                this.treeGraph.draw(data);
            });
        },

        updateStrategies: function () {
            this.update([this.lesses[1]]);
        },

        update: function (lesses) {
            this.toggleLoading();

            // Expand with node_start  and node_end
            new TreeFetcher(lesses || this.lesses)
                .fetch(this.d3Chart.settings)
                .done(updateTree.bind(this))
                .fail(displayError);
        },

        toggleLoading: function () {
            this.loading = !this.loading;

            $(".load-graph-wrapper .loading-spinner").toggleClass("on");
            $("button.apply_strategies").prop("disabled", this.loading);
        },

        addNode: function (name) {
            if (!(this.nodes.indexOf(name) > -1)) {
                this.nodes.push(name);
            }
        }
    };

    function Tree(target) {
        this.target        = target;
        this.data          = target.data();
        this.url           = this.data.url;
        this.strategiesUrl = this.data.strategiesUrl;
        this.topologyUrl   = this.data.topologyUrl;
        this.id            = this.data.id;
    }

    return Tree;
}());
