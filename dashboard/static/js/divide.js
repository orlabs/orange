(function (L) {
    var _this = null;
    L.Divide = L.Divide || {};
    _this = L.Divide = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("divide", _this, true);
            _this.initEvents();
        },

        initEvents: function () {
            var op_type = "divide";
            L.Common.initRuleAddDialog(op_type, _this);//添加规则对话框
            L.Common.initRuleDeleteDialog(op_type, _this);//删除规则对话框
            L.Common.initRuleEditDialog(op_type, _this);//编辑规则对话框
            L.Common.initRuleSortEvent(op_type, _this);

            L.Common.initSelectorAddDialog(op_type, _this);
            L.Common.initSelectorDeleteDialog(op_type, _this);
            L.Common.initSelectorEditDialog(op_type, _this);
            L.Common.initSelectorSortEvent(op_type, _this);
            L.Common.initSelectorClickEvent(op_type, _this);

            L.Common.initSelectorTypeChangeEvent();//选择器类型选择事件
            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            L.Common.initViewAndDownloadEvent(op_type, _this);
            L.Common.initSwitchBtn(op_type, _this);//redirect关闭、开启
            L.Common.initSyncDialog(op_type, _this);//编辑规则对话框
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
    };
}(APP));
