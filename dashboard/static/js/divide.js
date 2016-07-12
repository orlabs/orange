(function (L) {
    var _this = null;
    L.Divide = L.Divide || {};
    _this = L.Divide = {
        data: {
            rules: {},
        },

        init: function () {
            _this.loadConfigs();
            _this.initEvents();

        },

        initEvents: function () {
            L.Common.initRuleAddDialog("divide", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("divide", _this);//删除规则对话框
            L.Common.initRuleEditDialog("divide", _this);//编辑规则对话框
            L.Common.initSyncDialog("divide", _this);//编辑规则对话框

            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            L.Common.initViewAndDownloadEvent("divide");

            L.Common.initSwitchBtn("divide");//divide关闭、开启
        },


        buildRule: function () {
            var result = {
                success: false,
                data: {
                    name: null,
                    judge: {}
                }
            };

            //build name and judge
            var buildJudgeResult = L.Common.buildJudge();
            if (buildJudgeResult.success == true) {
                result.data.name = buildJudgeResult.data.name;
                result.data.judge = buildJudgeResult.data.judge;
            } else {
                result.success = false;
                result.data = buildJudgeResult.data;
                return result;
            }

            //build extractor
            var buildExtractorResult = L.Common.buildExtractor();
            if (buildExtractorResult.success == true) {
                result.data.extractor = buildExtractorResult.data.extractor;
            } else {
                result.success = false;
                result.data = buildExtractorResult.data;
                return result;
            }

            //build upstream
            var upstream_host = $("#rule-upstream-host").val();
            // if (!upstream_host) {
            //     result.success = false;
            //     result.data = "upstream host不得为空";
            //     return result;
            // }
            result.data.upstream_host = upstream_host||"";

            var upstream_url = $("#rule-upstream-url").val();
            if (!upstream_url) {
                result.success = false;
                result.data = "upstream url不得为空";
                return result;
            }
            result.data.upstream_url = upstream_url;
            result.data.log = ($("#rule-log").val() === "true");

            //enable or not
            var enable = $('#rule-enable').is(':checked');
            result.data.enable = enable;

            result.success = true;
            return result;
        },

        loadConfigs: function () {
            $.ajax({
                url: '/divide/configs',
                type: 'get',
                cache:false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        L.Common.resetSwitchBtn(result.data.enable, "divide");
                        $("#switch-btn").show();
                        $("#view-btn").show();
                        _this.renderTable(result.data);//渲染table
                        _this.data.enable = result.data.enable;
                        _this.data.rules = result.data.rules;//重新设置数据

                    } else {
                        L.Common.showTipDialog("错误提示", "查询divide配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询divide配置请求发生异常");
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