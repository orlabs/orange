(function (L) {
    var _this = null;
    L.HmacAuth = L.HmacAuth || {};
    _this = L.HmacAuth = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("hmac_auth", _this, true);
            _this.initEvents();
        },

        initEvents: function () {
            var op_type = "hmac_auth";
            //添加规则对话框
            L.Common.initRuleAddDialog(op_type, _this);
            //删除规则对话框
            L.Common.initRuleDeleteDialog(op_type, _this);
            //编辑规则对话框
            L.Common.initRuleEditDialog(op_type, _this);
            L.Common.initRuleSortEvent(op_type, _this);

            L.Common.initSelectorAddDialog(op_type, _this);
            L.Common.initSelectorDeleteDialog(op_type, _this);
            L.Common.initSelectorEditDialog(op_type, _this);
            L.Common.initSelectorSortEvent(op_type, _this);
            L.Common.initSelectorClickEvent(op_type, _this);
            //选择器类型选择事件
            L.Common.initSelectorTypeChangeEvent();
            //添加或删除条件
            L.Common.initConditionAddOrRemove();
            //judge类型选择事件
            L.Common.initJudgeTypeChangeEvent();
            //condition类型选择事件
            L.Common.initConditionTypeChangeEvent();

            L.Common.initViewAndDownloadEvent(op_type, _this);
            //redirect关闭、开启
            L.Common.initSwitchBtn(op_type, _this);
            //编辑规则对话框
            L.Common.initSyncDialog(op_type, _this);
        },

        buildRule: function () {
            let result = {
                success: false,
                data: {
                    name: null,
                    judge: {},
                    handle: {}
                }
            };

            //build name and judge
            let buildJudgeResult = L.Common.buildJudge();
            if (buildJudgeResult.success == true) {
                result.data.name = buildJudgeResult.data.name;
                result.data.judge = buildJudgeResult.data.judge;
            } else {
                result.success = false;
                result.data = buildJudgeResult.data;
                return result;
            }

            //build handle
            let buildHandleResult = _this.buildHandle();
            if (buildHandleResult.success == true) {
                result.data.handle = buildHandleResult.handle;
            } else {
                result.success = false;
                result.data = buildHandleResult.data;
                return result;
            }

            //enable or not
            let enable = $('#rule-enable').is(':checked');
            result.data.enable = enable;

            result.success = true;
            return result;
        },

        buildHandle: function () {
            let result = {};
            let handle = {};
            // 检查秘钥是否为空
            let handle_secret = $("#rule-handle-secret").val();
            if (!handle_secret) {
                result.success = false;
                result.data = "[秘钥] 不能为空";
                return result
            }

            let handle_algorithm = $("#rule-handle-algorithm").val();
            if (!handle_algorithm) {
                result.success = false;
                result.data = "[算法] 不能为空";
                return result
            }

            let handle_timeout = $("#rule-handle-timeout").val();
            if (!handle_timeout) {
                result.success = false;
                result.data = "[超时] 不能为空";
                return result
            }

            handle.credentials = {};
            handle.credentials.secret = handle_secret;
            handle.credentials.algorithm = handle_algorithm;
            handle.credentials.timeout = parseInt(handle_timeout);

            // 检查处理码是否为空
            let handle_code = $("#rule-handle-code").val();
            if (!handle_code) {
                result.success = false;
                result.data = "[处理] 状态码不能为空";
                return result;
            }

            handle.code = parseInt(handle_code);
            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },
    };
}(APP));
