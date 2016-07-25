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
            $(document).on('click', '#judge-area .pair .btn-success', _this.addNewCondition);

            //删除输入行
            $(document).on('click', '#judge-area .pair .btn-danger', function (event) {
                $(this).parents('.form-group').remove();//删除本行输入
                _this.resetAddConditionBtn();
            });
        },

        

        //变量提取器增加、删除按钮事件
        initExtractionAddOrRemove: function () {

            //添加规则框里的事件
            //点击“加号“添加新的输入行
            $(document).on('click', '#extractor-area .pair .btn-success', _this.addNewExtraction);

            //删除输入行
            $(document).on('click', '#extractor-area .pair .btn-danger', function (event) {
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
                        $(this).find("input[name=rule-extractor-extraction-default]").show();
                    });
                } else {
                    $(this).parents(".extraction-default-hodler").each(function () {
                        $(this).find("input[name=rule-extractor-extraction-default]").hide();
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
                        $(this).find("input[name=rule-extractor-extraction-default]").hide();
                    });
                }else{
                    $(this).parents(".extraction-holder").each(function () {
                        $(this).find("select[name=rule-extractor-extraction-has-default]").val("0").show();
                        $(this).find("input[name=rule-extractor-extraction-default]").hide();
                    });
                }
            });
        },

        buildJudge: function () {
            var result = {
                success: false,
                data: {
                    name: null,
                    judge: {}
                }
            };
            var name = $("#rule-name").val();
            if (!name) {
                result.success = false;
                result.data = "规则名称不能为空";
                return result;
            }

            result.data.name = name;


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
                    var default_value = self.find("input[name=rule-extractor-extraction-default]").val();
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
                }
                ]
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
                    $(this).find(".btn-success").show();
                    $(this).find(".btn-danger").show();
                } else {
                    $(this).find(".btn-success").hide();
                    $(this).find(".btn-danger").show();
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
                    $(this).find(".btn-success").show();
                    $(this).find(".btn-danger").show();
                } else {
                    $(this).find(".btn-success").hide();
                    $(this).find(".btn-danger").show();
                }
            })
        },

        //数据/表格视图转换和下载事件
        initViewAndDownloadEvent: function (type) {
            var data = {};
            var rules_key = "";
            if (type == "redirect") {
                data = L.Redirect.data;
                rules_key = "rules";
            } else if (type == "rewrite") {
                data = L.Rewrite.data;
                rules_key = "rules";
            } else if (type == "basic_auth") {
                data = L.BasicAuth.data;
                rules_key = "rules";
            } else if (type == "key_auth") {
                data = L.KeyAuth.data;
                rules_key = "rules";
            } else if (type == "waf") {
                data = L.WAF.data;
                rules_key = "rules";
            } else if (type == "divide") {
                data = L.Divide.data;
                rules_key = "rules";
            } else if (type == "monitor") {
                data = L.Monitor.data;
                rules_key = "rules";
            } else {
                return;
            }

            $("#view-btn").click(function () {//试图转换
                var self = $(this);
                var now_state = $(this).attr("data-type");
                if (now_state == "table") {//当前是表格视图，点击切换到数据视图
                    self.attr("data-type", "database");
                    self.find("i").removeClass("fa-database").addClass("fa-table");
                    self.find("span").text("表格视图");

                    var showData = {};
                    showData.enable = data.enable;
                    showData[rules_key] = data.rules;
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
                downloadData[rules_key] = data.rules;
                var blob = new Blob([JSON.stringify(downloadData, null, 4)], {type: "text/plain;charset=utf-8"});
                saveAs(blob, "data.json");
            });

        },

        initSwitchBtn: function (type) {
            var op_type = "";
            if (type == "redirect") {
                op_type = "redirect";
            } else if (type == "rewrite") {
                op_type = "rewrite";
            } else if (type == "basic_auth") {
                op_type = "basic_auth";
            } else if (type == "key_auth") {
                op_type = "key_auth";
            } else if (type == "waf") {
                op_type = "waf";
            } else if (type == "divide") {
                op_type = "divide";
            } else if (type == "monitor") {
                op_type = "monitor";
            } else {
                return;
            }

            $("#switch-btn").click(function () {//是否开启redirect
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
                                            _this.data.enable = false;
                                            self.attr("data-on", "no");
                                            self.removeClass("btn-danger").addClass("btn-info");
                                            self.find("i").removeClass("fa-pause").addClass("fa-play");
                                            self.find("span").text("启用" + op_type);

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
                                            _this.data.enable = true;
                                            //重置按钮
                                            self.attr("data-on", "yes");
                                            self.removeClass("btn-info").addClass("btn-danger");
                                            self.find("i").removeClass("fa-play").addClass("fa-pause");
                                            self.find("span").text("停用" + op_type);

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
            var op_type = "";
            var rules_key = "";
            if (type == "redirect") {
                op_type = "redirect";
                rules_key = "rules";
            } else if (type == "rewrite") {
                op_type = "rewrite";
                rules_key = "rules";
            } else if (type == "basic_auth") {
                op_type = "basic_auth";
                rules_key = "rules";
            }  else if (type == "key_auth") {
                op_type = "key_auth";
                rules_key = "rules";
            }  else if (type == "waf") {
                op_type = "waf";
                rules_key = "rules";
            } else if (type == "divide") {
                op_type = "divide";
                rules_key = "rules";
            } else if (type == "monitor") {
                op_type = "monitor";
                rules_key = "rules";
            } else {
                return;
            }

            $("#add-btn").click(function () {
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
                                    url: '/' + op_type + '/configs',
                                    type: 'put',
                                    cache:false,
                                    data: {
                                        rule: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            //重新渲染规则
                                            context.loadConfigs();
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
            var op_type = "";
            var rules_key = "";
            if (type == "redirect") {
                op_type = "redirect";
                rules_key = "rules";
            } else if (type == "rewrite") {
                op_type = "rewrite";
                rules_key = "rules";
            } else if (type == "basic_auth") {
                op_type = "basic_auth";
                rules_key = "rules";
            } else if (type == "key_auth") {
                op_type = "key_auth";
                rules_key = "rules";
            } else if (type == "waf") {
                op_type = "waf";
                rules_key = "rules";
            } else if (type == "divide") {
                op_type = "divide";
                rules_key = "rules";
            } else if (type == "monitor") {
                op_type = "monitor";
                rules_key = "rules";
            } else {
                return;
            }

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
                                                    context.loadConfigs();
                                                    return true;
                                                } else {
                                                    L.Common.showErrorTip("提示", r.msg || "同步配置发生错误");
                                                    return false;
                                                }
                                            },
                                            error: function () {
                                                L.Common.showErrorTip("提示", "同步配置请求发生异常");
                                                return false;
                                            }
                                        });
                                    }
                                }
                                ]
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
            var op_type = "";
            var rules_key = "";
            if (type == "redirect") {
                op_type = "redirect";
                rules_key = "rules";
            } else if (type == "rewrite") {
                op_type = "rewrite";
                rules_key = "rules";
            } else if (type == "basic_auth") {
                op_type = "basic_auth";
                rules_key = "rules";
            } else if (type == "key_auth") {
                op_type = "key_auth";
                rules_key = "rules";
            } else if (type == "waf") {
                op_type = "waf";
                rules_key = "rules";
            } else if (type == "divide") {
                op_type = "divide";
                rules_key = "rules";
            } else if (type == "monitor") {
                op_type = "monitor";
                rules_key = "rules";
            } else {
                return;
            }

            $(document).on("click", ".edit-btn", function () {
                var tpl = $("#edit-tpl").html();
                var rule_id = $(this).attr("data-id");
                var rule = {};
                var rules = context.data.rules;
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
                                    url: '/' + op_type + '/configs',
                                    type: 'post',
                                    cache:false,
                                    data: {
                                        rule: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function (result) {
                                        if (result.success) {
                                            //重新渲染规则
                                            context.loadConfigs();

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
                d.show();
            });
        },

        initRuleDeleteDialog: function (type, context) {
            var op_type = "";
            var rules_key = "";
            if (type == "redirect") {
                op_type = "redirect";
                rules_key = "rules";
            } else if (type == "rewrite") {
                op_type = "rewrite";
                rules_key = "rules";
            } else if (type == "basic_auth") {
                op_type = "basic_auth";
                rules_key = "rules";
            } else if (type == "key_auth") {
                op_type = "key_auth";
                rules_key = "rules";
            } else if (type == "waf") {
                op_type = "waf";
                rules_key = "rules";
            } else if (type == "divide") {
                op_type = "divide";
                rules_key = "rules";
            } else if (type == "monitor") {
                op_type = "monitor";
                rules_key = "rules";
            } else {
                return;
            }

            $(document).on("click", ".delete-btn", function () {

                var name = $(this).attr("data-name");
                var rule_id = $(this).attr("data-id");
                console.log("删除:" + name);
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
                                url: '/' + op_type + '/configs',
                                type: 'delete',
                                cache:false,
                                data: {
                                    rule_id: rule_id
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        context.loadConfigs();

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
                    }
                    ]
                });

                d.show();
            });
        },

        resetSwitchBtn: function (enable, type) {
            var op_type = "";
            if (type == "redirect") {
                op_type = "redirect";
            } else if (type == "rewrite") {
                op_type = "rewrite";
            } else if (type == "basic_auth") {
                op_type = "basic_auth";
            } else if (type == "key_auth") {
                op_type = "key_auth";
            } else if (type == "waf") {
                op_type = "waf";
            } else if (type == "divide") {
                op_type = "divide";
            } else if (type == "monitor") {
                op_type = "monitor";
            } else {
                return;
            }

            var self = $("#switch-btn");
            if (enable == true) {//当前是开启状态，则应显示“关闭”按钮
                self.attr("data-on", "yes");
                self.removeClass("btn-info").addClass("btn-danger");
                self.find("i").removeClass("fa-play").addClass("fa-pause");
                self.find("span").text("停用" + op_type);
            } else {
                self.attr("data-on", "no");
                self.removeClass("btn-danger").addClass("btn-info");
                self.find("i").removeClass("fa-pause").addClass("fa-play");
                self.find("span").text("启用" + op_type);
            }
        },

        showErrorTip: function (title, content) {
            var d = dialog({
                title: title,
                width: 300,
                content: content,
                modal: true,
                button: [{
                    value: '返回',
                    callback: function () {
                        d.close().remove();
                    }
                }
                ]
            });
            d.show();
        },


        showTipDialog: function (title, content) {
            if (!content) {
                content = title;
                title = "Tips";
            }
            var d = dialog({
                title: title || 'Tips',
                content: content,
                width: 350,
                cancel: false,
                ok: function () {
                }
            });
            d.show();
        },

        resetNav: function (select) {
            $("#main-nav-menu li").each(function () {
                $(this).removeClass("active")
            });

            if (select) {
                $("#main-nav-menu li#" + select).addClass("active");
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
