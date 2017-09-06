(function (L) {
    var _this = null;
    L.JwtAuth = L.JwtAuth || {};
    _this = L.JwtAuth = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("jwt_auth", _this, true);
            _this.initEvents();
        },

        initEvents: function () {
            var op_type = "jwt_auth";
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

             _this.initPayloadAddOrRemove(); //添加或删除 payload key
            _this.initPayloadAddBtnEvent();

            L.Common.initViewAndDownloadEvent(op_type, _this);
            L.Common.initSwitchBtn(op_type, _this);//redirect关闭、开启
            L.Common.initSyncDialog(op_type, _this);//编辑规则对话框
        },



        //增加、删除  payload key 按钮事件
        initPayloadAddOrRemove: function () {

            //点击“加号“添加新的输入行
            $(document).on('click', '#payload-area .pair .btn-add', _this.addNewPayload);

            //删除输入行
            $(document).on('click', '#payload-area .pair .btn-remove', function (event) {
                $(this).parents('.form-group').remove();//删除本行输入
                _this.resetAddPayloadBtn();
            });
        },

        initPayloadAddBtnEvent: function () {
            $(document).on('click', '#add-payload-btn', function () {
                var row;
                var current_es = $('.payload-holder');
                if (current_es && current_es.length) {
                    row = current_es[current_es.length - 1];
                }
                if (row) {//至少存在了一个提取项
                    var new_row = $(row).clone(true);
                    $(new_row).find("label").text("");
                    $("#payload-area").append($(new_row));
                } else {//没有任何提取项，从模板创建一个
                    var html = $("#single-payload-tmpl").html();
                    $("#payload-area").append(html);
                }

                _this.resetAddPayloadBtn();
            });
        },


        addNewPayload: function (event) {
            var self = $(this);
            var row = self.parents('.payload-holder');
            var new_row = row.clone(true);

            $(new_row).find("input[name=rule-handle-key]").val("");
            $(new_row).find("input[name=rule-handle-target-value]").val("");
            $(new_row).find("label").text("");

            $(new_row).insertAfter($(this).parents('.payload-holder'))
            _this.resetAddPayloadBtn();
        },

        resetAddPayloadBtn: function () {
            var l = $("#payload-area .pair").length;
            var c = 0;
            $("#payload-area .pair").each(function () {
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

            var handle_credentials = _this.buildPayloads();
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

        buildPayloads: function () {
            var result = {
                success: false,
                data: []
            };

            var secret = '';

            var tmp_success = true;
            var tmp_tip = "";
            $(".secret-holder").each(function () {
                var self = $(this);
                secret = self.find("input[name=rule-handle-secret]").val();
                if (!secret) {
                    tmp_success = false;
                    tmp_tip = "Secret 不得为空";
                }
            });

            var payloads = [];

            $(".payload-holder").each(function () {
                var self = $(this);
                var payload = {};

                var payload_type = self.find("select[name=rule-handle-payload-type]").val();
                if (!payload_type) {
                    tmp_success = false;
                    tmp_tip = "payload 的type字段不得为空";
                }

                var key = self.find("input[name=rule-handle-payload-key]").val();
                var target_key = self.find("input[name=rule-handle-payload-target-key]").val();
                if (!key || !target_key) {
                    tmp_success = false;
                    tmp_tip = "payload 的 key 与目标 key 都不能为空";
                }

                payload.type = parseInt(payload_type);
                payload.key = key;
                payload.target_key = target_key;
                payloads.push(payload);
            });


            if (!tmp_success) {
                result.success = false;
                result.data = tmp_tip;
                return result;
            }
               //判断个数是否匹配
            if (secret == '') {
                result.success = false;
                result.data = "请配置 secret";
                return result;
            }

            result.data = {
               secret: secret,
               payload : payloads,
            };

            result.success = true;
            return result;
        },
    };
}(APP));
