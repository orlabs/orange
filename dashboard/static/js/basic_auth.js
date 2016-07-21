(function (L) {
    var _this = null;
    L.BasicAuth = L.BasicAuth || {};
    _this = L.BasicAuth = {
        data: {
            rules: {}
        },

        init: function () {
            _this.loadConfigs();
            _this.initEvents();
        },

        initEvents: function () {
            L.Common.initRuleAddDialog("basic_auth", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("basic_auth", _this);//删除规则对话框
            L.Common.initRuleEditDialog("basic_auth", _this);//编辑规则对话框
            L.Common.initSyncDialog("basic_auth", _this);//编辑规则对话框

            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initCredentialAddOrRemove();//添加或删除credential
            L.Common.initCredentialAddBtnEvent();

            L.Common.initViewAndDownloadEvent("basic_auth");
            L.Common.initSwitchBtn("basic_auth");//redirect关闭、开启
        },


        buildRule: function () {
            var result = {
                success: false,
                data: {
                    name: null,
                    judge: {},
                    handle: {}
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

            //build handle
            var buildHandleResult = _this.buildHandle();
            if (buildHandleResult.success == true) {
                result.data.handle = buildHandleResult.handle;
            } else {
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

        buildHandle: function () {
            var result = {};
            var handle = {};

            var handle_credentials = _this.buildCredentials();
            if(!handle_credentials.success){
                result.success = false;
                result.data = handle_credentials.data;
                return result;
            }else{
                handle.credentials = handle_credentials.data;
            }

            var handle_code = $("#rule-handle-code").val();
            if (!handle_code) {
                result.success = false;
                result.data = "未授权处理的状态码不能为空";
                return result;
            }

            handle.code = parseInt(handle_code);

            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },

        buildCredentials: function () {
            var result = {
                success: false,
                data: []
            };

            var credentials = [];

            var tmp_success = true;
            var tmp_tip = "";
            $(".credential-holder").each(function () {
                var self = $(this);
                var credential = {};
                var username = self.find("input[name=rule-handle-credential-username]").val();
                var password = self.find("input[name=rule-handle-credential-password]").val();

                if (!username || !password) {
                    tmp_success = false;
                    tmp_tip = "credential的username和password字段均不得为空";
                }

                credential.username = username;
                credential.password = password;
                credentials.push(credential);
            });

            if (!tmp_success) {
                result.success = false;
                result.data = tmp_tip;
                return result;
            }
            result.data = credentials;

            //判断个数是否匹配
            if (credentials.length < 1) {
                result.success = false;
                result.data = "请配置credentials";
                return result;
            }

            result.success = true;
            return result;
        },

        loadConfigs: function () {
            $.ajax({
                url: '/basic_auth/configs',
                type: 'get',
                cache:false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        L.Common.resetSwitchBtn(result.data.enable, "basic_auth");
                        $("#switch-btn").show();
                        $("#view-btn").show();
                        _this.renderTable(result.data);//渲染table
                        _this.data.enable = result.data.enable;
                        _this.data.rules = result.data.rules;//重新设置数据

                    } else {
                        L.Common.showTipDialog("错误提示", "查询Basic Auth配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询Basic Auth配置请求发生异常");
                }
            });
        },

        renderTable: function (data, highlight_id) {
            highlight_id = highlight_id || 0;
            var tpl = $("#rule-item-tpl").html();
            data.highlight_id = highlight_id;
            var html = juicer(tpl, data);
            $("#rules").html(html);
        }
    };
}(APP));