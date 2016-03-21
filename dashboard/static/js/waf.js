(function (L) {
    var _this = null;
    L.WAF = L.WAF || {};
    _this = L.WAF = {
        data: {
            rules: {}
        },

        init: function () {
            _this.loadConfigs();
            _this.initEvents();

        },

        initEvents: function(){
            _this.initRuleAddDialog();//添加规则对话框
            _this.initRuleDeleteDialog();//删除规则对话框
            _this.initRuleEditDialog();//编辑规则对话框
            _this.initConditionAddOrRemove();//添加或删除条件
            _this.initMatcherTypeChangeEvent();//matcher类型选择事件
            _this.initConditionTypeChangeEvent();//condition类型选择事件
            _this.initActionTypeChangeEvent();//action类型选择事件

        },

        //增加、删除条件按钮事件
        initConditionAddOrRemove: function(){

            //添加规则框里的事件
            //点击“加号“添加新的输入行
            $(document).on('click', '#add-rule-form .pair .btn-success', _this.addNewCondition);

            //删除输入行
            $(document).on('click', '#add-rule-form .pair .btn-danger', function(event) {
                $(this).parents('.form-group').remove();//删除本行输入
                _this.resetAddConditionBtn();
            });


            //编辑规则框里的事件
            //点击“加号“添加新的输入行
            $(document).on('click', '#edit-rule-form .pair .btn-success', _this.addNewCondition);

            //删除输入行
            $(document).on('click', '#edit-rule-form .pair .btn-danger', function(event) {
                $(this).parents('.form-group').remove();//删除本行输入
                _this.resetAddConditionBtn();
            });
        },

        //matcher类型选择事件
        initMatcherTypeChangeEvent: function(){
            $(document).on("change", '#rule-matcher-type',function(){
                var matcher_type = $(this).val();
                if(matcher_type != "0" && matcher_type != "1"  && matcher_type != "2" && matcher_type != "3"){
                    L.Common.showTipDialog("提示", "选择的matcher类型不合法");
                    return
                }

                if(matcher_type == "3"){
                    $("#expression-area").show();
                }else{
                    $("#expression-area").hide();
                }
            });
        },

        //condition类型选择事件
        initConditionTypeChangeEvent: function(){
            $(document).on("change", 'select[name=rule-matcher-condition-type]',function(){
                var condition_type = $(this).val();

                if(condition_type != "Header"){
                    $(this).parents(".condition-holder").each(function(){
                         $(this).find(".condition-name-hodler").hide();
                    });
                }else{
                     $(this).parents(".condition-holder").each(function(){
                         $(this).find(".condition-name-hodler").show();
                    });
                }
            });
        },

        //action类型选择事件
        initActionTypeChangeEvent: function(){
            $(document).on("change", '#rule-action-perform',function(){
                var action_type = $(this).val();

                if(action_type == "allow"){
                    $(this).parents(".action-holder").find(".action-code-hodler").hide();
                }else{
                    $(this).parents(".action-holder").find(".action-code-hodler").show();
                }
            });
        },


        buildRule: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    matcher:{},
                    action:{}
                }
            };

            //build name and matcher
            var buildMatcherResult = _this.buildMatcher();
            if(buildMatcherResult.success == true){
                result.data.name = buildMatcherResult.data.name;
                result.data.matcher = buildMatcherResult.data.matcher;
            }else{
                result.success = false;
                result.data = buildMatcherResult.data;
                return result;
            }

            //build action
            var buildActionResult = _this.buildAction();
            if(buildActionResult.success == true){
                result.data.action = buildActionResult.action;
            }else{
                result.success = false;
                result.data = buildActionResult.data;
                return result;
            }

            //enable or not
            var enable = $('#rule-enable').is(':checked');
            result.data.enable = enable;

            result.success = true;
            return result;
        },

        buildMatcher: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    matcher:{}
                }
            };
            var name = $("#rule-name").val();
            if(!name){
                result.success = false;
                result.data = "规则名称不能为空";
                return result;
            }

            result.data.name = name;

            

            var matcher_type = parseInt($("#rule-matcher-type").val());
            result.data.matcher.type = matcher_type;

            if(matcher_type == 3){
                var matcher_expression = $("#rule-matcher-expression").val();
                if(!matcher_expression){
                    result.success = false;
                    result.data = "复杂匹配的规则表达式不得为空";
                    return result;
                }
                result.data.matcher.expression = matcher_expression;
            }

            var matcher_conditions = [];

            var tmp_success = true;
            var tmp_tip = "";
            $(".condition-holder").each(function(){
                var self = $(this);
                var condition = {};
                var condition_type = self.find("select[name=rule-matcher-condition-type]").val();
                condition.type = condition_type;

                if(condition_type == "Header"){
                    var condition_name = self.find("input[name=rule-matcher-condition-name]").val();
                    if(!condition_name){
                        tmp_success = false;
                        tmp_tip = "condition的name字段不得为空";
                    }

                    condition.name = condition_name;
                }

                condition.operator = self.find("select[name=rule-matcher-condition-operator]").val();
                condition.value = self.find("input[name=rule-matcher-condition-value]").val() || "";

                matcher_conditions.push(condition);
            });

            if(!tmp_success){
                result.success = false;
                result.data = tmp_tip;
                return result;
            }
            result.data.matcher.conditions = matcher_conditions;

            //判断规则类型和条件个数是否匹配
            if(result.data.matcher.conditions.length<1){
                result.success = false;
                result.data = "请配置规则条件";
                return result;
            }
            if(result.data.matcher.type==0 && result.data.matcher.conditions.length!=1){
                result.success = false;
                result.data = "单一条件匹配模式只能有一条condition，请删除多余配置";
                return result;
            }
            if(result.data.matcher.type==3){//判断条件表达式与条件个数等
                try{
                    var condition_count = result.data.matcher.conditions.length;
                    var regrex1 = /(v\[[0-9]+\])/g;
                    var regrex2 = /([0-9]+)/g;
                    var expression_v_array = [];// 提取条件变量
                    expression_v_array = result.data.matcher.expression.match(regrex1);
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

        buildAction: function(){
            var result = {};
            var action = {};
            var action_perform = $("#rule-action-perform").val();
            if(action_perform!="deny" && action_perform!="allow"){
                result.success = false;
                result.data = "执行动作类型不合法，只能是deny或allow";
                return result;
            }
            action.perform = action_perform;

            if(action_perform=="deny"){
                var action_code = $("#rule-action-code").val();
                if(!action_code){
                    result.success = false;
                    result.data = "执行deny的状态码不能为空";
                    return result;
                }

                action.code = parseInt(action_code);
            }

            action.log = ($("#rule-action-log").val() === "true");
            result.success = true;
            result.action = action;
            return result;
        },

        initRuleAddDialog: function(){
            $("#add-btn").click(function(){
                var content = $("#add-tpl").html()
                var d = dialog({
                    title: '添加规则',
                    width: 680,
                    content: content,
                    modal:true,
                    button: [{
                            value: '取消'
                        },{
                            value: '预览',
                            autofocus: false,
                            callback: function () {
                                _this.showRulePreview();
                                return false;
                            }
                        },{
                            value: '确定',
                            autofocus: false,
                            callback: function () {
                                var result = _this.buildRule();
                                if(result.success == true){
                                    $.ajax({
                                        url : '/orange/dashboard/waf/configs',
                                        type : 'put',
                                        data: {
                                            rule: JSON.stringify(result.data)
                                        },
                                        dataType : 'json',
                                        success : function(result) {
                                            if(result.success){
                                                //重新渲染规则
                                                var tpl = $("#rule-item-tpl").html();
                                                var html = juicer(tpl, result.data);
                                                _this.data.rules = result.data.access_rules;
                                                $("#rules").html(html);
                                                return true;
                                            }else{
                                                _this.showErrorTip("提示", result.msg || "添加规则发生错误");
                                                return false;
                                            }
                                        },
                                        error : function() {
                                            _this.showErrorTip("提示", "添加规则请求发生异常");
                                            return false;
                                        }
                                    });
                                    
                                }else{
                                    _this.showErrorTip("错误提示", result.data);
                                    return false;
                                }
                            }
                        }
                    ]
                });
                _this.resetAddConditionBtn();//删除增加按钮显示与否
                d.show();
            });
        },

        initRuleEditDialog: function(){
            $(document).on("click", ".edit-btn", function(){
                var tpl = $("#edit-tpl").html();
                var rule_id = $(this).attr("data-id");
                var rule = {};
                var rules = _this.data.rules;
                for(var i=0; i< rules.length; i++){
                    var r = rules[i];
                    if(r.id == rule_id){
                        rule = r;
                        break;
                    }
                }
                if(!rule_id || !rule){
                    _this.showErrorTip("提示", "要编辑的规则不存在或者查找出错");
                    return;
                }

                console.log("编辑", rule);

                var html = juicer(tpl, {
                    r:rule
                });

                var d = dialog({
                    title: "编辑规则",
                    width: 680,
                    content: html,
                    modal:true,
                    button: [{
                            value: '取消'
                        },{
                            value: '预览',
                            autofocus: false,
                            callback: function () {
                                _this.showRulePreview();
                                return false;
                            }
                        },{
                            value: '保存修改',
                            autofocus: false,
                            callback: function () {
                                var result = _this.buildRule();
                                result.data.id = rule.id;//拼上要修改的id

                                if(result.success == true){
                                    $.ajax({
                                        url : '/orange/dashboard/waf/configs',
                                        type : 'post',
                                        data: {
                                            rule: JSON.stringify(result.data)
                                        },
                                        dataType : 'json',
                                        success : function(result) {
                                            if(result.success){
                                                //重新渲染规则
                                                var tpl = $("#rule-item-tpl").html();
                                                var html = juicer(tpl, result.data);
                                                _this.data.rules = result.data.access_rules;
                                                $("#rules").html(html);
                                                return true;
                                            }else{
                                                _this.showErrorTip("提示", result.msg || "编辑规则发生错误");
                                                return false;
                                            }
                                        },
                                        error : function() {
                                            _this.showErrorTip("提示", "编辑规则请求发生异常");
                                            return false;
                                        }
                                    });
                                    
                                }else{
                                    _this.showErrorTip("错误提示", result.data);
                                    return false;
                                }
                            }
                        }
                    ]
                });

                _this.resetAddConditionBtn();//删除增加按钮显示与否
                d.show();
            });
        },

        initRuleDeleteDialog: function(){
            $(document).on("click", ".delete-btn", function(){

                var name = $(this).attr("data-name");
                var rule_id = $(this).attr("data-id");
                console.log("删除:" + name);
                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除规则【"+ name +"】吗？",
                    modal:true,
                    button: [{
                            value: '取消'
                        },{
                            value: '确定',
                            autofocus: false,
                            callback: function () {
                                $.ajax({
                                    url : '/orange/dashboard/waf/configs',
                                    type : 'delete',
                                    data: {
                                        rule_id: rule_id
                                    },
                                    dataType : 'json',
                                    success : function(result) {
                                        if(result.success){
                                            //重新渲染规则
                                            var tpl = $("#rule-item-tpl").html();
                                            var html = juicer(tpl, result.data);
                                            _this.data.rules = result.data.access_rules;
                                            $("#rules").html(html);
                                            return true;
                                        }else{
                                            _this.showErrorTip("提示", result.msg || "删除规则发生错误");
                                            return false;
                                        }
                                    },
                                    error : function() {
                                        _this.showErrorTip("提示", "删除规则请求发生异常");
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

        showErrorTip: function(title, content){
            var d = dialog({
                title: title,
                width: 300,
                content: content,
                modal:true,
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

        showRulePreview: function(){
            var content = "";
            var rule = _this.buildRule();
            if(rule.success==true){
                content = '<pre id="preview_rule"><code></code></pre>';
            }else{
                content = rule.data;
            }

            var d = dialog({
                title: '规则预览',
                width: 500,
                content: content,
                modal:true,
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

        addNewCondition: function(event) {
            var self = $(this);
            var row = self.parents('.condition-holder');
            var new_row = row.clone(true);
            // $(new_row).find("input[name=rule-matcher-condition-value]").val("");
            // $(new_row).find("input[name=rule-matcher-condition-name]").val("");
            
            var old_type = $(row).find("select[name=rule-matcher-condition-type]").val();
            $(new_row).find("select[name=rule-matcher-condition-type]").val(old_type);

            var old_operator = $(row).find("select[name=rule-matcher-condition-operator]").val();
            $(new_row).find("select[name=rule-matcher-condition-operator]").val(old_operator);

            $(new_row).insertAfter($(this).parents('.condition-holder'))
            _this.resetAddConditionBtn();
        },

        resetAddConditionBtn: function(){
            var l = $(".pair").length;
            var c = 0;
            $(".pair").each(function(){
                c++;
                if(c==l){
                    $(this).find(".btn-success").show();
                    $(this).find(".btn-danger").show();
                }else{
                    $(this).find(".btn-success").hide();
                    $(this).find(".btn-danger").show();
                }
            })
        },

        loadConfigs: function () {
            $.ajax({
                url: '/orange/dashboard/waf/configs',
                type: 'get',
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        var tpl = $("#rule-item-tpl").html();
                        var html = juicer(tpl, result.data);
                        $("#rules").html(html);
                        _this.data.rules = result.data.access_rules;

                    }else{
                        L.Common.showTipDialog("错误提示", "查询waf配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询waf配置请求发生异常");
                }
            });
        },
    };
}(APP));