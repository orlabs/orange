(function (L) {
    var _this = null;
    L.BasicAuth = L.BasicAuth || {};
    _this = L.BasicAuth = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("basic_auth", _this, true);
            _this.initEvents();
        },

        initEvents: function () {
            L.Common.initRuleAddDialog("basic_auth", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("basic_auth", _this);//删除规则对话框
            L.Common.initRuleEditDialog("basic_auth", _this);//编辑规则对话框
            L.Common.initRuleSortEvent("basic_auth", _this);

            L.Common.initSelectorAddDialog("basic_auth", _this);
            L.Common.initSelectorDeleteDialog("basic_auth", _this);
            L.Common.initSelectorEditDialog("basic_auth", _this);
            L.Common.initSelectorSortEvent("basic_auth", _this);
            L.Common.initSelectorClickEvent("basic_auth", _this);

            L.Common.initSelectorTypeChangeEvent();//选择器类型选择事件
            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            _this.initCredentialAddOrRemove();//添加或删除credential
            _this.initCredentialAddBtnEvent();

            L.Common.initViewAndDownloadEvent("basic_auth", _this);
            L.Common.initSwitchBtn("basic_auth", _this);//redirect关闭、开启
            L.Common.initSyncDialog("basic_auth", _this);//编辑规则对话框
        },

        //增加、删除credential按钮事件
        initCredentialAddOrRemove: function () {

            //点击“加号“添加新的输入行
            $(document).on('click', '#credential-area .pair .btn-add', _this.addNewCredential);

            //删除输入行
            $(document).on('click', '#credential-area .pair .btn-remove', function (event) {
                $(this).parents('.form-group').remove();//删除本行输入
                _this.resetAddCredentialBtn();
            });
        },

        initCredentialAddBtnEvent: function () {
            $(document).on('click', '#add-credential-btn', function () {
                var row;
                var current_es = $('.credential-holder');
                if (current_es && current_es.length) {
                    row = current_es[current_es.length - 1];
                }
                if (row) {//至少存在了一个提取项
                    var new_row = $(row).clone(true);
                    $(new_row).find("label").text("");
                    $("#credential-area").append($(new_row));
                } else {//没有任何提取项，从模板创建一个
                    var html = $("#single-credential-tmpl").html();
                    $("#credential-area").append(html);
                }

                _this.resetAddCredentialBtn();
            });
        },


        addNewCredential: function (event) {
            var self = $(this);
            var row = self.parents('.credential-holder');
            var new_row = row.clone(true);

            $(new_row).find("input[name=rule-handle-credential-username]").val("");
            $(new_row).find("input[name=rule-handle-credential-password]").val("");
            $(new_row).find("label").text("");

            $(new_row).insertAfter($(this).parents('.credential-holder'))
            _this.resetAddCredentialBtn();
        },

        resetAddCredentialBtn: function () {
            var l = $("#credential-area .pair").length;
            var c = 0;
            $("#credential-area .pair").each(function () {
                c++;
                if (c == l) {
                    $(this).find(".btn-add").show();
                    $(this).find(".btn-remove").show();
                } else {
                    $(this).find(".btn-add").hide();
                    $(this).find(".btn-remove").show();
                }
            })
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
    };
}(APP));
