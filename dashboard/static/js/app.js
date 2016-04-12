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

        initExtractionAddBtnEvent: function(){
            $(document).on('click', '#add-extraction-btn', function(){
                var row;
                var current_es =  $('.extraction-holder');
                if(current_es && current_es.length) {
                    row = current_es[current_es.length-1];
                }
                if(row){//至少存在了一个提取项
                    var new_row = $(row).clone(true);

                    var old_type = $(row).find("select[name=rule-extractor-extraction-type]").val();
                    $(new_row).find("select[name=rule-extractor-extraction-type]").val(old_type);
                    $(new_row).find("label").text("");

                    $("#extractor-area").append( $(new_row));
                }else{//没有任何提取项，从模板创建一个
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

        initExtractionTypeChangeEvent: function () {
            $(document).on("change", 'select[name=rule-extractor-extraction-type]', function () {
                var extraction_type = $(this).val();

                if (extraction_type != "Header" && extraction_type != "Query" && extraction_type != "PostParams") {
                    $(this).parents(".extraction-holder").each(function () {
                        $(this).find(".extraction-name-hodler").hide();
                    });
                } else {
                    $(this).parents(".extraction-holder").each(function () {
                        $(this).find(".extraction-name-hodler").show();
                    });
                }
            });
        },

        buildJudge: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    judge:{}
                }
            };
            var name = $("#rule-name").val();
            if(!name){
                result.success = false;
                result.data = "规则名称不能为空";
                return result;
            }

            result.data.name = name;

            

            var judge_type = parseInt($("#rule-judge-type").val());
            result.data.judge.type = judge_type;

            if(judge_type == 3){
                var judge_expression = $("#rule-judge-expression").val();
                if(!judge_expression){
                    result.success = false;
                    result.data = "复杂匹配的规则表达式不得为空";
                    return result;
                }
                result.data.judge.expression = judge_expression;
            }

            var judge_conditions = [];

            var tmp_success = true;
            var tmp_tip = "";
            $(".condition-holder").each(function(){
                var self = $(this);
                var condition = {};
                var condition_type = self.find("select[name=rule-judge-condition-type]").val();
                condition.type = condition_type;

                if(condition_type == "Header" || condition_type == "Query" || condition_type == "PostParams"){
                    var condition_name = self.find("input[name=rule-judge-condition-name]").val();
                    if(!condition_name){
                        tmp_success = false;
                        tmp_tip = "condition的name字段不得为空";
                    }

                    condition.name = condition_name;
                }

                condition.operator = self.find("select[name=rule-judge-condition-operator]").val();
                condition.value = self.find("input[name=rule-judge-condition-value]").val() || "";

                judge_conditions.push(condition);
            });

            if(!tmp_success){
                result.success = false;
                result.data = tmp_tip;
                return result;
            }
            result.data.judge.conditions = judge_conditions;

            //判断规则类型和条件个数是否匹配
            if(result.data.judge.conditions.length<1){
                result.success = false;
                result.data = "请配置规则条件";
                return result;
            }
            if(result.data.judge.type==0 && result.data.judge.conditions.length!=1){
                result.success = false;
                result.data = "单一条件匹配模式只能有一条condition，请删除多余配置";
                return result;
            }
            if(result.data.judge.type==3){//判断条件表达式与条件个数等
                try{
                    var condition_count = result.data.judge.conditions.length;
                    var regrex1 = /(v\[[0-9]+\])/g;
                    var regrex2 = /([0-9]+)/g;
                    var expression_v_array = [];// 提取条件变量
                    expression_v_array = result.data.judge.expression.match(regrex1);
                    if(!expression_v_array || expression_v_array.length<1){
                        result.success = false;
                        result.data = "规则表达式格式错误，请检查";
                        return result;
                    }

                    var expression_v_array_len = expression_v_array.length;
                    var max_v_index = 1;
                    for(var i = 0; i<expression_v_array_len; i++){
                        var expression_v = expression_v_array[i];
                        var index_array = expression_v.match(regrex2);
                        if(!index_array || index_array.length<1){
                            result.success = false;
                            result.data = "规则表达式中条件变量格式错误，请检查";
                            return result;
                        }

                        var var_index = parseInt(index_array[0]);
                        if(var_index>max_v_index){
                            max_v_index = var_index;
                        }
                    }

                    if(condition_count<max_v_index){
                        result.success = false;
                        result.data = "规则表达式中的变量最大索引[" + max_v_index + "]与条件个数[" + condition_count + "]不相符，请检查";
                        return result;
                    }
                }catch(e){
                    result.success = false;
                    result.data = "条件表达式验证发生异常:"+e;
                    return result;
                }                
            }

            result.success = true;
            return result;
        },


        buildExtractor:function(){
            var result = {
                success: false,
                data: {
                    extractor:{}
                }
            };

            var extractions = [];
            var tmp_success = true;
            var tmp_tip = "";
            $(".extraction-holder").each(function(){
                var self = $(this);
                var extraction = {};
                var type = self.find("select[name=rule-extractor-extraction-type]").val();
                extraction.type = type;

                if(type == "Header" || type == "Query" || type == "PostParams"){
                    var name = self.find("input[name=rule-extractor-extraction-name]").val();
                    if(!name){
                        tmp_success = false;
                        tmp_tip = "变量提取项的name字段不得为空";
                    }

                    extraction.name = name;
                }
                extractions.push(extraction);
            });

            if(!tmp_success){
                result.success = false;
                result.data = tmp_tip;
                return result;
            }
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
                top: 50,
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
        
        resetNav: function(select){
            $("#main-nav-menu li").each(function(){
                $(this).removeClass("active")
            });

            if(select){
                $("#main-nav-menu li#"+select).addClass("active");
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