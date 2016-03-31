/*globals Ajax,EditableTable*/

var GasAssetListTable = (function () {
    'use strict';

    var editableTable, assetUrl;

    function setAssetTypeOptions(data, initial) {
        var options = [];

        data.forEach(function (option) {
            options.push(
                $("<option/>").attr("value", option.type).html(option.type)
            );
        });

        $(this).parents("tr").find("select.type")
            .html(options)
            .val(function () {
                var type = $(this).data('type');

                return ((type === 'blank' || !initial) ? $(this).val() : type);
            });
    }

    function getAssetData(target) {
        var row = $(target).parents("tr"),
            assetData = {
                part: row.find("select.part").val(),
                pressure_level: row.find("select.pressure_level").val()
            };

        return assetData;
    }

    function getAssetTypes(e) {
        var gasData = [ getAssetData(e.target) ];

        Ajax.json(assetUrl, { gas_parts: gasData }, function (data) {
            setAssetTypeOptions.call(e.target, data[0], false);
        });
    }

    function getMultipleAssetTypes(data) {
        Ajax.json(assetUrl, { gas_parts: data }, function (data) {
            data.forEach(function (options, i) {
                setAssetTypeOptions.call($($("select.type")[i]), options, true);
            });
        });
    }

    function setInitialSelectBoxes() {
        var data = [];

        $(editableTable.selector).find("select.part").each(function () {
            data.push(getAssetData(this));
        });

        getMultipleAssetTypes(data);
    }

    function setEventListeners() {
        $(editableTable.selector).find("select.part, select.pressure_level")
            .off("change")
            .on("change", getAssetTypes);
    }

    GasAssetListTable.prototype = {
        append: function () {
            editableTable.append(this.updateTable);
            setInitialSelectBoxes.call(this);
            setEventListeners();
        },

        updateTable: function () {
            setEventListeners();

            $("#gas_asset_list_asset_list").text(JSON.stringify(editableTable.getData()));
        }
    };

    function GasAssetListTable(selector) {
        assetUrl      = $(selector).data('url');
        editableTable = new EditableTable(selector);
    }

    return GasAssetListTable;
}());
