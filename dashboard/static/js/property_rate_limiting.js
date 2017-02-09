(function (L) {
    var _this = null;
    L.PropertyRateLimiting = L.PropertyRateLimiting || {};
    _this = L.PropertyRateLimiting = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("property_rate_limiting", _this, true);
            _this.initEvents();
        },

        initEvents: function(){
            var op_type = "property_rate_limiting";
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


            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            L.Common.initViewAndDownloadEvent(op_type, _this);
            L.Common.initSwitchBtn(op_type, _this);//redirect关闭、开启
            L.Common.initSyncDialog(op_type, _this);//编辑规则对话框
        },

        buildRule: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    judge:{},
                    extractor: {},
                    handle:{}
                }
            };

            //build name and judge
            var buildJudgeResult = L.Common.buildName();
            if(buildJudgeResult.success == true){
                result.data.name = buildJudgeResult.data.name;
            }else{
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

            //build handle
            var buildHandleResult = _this.buildHandle();
            if(buildHandleResult.success == true){
                result.data.handle = buildHandleResult.handle;
            }else{
                result.success = false;
                result.data = buildHandleResult.data;
                return result;
            }

            //enable or not
            var enable = $('#rule-enable').is(':checked');
            result.data.enable = enable;

            result.success = true;
            return result;
        },

        buildHandle: function(){
            var result = {};
            var handle = {};
            var period = $("#rule-handle-period").val();
            period = parseInt(period);
            if(isNaN(period)){
                console.log("时间间隔错误：", period);
                result.success = false;
                result.data = "时间间隔选择错误，须是整数";
                return result;
            }
            handle.period = period;

            var count = $("#rule-handle-count").val();
            count = parseInt(count);
            if(isNaN(count)){
                console.log("最多访问次数输入错误：", count);
                result.success = false;
                result.data = "最多访问次数输入错误，须是整数";
                return result;
            }
            handle.count = count;

            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },
    };
}(APP));
