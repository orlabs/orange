(function (L) {
    var _this = null;
    L.KVStore = L.KVStore || {};
    _this = L.KVStore = {
        data: {
            rules: {},
        },

        init: function () {
            _this.loadConfigs();
            _this.initEvents();

        },

        initEvents: function () {
            L.Common.initRuleAddDialog("kvstore", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("kvstore", _this);//删除规则对话框
            L.Common.initRuleEditDialog("kvstore", _this);//编辑规则对话框
            L.Common.initSyncDialog("kvstore", _this);//编辑规则对话框

            L.Common.initViewAndDownloadEvent("kvstore");
            L.Common.initSwitchBtn("kvstore");//kvstore关闭、开启
        },

        loadConfigs: function () {
            $.ajax({
                url: '/kvstore/configs',
                type: 'get',
                cache:false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        L.Common.resetSwitchBtn(result.data.enable, "kvstore");
                        $("#switch-btn").show();
                        $("#view-btn").show();
                        _this.renderTable(result.data);//渲染table
                        _this.data.enable = result.data.enable;
                        _this.data.rules = result.data.rules;//重新设置数据

                    } else {
                        L.Common.showTipDialog("错误提示", "查询kvstore配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询kvstore配置请求发生异常");
                }
            });
        },

        renderTable: function (data, highlight_id) {
            highlight_id = highlight_id || 0;
            var tpl = $("#rule-item-tpl").html();
            data.highlight_id = highlight_id;
            var html = juicer(tpl, data);
            $("#rules").html(html);
        },
    };
}(APP));
