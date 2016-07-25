(function (L) {
    var _this = null;
    L.KeyAuth = L.KeyAuth || {};
    _this = L.KeyAuth = {
        data: {
            rules: {}
        },

        init: function () {
            _this.loadConfigs();
            _this.initEvents();
        },

        initEvents: function () {
            L.Common.initRuleAddDialog("key_auth", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("key_auth", _this);//删除规则对话框
            L.Common.initRuleEditDialog("key_auth", _this);//编辑规则对话框
            L.Common.initSyncDialog("key_auth", _this);//编辑规则对话框

            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            _this.initCredentialAddOrRemove();//添加或删除credential
            _this.initCredentialAddBtnEvent();

            L.Common.initViewAndDownloadEvent("key_auth");
            L.Common.initSwitchBtn("key_auth");//redirect关闭、开启
        },

        //增加、删除credential按钮事件
        initCredentialAddOrRemove: function () {

            //点击“加号“添加新的输入行
            $(document).on('click', '#credential-area .pair .btn-success', _this.addNewCredential);

            //删除输入行
            $(document).on('click', '#credential-area .pair .btn-danger', function (event) {
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

            $(new_row).find("input[name=rule-handle-credential-key]").val("");
            $(new_row).find("input[name=rule-handle-credential-target-value]").val("");
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
                    $(this).find(".btn-success").show();
                    $(this).find(".btn-danger").show();
                } else {
                    $(this).find(".btn-success").hide();
                    $(this).find(".btn-danger").show();
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

                var credential_type = self.find("select[name=rule-handle-credential-type]").val();
                if (!credential_type) {
                    tmp_success = false;
                    tmp_tip = "credential的type字段不得为空";
                }
                
                var key = self.find("input[name=rule-handle-credential-key]").val();
                var target_value = self.find("input[name=rule-handle-credential-target-value]").val();
                if (!key || !target_value) {
                    tmp_success = false;
                    tmp_tip = "credential的key和target_value字段均不得为空";
                }

                credential.type = parseInt(credential_type);
                credential.key = key;
                credential.target_value = target_value;
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

        loadConfigs: function (highlight_id) {
            $.ajax({
                url: '/key_auth/configs',
                type: 'get',
                cache:false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        L.Common.resetSwitchBtn(result.data.enable, "key_auth");
                        $("#switch-btn").show();
                        $("#view-btn").show();
                        _this.renderTable(result.data, highlight_id);//渲染table
                        _this.data.enable = result.data.enable;
                        _this.data.rules = result.data.rules;//重新设置数据

                    } else {
                        L.Common.showTipDialog("错误提示", "查询Key Auth配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询Key Auth配置请求发生异常");
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
