(function (L) {
    var _this = null;
    L.Headers = L.Headers || {};
    _this = L.Headers = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("headers", _this, true);
            _this.initEvents();
        },

        initEvents: function(){
            L.Common.initRuleAddDialog("headers", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("headers", _this);//删除规则对话框
            L.Common.initRuleEditDialog("headers", _this);//编辑规则对话框
            L.Common.initRuleSortEvent("headers", _this);

            L.Common.initSelectorAddDialog("headers", _this);
            L.Common.initSelectorDeleteDialog("headers", _this);
            L.Common.initSelectorEditDialog("headers", _this);
            L.Common.initSelectorSortEvent("headers", _this);
            L.Common.initSelectorClickEvent("headers", _this);

            L.Common.initSelectorTypeChangeEvent();//选择器类型选择事件
            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件


            L.Common.initHeaderAddBtnEvent();
            L.Common.initHeaderAddOrRemove();

            L.Common.initViewAndDownloadEvent("headers", _this);
            L.Common.initSwitchBtn("headers", _this);//redirect关闭、开启
            L.Common.initSyncDialog("headers", _this);//编辑规则对话框
        },


        buildRule: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    judge:{},
                    extractor: {},
                    handle:{},
                    headers:{}
                }
            };

            //build name and judge
            var buildJudgeResult = L.Common.buildJudge();
            if(buildJudgeResult.success == true){
                result.data.name = buildJudgeResult.data.name;
                result.data.judge = buildJudgeResult.data.judge;
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

            //build headers
            var buildExtractorResult = L.Common.buildHeader();
            if (buildExtractorResult.success == true) {
                result.data.headers = buildExtractorResult.data.headers;
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
            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        }
    };
}(APP));
