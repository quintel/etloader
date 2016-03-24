/*globals BusinessCaseTable,D3LoadChart,ErrorDisplayer,Les,StatusUpdater,
Strategies,TreeFetcher,TreeGraph*/
var Tree = (function () {
    'use strict';

    function updateDomElements() {
        new StatusUpdater("Creating tree", 1).append();

        $("a.dropdown-toggle").first().addClass("disabled");
        $("#collapse-stakeholders select").prop('disabled', true);
    }

    function updateTree(data) {
        this.toggleLoading();

        this.treeGraph.setData(data).reload();

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
        loading: false,
        create: function () {
            updateDomElements();

            this.treeGraph    = new TreeGraph(this.target.selector);
            this.d3Chart      = new D3LoadChart(".load-graph .chart", "load");
            this.strategies   = new Strategies();
            this.lesses       = [ new Les(), new Les(this.strategies) ];
            this.businessCase = new BusinessCaseTable("#business_case_table");

            this.businessCase.setNoCaseMessage();

            getTopology.call(this, function (data) {
                $("#collapse-stakeholders select").prop('disabled', false);

                this.treeGraph.setData(data).showGraph();
            });
        },

        updateStrategies: function () {
            this.update([this.lesses[1]]);
        },

        update: function (lesses) {
            this.toggleLoading();

            // Expand with node_start  and node_end
            new TreeFetcher(lesses || this.lesses)
                .fetch(this.d3Chart.lesOptions)
                .done(updateTree.bind(this))
                .fail(displayError);
        },

        toggleLoading: function () {
            var loadingSpinner = $(".load-graph-wrapper .loading-spinner");
            loadingSpinner.toggleClass("on");

            this.loading = !this.loading;

            $("button.apply_strategies").prop("disabled", loadingSpinner.hasClass("on"));
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
