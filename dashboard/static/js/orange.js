(function (L) {
    var _this = null;
    L.Common = L.Common || {};
    _this = L.Common = {
        data: {},

        init: function () {

        },

        //增加、删除条件按钮事件
        initConditionAddOrRemove: function () {
            //添加规则框里的事件
            //点击“加号“添加新的输入行
            $(document).on('click', '#judge-area .pair .btn-add', _this.addNewCondition);

            //删除输入行
            $(document).on('click', '#judge-area .pair .btn-remove', function (event) {
                $(this).parents('.form-group').remove();//删除本行输入
                _this.resetAddConditionBtn();
            });
        },

        //变量提取器增加、删除按钮事件
        initExtractionAddOrRemove: function () {

            //添加规则框里的事件
            //点击“加号“添加新的输入行
            $(document).on('click', '#extractor-area .pair .btn-add', _this.addNewExtraction);

            //删除输入行
            $(document).on('click', '#extractor-area .pair .btn-remove', function (event) {
                $(this).parents('.form-group').remove();//删除本行输入
                _this.resetAddExtractionBtn();
            });
        },

        initExtractionAddBtnEvent: function () {
            $(document).on('click', '#add-extraction-btn', function () {
                var row;
                var current_es = $('.extraction-holder');
                if (current_es && current_es.length) {
                    row = current_es[current_es.length - 1];
                }
                if (row) {//至少存在了一个提取项
                    var new_row = $(row).clone(true);

                    var old_type = $(row).find("select[name=rule-extractor-extraction-type]").val();
                    $(new_row).find("select[name=rule-extractor-extraction-type]").val(old_type);
                    $(new_row).find("label").text("");

                    $("#extractor-area").append($(new_row));
                } else {//没有任何提取项，从模板创建一个
                    var html = $("#single-extraction-tmpl").html();
                    $("#extractor-area").append(html);
                }

                _this.resetAddExtractionBtn();
            });
        },

        //selector类型选择事件
        initSelectorTypeChangeEvent: function () {
            $(document).on("change", '#selector-type', function () {
                var selector_type = $(this).val();
                if (selector_type == "1") {
                    $("#judge-area").show();
                } else {
                    $("#judge-area").hide();
                }
            });
        },

        //judge类型选择事件
        initJudgeTypeChangeEvent: function () {
            $(document).on("change", '#rule-judge-type', function () {
                var judge_type = $(this).val();
                if (judge_type != "0" && judge_type != "1" && judge_type != "2" && judge_type != "3") {
                    L.Common.showTipDialog("提示", "选择的judge类型不合法");
                    return
                }

                if (judge_type == "3") {
                    $("#expression-area").show();
                } else {
                    $("#expression-area").hide();
                }
            });
        },

        //condition类型选择事件
        initConditionTypeChangeEvent: function () {
            $(document).on("change", 'select[name=rule-judge-condition-type]', function () {
                var condition_type = $(this).val();

                if (condition_type != "Header" && condition_type != "Query" && condition_type != "PostParams") {
                    $(this).parents(".condition-holder").each(function () {
                        $(this).find(".condition-name-hodler").hide();
                    });
                } else {
                    $(this).parents(".condition-holder").each(function () {
                        $(this).find(".condition-name-hodler").show();
                    });
                }
            });
        },

        //提取项是否有默认值选择事件
        initExtractionHasDefaultValueOrNotEvent: function () {
            $(document).on("change", 'select[name=rule-extractor-extraction-has-default]', function () {
                var has_default = $(this).val();

                if (has_default=="1") {
                    $(this).parents(".extraction-default-hodler").each(function () {
                        $(this).find("div[name=rule-extractor-extraction-default]").show();
                    });
                } else {
                    $(this).parents(".extraction-default-hodler").each(function () {
                        $(this).find("div[name=rule-extractor-extraction-default]").hide();
                    });
                }
            });
        },

        initExtractionTypeChangeEvent: function () {
            $(document).on("change", 'select[name=rule-extractor-extraction-type]', function () {
                var extraction_type = $(this).val();

                if (extraction_type != "Header" && extraction_type != "Query"
                    && extraction_type != "PostParams" && extraction_type != "URI") {
                    $(this).parents(".extraction-holder").each(function () {
                        $(this).find(".extraction-name-hodler").hide();
                    });
                } else {
                    $(this).parents(".extraction-holder").each(function () {
                        $(this).find(".extraction-name-hodler").show();
                    });
                }

                //URI类型没有默认值选项
                if(extraction_type=="URI"){
                    $(this).parents(".extraction-holder").each(function () {
                        $(this).find("select[name=rule-extractor-extraction-has-default]").hide();
                        $(this).find("div[name=rule-extractor-extraction-default]").hide();
                    });
                }else{
                    $(this).parents(".extraction-holder").each(function () {
                        $(this).find("select[name=rule-extractor-extraction-has-default]").val("0").show();
                        $(this).find("div[name=rule-extractor-extraction-default]").hide();
                    });
                }
            });
        },

        buildSelector: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    type: 0,
                    judge: {},
                    handle: {}
                }
            };

            // build name
            var name = $("#selector-name").val();
            if (!name) {
                result.success = false;
                result.data = "名称不能为空";
                return result;
            }
            result.data.name = name;

            // build type
            var type = $("#selector-type").val();
            if (!type) {
                result.success = false;
                result.data = "类型不能为空";
                return result;
            }
            result.data.type = parseInt(type);

            //build judge
            if(type==1){
                var buildJudgeResult = L.Common.buildJudge(true);
                if (buildJudgeResult.success == true) {
                    result.data.judge = buildJudgeResult.data.judge;
                } else {
                    result.success = false;
                    result.data = buildJudgeResult.data;
                    return result;
                }
            }

            //build handle
            result.data.handle.continue = ($("#selector-continue").val() === "true");
            result.data.handle.log = ($("#selector-log").val() === "true");

            //enable or not
            var enable = $('#selector-enable').is(':checked');
            result.data.enable = enable;

            result.success = true;
            return result;
        },

        buildName:function()
        {
            var result = {
                success: false,
                data: {
                    name: {}
                }
            };

            var name = $("#rule-name").val();
            if (!name) {
                result.data = "规则名称不能为空";
                return result;
            }

            result.data.name = name;
            result.success = true;
            return result;
        },

        buildJudge: function (ignore_name) {
            var result = {
                success: false,
                data: {
                    judge: {}
                }
            };

            if(ignore_name != true) {
                var temp_result = L.Common.buildName();
                if(!temp_result.success){
                    return temp_result;
                }else{
                    result.data.name = temp_result.data.name
                }
            }

            var judge_type = parseInt($("#rule-judge-type").val());
            result.data.judge.type = judge_type;

            if (judge_type == 3) {
                var judge_expression = $("#rule-judge-expression").val();
                if (!judge_expression) {
                    result.success = false;
                    result.data = "复杂匹配的规则表达式不得为空";
                    return result;
                }
                result.data.judge.expression = judge_expression;
            }

            var judge_conditions = [];

            var tmp_success = true;
            var tmp_tip = "";
            $(".condition-holder").each(function () {
                var self = $(this);
                var condition = {};
                var condition_type = self.find("select[name=rule-judge-condition-type]").val();
                condition.type = condition_type;

                if (condition_type == "Header" || condition_type == "Query" || condition_type == "PostParams") {
                    var condition_name = self.find("input[name=rule-judge-condition-name]").val();
                    if (!condition_name) {
                        tmp_success = false;
                        tmp_tip = "condition的name字段不得为空";
                    }

                    condition.name = condition_name;
                }

                condition.operator = self.find("select[name=rule-judge-condition-operator]").val();
                condition.value = self.find("input[name=rule-judge-condition-value]").val() || "";

                judge_conditions.push(condition);
            });

            if (!tmp_success) {
                result.success = false;
                result.data = tmp_tip;
                return result;
            }
            result.data.judge.conditions = judge_conditions;

            //判断规则类型和条件个数是否匹配
            if (result.data.judge.conditions.length < 1) {
                result.success = false;
                result.data = "请配置规则条件";
                return result;
            }
            if (result.data.judge.type == 0 && result.data.judge.conditions.length != 1) {
                result.success = false;
                result.data = "单一条件匹配模式只能有一条condition，请删除多余配置";
                return result;
            }
            if (result.data.judge.type == 3) {//判断条件表达式与条件个数等
                try {
                    var condition_count = result.data.judge.conditions.length;
                    var regrex1 = /(v\[[0-9]+\])/g;
                    var regrex2 = /([0-9]+)/g;
                    var expression_v_array = [];// 提取条件变量
                    expression_v_array = result.data.judge.expression.match(regrex1);
                    if (!expression_v_array || expression_v_array.length < 1) {
                        result.success = false;
                        result.data = "规则表达式格式错误，请检查";
                        return result;
                    }

                    var expression_v_array_len = expression_v_array.length;
                    var max_v_index = 1;
                    for (var i = 0; i < expression_v_array_len; i++) {
                        var expression_v = expression_v_array[i];
                        var index_array = expression_v.match(regrex2);
                        if (!index_array || index_array.length < 1) {
                            result.success = false;
                            result.data = "规则表达式中条件变量格式错误，请检查";
                            return result;
                        }

                        var var_index = parseInt(index_array[0]);
                        if (var_index > max_v_index) {
                            max_v_index = var_index;
                        }
                    }

                    if (condition_count < max_v_index) {
                        result.success = false;
                        result.data = "规则表达式中的变量最大索引[" + max_v_index + "]与条件个数[" + condition_count + "]不相符，请检查";
                        return result;
                    }
                } catch (e) {
                    result.success = false;
                    result.data = "条件表达式验证发生异常:" + e;
                    return result;
                }
            }

            result.success = true;
            return result;
        },

        buildExtractor: function () {
            var result = {
                success: false,
                data: {
                    extractor: {}
                }
            };

            //提取器类型
            var extractor_type = $("#rule-extractor-type").val();
            try{
                extractor_type = parseInt(extractor_type);
                if(!extractor_type || extractor_type != 2){
                    extractor_type = 1;
                }
            }catch(e){
                extractor_type = 1;
            }


            //提取项
            var extractions = [];
            var tmp_success = true;
            var tmp_tip = "";
            $(".extraction-holder").each(function () {
                var self = $(this);
                var extraction = {};
                var type = self.find("select[name=rule-extractor-extraction-type]").val();
                extraction.type = type;

                //如果允许子key则提取
                if (type == "Header" || type == "Query" || type == "PostParams"|| type == "URI") {
                    var name = self.find("input[name=rule-extractor-extraction-name]").val();
                    if (!name) {
                        tmp_success = false;
                        tmp_tip = "变量提取项的name字段不得为空";
                    }
                    extraction.name = name;
                }

                //如果允许默认值则提取
                var allow_default = (type == "Header" || type == "Query" || type == "PostParams"|| type == "Host"|| type == "IP"|| type == "Method");
                var has_default = self.find("select[name=rule-extractor-extraction-has-default]").val();
                if (allow_default && has_default=="1") {//只有允许提取&&有默认值的才取默认值
                    var default_value = self.find("div[name=rule-extractor-extraction-default]>input").val();
                    if (!default_value) {
                        default_value = "";
                    }
                    extraction.default = default_value;
                }

                extractions.push(extraction);
            });

            if (!tmp_success) {
                result.success = false;
                result.data = tmp_tip;
                return result;
            }

            result.data.extractor.type = extractor_type;
            result.data.extractor.extractions = extractions;
            result.success = true;
            return result;
        },

        showRulePreview: function (rule) {
            var content = "";

            if (rule.success == true) {
                content = '<pre id="preview_rule"><code></code></pre>';
            } else {
                content = rule.data;
            }

            var d = dialog({
                title: '规则预览',
                width: 500,
                content: content,
                modal: true,
                button: [{
                    value: '返回',
                    callback: function () {
                        d.close().remove();
                    }
                }]
            });
            d.show();

            $("#preview_rule code").text(JSON.stringify(rule.data, null, 2));
            $('pre code').each(function () {
                hljs.highlightBlock($(this)[0]);
            });
        },

        addNewCondition: function (event) {
            var self = $(this);
            var row = self.parents('.condition-holder');
            var new_row = row.clone(true);
            // $(new_row).find("input[name=rule-judge-condition-value]").val("");
            // $(new_row).find("input[name=rule-judge-condition-name]").val("");

            var old_type = $(row).find("select[name=rule-judge-condition-type]").val();
            $(new_row).find("select[name=rule-judge-condition-type]").val(old_type);

            var old_operator = $(row).find("select[name=rule-judge-condition-operator]").val();
            $(new_row).find("select[name=rule-judge-condition-operator]").val(old_operator);

            $(new_row).insertAfter($(this).parents('.condition-holder'))
            _this.resetAddConditionBtn();
        },

        resetAddConditionBtn: function () {
            var l = $("#judge-area .pair").length;
            var c = 0;
            $("#judge-area .pair").each(function () {
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


        addNewExtraction: function (event) {
            var self = $(this);
            var row = self.parents('.extraction-holder');
            var new_row = row.clone(true);

            var old_type = $(row).find("select[name=rule-extractor-extraction-type]").val();
            $(new_row).find("select[name=rule-extractor-extraction-type]").val(old_type);

            var old_has_default_value = $(row).find("select[name=rule-extractor-extraction-has-default]").val();
            $(new_row).find("select[name=rule-extractor-extraction-has-default]").val(old_has_default_value);
            if(old_has_default_value=="1"){
                $(new_row).find("input[name=rule-extractor-extraction-default]").show().val("");
            }else{
                $(new_row).find("input[name=rule-extractor-extraction-default]").hide();
            }

            if(old_type=="URI"){//如果拷贝的是URI类型，则不显示default
                $(new_row).find("input[name=rule-extractor-extraction-default]").hide();
                $(new_row).find("select[name=rule-extractor-extraction-has-default]").hide();
            }

            $(new_row).find("label").text("");

            $(new_row).insertAfter($(this).parents('.extraction-holder'))
            _this.resetAddExtractionBtn();
        },

        resetAddExtractionBtn: function () {
            var l = $("#extractor-area .pair").length;
            var c = 0;
            $("#extractor-area .pair").each(function () {
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

        //数据/表格视图转换和下载事件
        initViewAndDownloadEvent: function (type, context) {
            var data = context.data;

            $("#view-btn").click(function () {//试图转换
                var self = $(this);
                var now_state = $(this).attr("data-type");
                if (now_state == "table") {//当前是表格视图，点击切换到数据视图
                    self.attr("data-type", "database");
                    self.find("i").removeClass("fa-database").addClass("fa-table");
                    self.find("span").text("表格视图");

                    var showData = {};
                    showData.enable = data.enable;
                    showData.selectors = data.selectors;
                    jsonformat.format(JSON.stringify(showData));
                    $("#jfContent_pre").text(JSON.stringify(showData, null, 4));
                    $('pre').each(function () {
                        hljs.highlightBlock($(this)[0]);
                    });
                    $("#table-view").hide();
                    $("#database-view").show();
                } else {
                    self.attr("data-type", "table");
                    self.find("i").removeClass("fa-table").addClass("fa-database");
                    self.find("span").text("数据视图");

                    $("#database-view").hide();
                    $("#table-view").show();
                }
            });

            $(document).on("click", "#btnDownload", function () {//规则json下载
                var downloadData = {};
                downloadData.enable = data.enable;
                downloadData.selectors = data.selectors;
                var blob = new Blob([JSON.stringify(downloadData, null, 4)], {type: "text/plain;charset=utf-8"});
                saveAs(blob, "data.json");
            });

        },

        initSwitchBtn: function (type, context) {
            var op_type = type;

            $("#switch-btn").click(function () {//是否开启
                var self = $(this);
                var now_state = $(this).attr("data-on");
                if (now_state == "yes") {//当前是开启状态，点击则“关闭”
                    var d = dialog({
                        title: op_type + '设置',
                        width: 300,
                        content: "确定要关闭" + op_type + "吗？",
                        modal: true,
                        button: [{
                            value: '取消'
                        }, {
                            value: '确定',
                            autofocus: false,
                            callback: function () {
                                $.ajax({
                                    url: '/' + op_type + '/enable',
                                    type: 'post',
                                    cache:false,
                                    data: {
                                        enable: "0"
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            //重置按钮
                                            context.data.enable = false;
                                            self.attr("data-on", "no");
                                            self.removeClass("btn-danger").addClass("btn-info");
                                            self.find("i").removeClass("fa-pause").addClass("fa-play");
                                            self.find("span").text("启用该插件");

                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "关闭" + op_type + "发生错误");
                                            return false;
                                        }
                                    },
                                    error: function () {
                                        L.Common.showErrorTip("提示", "关闭" + op_type + "请求发生异常");
                                        return false;
                                    }
                                });
                            }
                        }
                        ]
                    });
                    d.show();


                } else {
                    var d = dialog({
                        title: op_type + '设置',
                        width: 300,
                        content: "确定要开启" + op_type + "吗？",
                        modal: true,
                        button: [{
                            value: '取消'
                        }, {
                            value: '确定',
                            autofocus: false,
                            callback: function () {
                                $.ajax({
                                    url: '/' + op_type + '/enable',
                                    type: 'post',
                                    cache:false,
                                    data: {
                                        enable: "1"
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            context.data.enable = true;
                                            //重置按钮
                                            self.attr("data-on", "yes");
                                            self.removeClass("btn-info").addClass("btn-danger");
                                            self.find("i").removeClass("fa-play").addClass("fa-pause");
                                            self.find("span").text("停用该插件");

                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "开启" + op_type + "发生错误");
                                            return false;
                                        }
                                    },
                                    error: function () {
                                        L.Common.showErrorTip("提示", "开启" + op_type + "请求发生异常");
                                        return false;
                                    }
                                });
                            }
                        }
                        ]
                    });
                    d.show();
                }
            });
        },

        initRuleAddDialog: function (type, context) {
            var op_type = type;
            var rules_key = "rules";


            $("#add-btn").click(function () {
                var selector_id = $("#add-btn").attr("data-id");
                if(!selector_id){
                    L.Common.showErrorTip("错误提示", "添加规则前请先选择【选择器】!");
                    return;
                }
                var content = $("#add-tpl").html()
                var d = dialog({
                    title: '添加规则',
                    width: 720,
                    content: content,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '预览',
                        autofocus: false,
                        callback: function () {
                            var rule = context.buildRule();
                            L.Common.showRulePreview(rule);
                            return false;
                        }
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function () {
                            var result = context.buildRule();
                            if (result.success == true) {
                                $.ajax({
                                    url: '/' + op_type + '/selectors/' + selector_id + "/rules",
                                    type: 'post',
                                    data: {
                                        rule: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            //重新渲染规则
                                            _this.loadRules(op_type, context, selector_id);
                                            _this.refreshConfigs(op_type, context);
                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "添加规则发生错误");
                                            return false;
                                        }
                                    },
                                    error: function () {
                                        L.Common.showErrorTip("提示", "添加规则请求发生异常");
                                        return false;
                                    }
                                });

                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }
                        }
                    }
                    ]
                });
                L.Common.resetAddConditionBtn();//删除增加按钮显示与否
                d.show();
            });
        },

        initSyncDialog: function (type, context) {
            var op_type = type;
            var rules_key = "rules";

            $("#sync-btn").click(function () {
                $.ajax({
                    url: '/' + op_type + '/fetch_config',
                    type: 'get',
                    cache:false,
                    data: {},
                    dataType: 'json',
                    success: function (result) {
                        if (result.success) {
                            var d = dialog({
                                title: '确定要从存储中同步配置吗?',
                                width: 680,
                                content: '<pre id="preview_plugin_config"><code></code></pre>',
                                modal: true,
                                button: [{
                                    value: '取消'
                                }, {
                                    value: '确定同步',
                                    autofocus: false,
                                    callback: function () {
                                        $.ajax({
                                            url: '/' + op_type + '/sync',
                                            type: 'post',
                                            cache:false,
                                            data: {},
                                            dataType: 'json',
                                            success: function (r) {
                                                if (r.success) {
                                                    _this.loadConfigs(op_type, context);
                                                    return true;
                                                } else {
                                                    _this.showErrorTip("提示", r.msg || "同步配置发生错误");
                                                    return false;
                                                }
                                            },
                                            error: function () {
                                                _this.showErrorTip("提示", "同步配置请求发生异常");
                                                return false;
                                            }
                                        });
                                    }
                                }]
                            });
                            d.show();

                            $("#preview_plugin_config code").text(JSON.stringify(result.data, null, 2));
                            $('pre code').each(function () {
                                hljs.highlightBlock($(this)[0]);
                            });
                        } else {
                            L.Common.showErrorTip("提示", result.msg || "从存储中获取该插件配置发生错误");
                            return;
                        }
                    },
                    error: function () {
                        L.Common.showErrorTip("提示", "从存储中获取该插件配置请求发生异常");
                        return false;
                    }
                });

            });
        },

        initRuleEditDialog: function (type, context) {
            var op_type = type;

            $(document).on("click", ".edit-btn", function () {
                var selector_id = $("#add-btn").attr("data-id");

                var tpl = $("#edit-tpl").html();
                var rule_id = $(this).attr("data-id");
                var rule = {};
                var rules = context.data.selector_rules[selector_id];
                for (var i = 0; i < rules.length; i++) {
                    var r = rules[i];
                    if (r.id == rule_id) {
                        rule = r;
                        break;
                    }
                }
                if (!rule_id || !rule) {
                    L.Common.showErrorTip("提示", "要编辑的规则不存在或者查找出错");
                    return;
                }

                var html = juicer(tpl, {
                    r: rule
                });

                var d = dialog({
                    title: "编辑规则",
                    width: 680,
                    content: html,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '预览',
                        autofocus: false,
                        callback: function () {
                            var rule = context.buildRule();
                            L.Common.showRulePreview(rule);
                            return false;
                        }
                    }, {
                        value: '保存修改',
                        autofocus: false,
                        callback: function () {
                            var result = context.buildRule();
                            result.data.id = rule.id;//拼上要修改的id

                            if (result.success == true) {
                                $.ajax({
                                    url: '/' + op_type + '/selectors/' + selector_id + "/rules",
                                    type: 'put',
                                    data: {
                                        rule: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            //重新渲染规则
                                            _this.loadRules(op_type, context, selector_id);
                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "编辑规则发生错误");
                                            return false;
                                        }
                                    },
                                    error: function () {
                                        L.Common.showErrorTip("提示", "编辑规则请求发生异常");
                                        return false;
                                    }
                                });

                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }
                        }
                    }
                    ]
                });

                L.Common.resetAddConditionBtn();//删除增加按钮显示与否
                L.Common.resetAddExtractionBtn();
                context.resetAddCredentialBtn && context.resetAddCredentialBtn();
                d.show();
            });
        },

        initRuleDeleteDialog: function (type, context) {
            var op_type = type;

            $(document).on("click", ".delete-btn", function () {
                var name = $(this).attr("data-name");
                var rule_id = $(this).attr("data-id");
                var selector_id = $("#add-btn").attr("data-id");

                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除规则【" + name + "】吗？",
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function () {
                            $.ajax({
                                url: '/' + op_type + '/selectors/' + selector_id + "/rules",
                                type: 'delete',
                                data: {
                                    rule_id: rule_id
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.loadRules(op_type, context, selector_id);
                                        _this.refreshConfigs(op_type, context);//刷新本地缓存
                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除规则发生错误");
                                        return false;
                                    }
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "删除规则请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });

                d.show();
            });
        },

        initRuleSortEvent: function (type, context){
            var op_type = type;
            $(document).on("click", "#rule-sort-btn", function () {
                var new_order = [];
                if($("#rules li")){
                    $("#rules li").each(function(item){
                        new_order.push($(this).attr("data-id"));
                    });
                }

                var new_order_str = new_order.join(",");
                if(!new_order_str||new_order_str==""){
                    L.Common.showErrorTip("提示", "规则列表为空， 无需排序");
                    return;
                }

                var selector_id = $("#add-btn").attr("data-id");
                if(!selector_id || selector_id==""){
                    L.Common.showErrorTip("提示", "操作异常， 未选中选择器， 无法排序");
                    return;
                }

                var d = dialog({
                    title: "提示",
                    content: "确定要保存新的规则顺序吗？",
                    width: 350,
                    modal: true,
                    cancel: function(){},
                    cancelValue: "取消",
                    okValue: "确定",
                    ok: function () {
                        $.ajax({
                            url: '/' + op_type + '/selectors/' +selector_id + '/rules/order',
                            type: 'put',
                            data: {
                                order: new_order_str
                            },
                            dataType: 'json',
                            success: function (result) {
                                if (result.success) {
                                    //重新渲染规则
                                    _this.loadRules(op_type, context, selector_id);
                                    return true;
                                } else {
                                    L.Common.showErrorTip("提示", result.msg || "保存排序发生错误");
                                    return false;
                                }
                            },
                            error: function () {
                                L.Common.showErrorTip("提示", "保存排序请求发生异常");
                                return false;
                            }
                        });
                    }
                });
                d.show();
            });
        },

        initSelectorAddDialog: function (type, context) {
            var op_type = type;
            $("#add-selector-btn").click(function () {
                var current_selected_id;
                var current_selected_selector = $("#selector-list li.selected-selector");
                if(current_selected_selector){
                    current_selected_id = $(current_selected_selector[0]).attr("data-id");
                }

                var content = $("#add-selector-tpl").html()
                var d = dialog({
                    title: '添加选择器',
                    width: 720,
                    content: content,
                    modal: true,
                    button: [{
                        value: '取消'
                    },{
                        value: '确定',
                        autofocus: false,
                        callback: function () {
                            var result = _this.buildSelector();
                            console.log(result);
                            if (result.success) {
                                $.ajax({
                                    url: '/' + op_type + '/selectors',
                                    type: 'post',
                                    data: {
                                        selector: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            //重新渲染
                                            _this.loadConfigs(op_type, context, false, function(){
                                                $("#selector-list li[data-id=" + current_selected_id+"]").addClass("selected-selector");
                                            });
                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "添加选择器发生错误");
                                            return false;
                                        }
                                    },
                                    error: function () {
                                        L.Common.showErrorTip("提示", "添加选择器请求发生异常");
                                        return false;
                                    }
                                });

                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }
                        }
                    }
                    ]
                });
                L.Common.resetAddConditionBtn();//删除增加按钮显示与否
                d.show();
            });
        },

        initSelectorDeleteDialog: function (type, context) {
            var op_type = type;
            $(document).on("click", ".delete-selector-btn", function (e) {
                e.stopPropagation();// 阻止冒泡
                var name = $(this).attr("data-name");
                var selector_id = $(this).attr("data-id");
                if(!selector_id){
                    L.Common.showErrorTip("提示", "参数错误，要删除的选择器不存在！");
                    return;
                }

                var current_selected_id;
                var current_selected_selector = $("#selector-list li.selected-selector");
                if(current_selected_selector){
                    current_selected_id = $(current_selected_selector[0]).attr("data-id");
                }

                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除选择器【" + name + "】吗? 删除选择器将同时删除它的所有规则!",
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function () {
                            $.ajax({
                                url: '/' + op_type + '/selectors',
                                type: 'delete',
                                data: {
                                    selector_id: selector_id
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.loadConfigs(op_type, context, false, function(){
                                            //删除的是原先选中的选择器, 重新选中第一个
                                            if(current_selected_id == selector_id){
                                                var selector_list = $("#selector-list li");
                                                if(selector_list && selector_list.length>0){
                                                    $(selector_list[0]).click();
                                                }else{
                                                    _this.emptyRules();
                                                }
                                            }else{
                                                if(current_selected_id){
                                                    $("#selector-list li[data-id=" + current_selected_id+"]").addClass("selected-selector");
                                                }else{
                                                    _this.emptyRules();
                                                }
                                            }
                                        });

                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除选择器发生错误");
                                        return false;
                                    }
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "删除选择器请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }
                    ]
                });

                d.show();
            });
        },

        initSelectorEditDialog: function(type, context){
            var op_type = type;

            $(document).on("click", ".edit-selector-btn", function (e) {
                e.stopPropagation();// 阻止冒泡
                var tpl = $("#edit-selector-tpl").html();
                var selector_id = $(this).attr("data-id");
                var selectors = context.data.selectors;
                selector = selectors[selector_id];
                if (!selector_id || !selector) {
                    L.Common.showErrorTip("提示", "要编辑的选择器不存在或者查找出错");
                    return;
                }

                var html = juicer(tpl, {
                    s: selector
                });

                var d = dialog({
                    title: "编辑选择器",
                    width: 680,
                    content: html,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '预览',
                        autofocus: false,
                        callback: function () {
                            var s = _this.buildSelector();
                            L.Common.showRulePreview(s);
                            return false;
                        }
                    }, {
                        value: '保存修改',
                        autofocus: false,
                        callback: function () {
                            var result = _this.buildSelector();
                            result.data.id = selector.id;//拼上要修改的id
                            result.data.rules = selector.rules;//拼上已有的rules

                            if (result.success == true) {
                                $.ajax({
                                    url: '/' + op_type + '/selectors',
                                    type: 'put',
                                    data: {
                                        selector: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            //重新渲染规则
                                            _this.loadConfigs(op_type, context);
                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "编辑选择器发生错误");
                                            return false;
                                        }
                                    },
                                    error: function () {
                                        L.Common.showErrorTip("提示", "编辑选择器请求发生异常");
                                        return false;
                                    }
                                });

                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }
                        }
                    }
                    ]
                });

                L.Common.resetAddConditionBtn();//删除增加按钮显示与否
                L.Common.resetAddExtractionBtn();
                d.show();
            });
        },

        initSelectorSortEvent: function (type, context){
            var op_type = type;
            $(document).on("click", "#selector-sort-btn", function () {
                var new_order = [];
                if($("#selector-list li")){
                    $("#selector-list li").each(function(item){
                        new_order.push($(this).attr("data-id"));
                    });
                }

                var new_order_str = new_order.join(",");
                if(!new_order_str||new_order_str==""){
                    L.Common.showErrorTip("提示", "选择器列表为空， 无需排序");
                    return;
                }

                var current_selected_id;
                var current_selected_selector = $("#selector-list li.selected-selector");
                if(current_selected_selector){
                    current_selected_id = $(current_selected_selector[0]).attr("data-id");
                }

                var d = dialog({
                    title: "提示",
                    content: "确定要保存新的选择器顺序吗？",
                    width: 350,
                    modal: true,
                    cancel: function(){},
                    cancelValue: "取消",
                    okValue: "确定",
                    ok: function () {
                        $.ajax({
                            url: '/' + op_type + '/selectors/order',
                            type: 'put',
                            data: {
                                order: new_order_str
                            },
                            dataType: 'json',
                            success: function (result) {
                                if (result.success) {
                                    //重新渲染规则
                                    _this.loadConfigs(op_type, context, false, function(){
                                        if(current_selected_id){//高亮原来选中的li
                                            $("#selector-list li[data-id=" + current_selected_id+"]").addClass("selected-selector");
                                        }
                                    });
                                    return true;
                                } else {
                                    L.Common.showErrorTip("提示", result.msg || "保存排序发生错误");
                                    return false;
                                }
                            },
                            error: function () {
                                L.Common.showErrorTip("提示", "保存排序请求发生异常");
                                return false;
                            }
                        });
                    }
                });
                d.show();
            });
        },

        initSelectorClickEvent: function (type, context){
            var op_type = type;
            $(document).on("click", ".selector-item", function () {
                var self = $(this);
                var selector_id = self.attr("data-id");
                var selector_name = self.attr("data-name");
                if(selector_name){
                    $("#rules-section-header").text("选择器【" + selector_name + "】规则列表");
                }

                $(".selector-item").each(function(){
                    $(this).removeClass("selected-selector");
                })
                self.addClass("selected-selector");

                $("#add-btn").attr("data-id", selector_id);
                _this.loadRules(op_type, context, selector_id);
            });
        },

        resetSwitchBtn: function (enable, type) {
            var op_type = type;

            var self = $("#switch-btn");
            if (enable == true) {//当前是开启状态，则应显示“关闭”按钮
                self.attr("data-on", "yes");
                self.removeClass("btn-info").addClass("btn-danger");
                self.find("i").removeClass("fa-play").addClass("fa-pause");
                self.find("span").text("停用该插件");
            } else {
                self.attr("data-on", "no");
                self.removeClass("btn-danger").addClass("btn-info");
                self.find("i").removeClass("fa-pause").addClass("fa-play");
                self.find("span").text("启用该插件");
            }
        },

        loadConfigs: function (type, context, page_load, callback) {
            var op_type = type;
            $.ajax({
                url: '/' + op_type + '/selectors',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        _this.resetSwitchBtn(result.data.enable, op_type);
                        $("#switch-btn").show();
                        $("#view-btn").show();

                        var enable = result.data.enable;
                        var meta = result.data.meta;
                        var selectors = result.data.selectors;

                        //重新设置数据
                        context.data.enable = enable;
                        context.data.meta = meta;
                        context.data.selectors = selectors;

                        _this.renderSelectors(meta, selectors);

                        if(page_load){//第一次加载页面
                            var selector_lis = $("#selector-list li");
                            if(selector_lis && selector_lis.length>0){
                                $(selector_lis[0]).click();
                            }
                        }

                        callback && callback();
                    } else {
                        _this.showErrorTip("错误提示", "查询" + op_type + "配置请求发生错误");
                    }
                },
                error: function () {
                    _this.showErrorTip("提示", "查询" + op_type + "配置请求发生异常");
                }
            });
        },

        refreshConfigs: function (type, context) {//刷新本地缓存，fix  issue #110 (https://github.com/sumory/orange/issues/110)
            var op_type = type;
            $.ajax({
                url: '/' + op_type + '/selectors',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        var enable = result.data.enable;
                        var meta = result.data.meta;
                        var selectors = result.data.selectors;

                        //重新设置数据
                        context.data.enable = enable;
                        context.data.meta = meta;
                        context.data.selectors = selectors;
                    } else {
                        _this.showErrorTip("错误提示", "刷新" + op_type + "配置的本地缓存发生错误， 请刷新页面！");
                    }
                },
                error: function () {
                    _this.showErrorTip("提示", "查询" + op_type + "配置的本地缓存发生异常， 请刷新页面！");
                }
            });
        },

        loadRules: function (type, context, selector_id) {
            var op_type = type;
            $.ajax({
                url: '/' + op_type + '/selectors/' + selector_id + "/rules",
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        $("#switch-btn").show();
                        $("#view-btn").show();

                        //重新设置数据
                        context.data.selector_rules = context.data.selector_rules || {};
                        context.data.selector_rules[selector_id] = result.data.rules;
                        context.renderRulesCallback && context.renderRulesCallback(result.data.rules);
                        _this.renderRules(result.data);
                    } else {
                        _this.showErrorTip("错误提示", "查询" + op_type + "规则发生错误");
                    }
                },
                error: function () {
                    _this.showErrorTip("提示", "查询" + op_type + "规则发生异常");
                }
            });
        },

        emptyRules: function(){
            $("#rules-section-header").text("选择器-规则列表");
            $("#rules").html("");
            $("#add-btn").removeAttr("data-id");
        },

        renderSelectors: function(meta, selectors){
            var tpl = $("#selector-item-tpl").html();
            var to_render_selectors = [];
            if(meta && selectors){
                var to_render_ids = meta.selectors;
                if(to_render_ids){
                    for(var i = 0; i < to_render_ids.length; i++){
                        if(selectors[to_render_ids[i]]){
                            to_render_selectors.push(selectors[to_render_ids[i]]);
                        }
                    }
                }
            }

            var html = juicer(tpl, {
                selectors: to_render_selectors
            });
            $("#selector-list").html(html);
        },

        renderRules: function (data) {
            data = data || {};
            if(!data.rules || data.rules.length<1){
                var html = '<div class="alert alert-warning" style="margin: 25px 0 10px 0;">'+
                        '<p>该选择器下没有规则,请添加!</p>'+
                '</div>';
                $("#rules").html(html);
            }else{
                var tpl = $("#rule-item-tpl").html();
                var html = juicer(tpl, data);
                $("#rules").html(html);
            }
        },

        showErrorTip: function (title, content) {
            toastr.options = {
              "closeButton": true,
              "debug": false,
              "progressBar": true,
              "positionClass": "toast-top-right",
              "onclick": null,
              "showDuration": "400",
              "hideDuration": "10000",
              "timeOut": "7000",
              "extendedTimeOut": "10000",
              "showEasing": "swing",
              "hideEasing": "linear",
              "showMethod": "fadeIn",
              "hideMethod": "fadeOut"
            }
            toastr.error(content,title || "错误提示");
        },

        showTipDialog: function (title, content) {
            toastr.options = {
              "closeButton": true,
              "debug": false,
              "progressBar": true,
              "positionClass": "toast-top-right",
              "onclick": null,
              "showDuration": "400",
              "hideDuration": "3000",
              "timeOut": "7000",
              "extendedTimeOut": "3000",
              "showEasing": "swing",
              "hideEasing": "linear",
              "showMethod": "fadeIn",
              "hideMethod": "fadeOut"
            }
            toastr.success(content, title || "提示");
        },

        resetNav: function (select) {
            $("#side-menu li").each(function () {
                $(this).removeClass("active")
            });

            if (select) {
                $("#side-menu li#" + select).addClass("active");
            }
        },

        formatDate: function (now) {
            now = now || new Date();
            var year = now.getFullYear();
            var month = now.getMonth() + 1;
            var date = now.getDate();
            var hour = now.getHours();
            var minute = now.getMinutes();
            var second = now.getSeconds();
            if (minute < 10) minute = "0" + minute;
            if (hour < 10) hour = "0" + hour;
            if (second < 10) second = "0" + second;
            return year + "-" + month + "-" + date + " " + hour + ":" + minute + ":" + second;
        },

        formatTime: function (now) {
            now = now || new Date();
            var hour = now.getHours();
            var minute = now.getMinutes();
            var second = now.getSeconds();
            if (minute < 10) minute = "0" + minute;
            if (hour < 10) hour = "0" + hour;
            if (second < 10) second = "0" + second;
            return hour + ":" + minute + ":" + second;
        }

    };
}(APP));
