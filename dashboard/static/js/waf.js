(function (L) {
    var _this = null;
    L.WAF = L.WAF || {};
    _this = L.WAF = {
        data: {
            rules: {},
            ruletable: null
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
            _this.initSwitchBtn();//防火墙关闭、开启

            $("#view-btn").click(function(){//试图转换
                var self = $(this);
                var now_state = $(this).attr("data-type");
                if(now_state == "table"){//当前是表格视图，点击切换到数据视图
                    self.attr("data-type", "database");
                    self.find("i").removeClass("fa-database").addClass("fa-table");
                    self.find("span").text("表格视图");

                    var showData = {
                        enable: _this.data.enable,
                        access_rules: _this.data.rules
                    }
                    jsonformat.format(JSON.stringify(showData));
                    $("#jfContent_pre").text(JSON.stringify(showData, null, 4));
                    $('pre').each(function(){
                        hljs.highlightBlock($(this)[0]);
                    });
                    $("#table-view").hide();
                    $("#database-view").show();
                }else{
                    self.attr("data-type", "table");
                    self.find("i").removeClass("fa-table").addClass("fa-database");
                    self.find("span").text("数据视图");

                    $("#database-view").hide();
                    $("#table-view").show();
                }
            });

            $(document).on("click", "#btnDownload", function(){//规则json下载
                var downloadData = {
                    enable: _this.data.enable,
                    access_rules: _this.data.rules
                }
                var blob = new Blob([JSON.stringify(downloadData, null, 4)], {type: "text/plain;charset=utf-8"});
                saveAs(blob, "data.json");
            });
        },


        initSwitchBtn: function(enable){
            $("#switch-btn").click(function(){//是否开启防火墙
                var self = $(this);
                var now_state = $(this).attr("data-on");
                if(now_state == "yes"){//当前是开启状态，点击则“关闭”
                    var d = dialog({
                        title: '防火墙设置',
                        width: 300,
                        content: "确定要关闭防火墙吗？",
                        modal:true,
                        button: [{
                                value: '取消'
                            },{
                                value: '确定',
                                autofocus: false,
                                callback: function () {
                                    $.ajax({
                                        url : '/orange/dashboard/waf/enable',
                                        type : 'post',
                                        data: {
                                            enable: "0"
                                        },
                                        dataType : 'json',
                                        success : function(result) {
                                            if(result.success){
                                                //重置按钮
                                                _this.data.enable = false;
                                                self.attr("data-on", "no");
                                                self.removeClass("btn-danger").addClass("btn-info");
                                                self.find("i").removeClass("fa-pause").addClass("fa-play");
                                                self.find("span").text("启用防火墙");
                                                
                                                return true;
                                            }else{
                                                _this.showErrorTip("提示", result.msg || "关闭防火墙发生错误");
                                                return false;
                                            }
                                        },
                                        error : function() {
                                            _this.showErrorTip("提示", "关闭防火墙请求发生异常");
                                            return false;
                                        }
                                    });
                                }
                            }
                        ]
                    });
                    d.show();

                    
                }else{
                    var d = dialog({
                        title: '防火墙设置',
                        width: 300,
                        content: "确定要开启防火墙吗？",
                        modal:true,
                        button: [{
                                value: '取消'
                            },{
                                value: '确定',
                                autofocus: false,
                                callback: function () {
                                    $.ajax({
                                        url : '/orange/dashboard/waf/enable',
                                        type : 'post',
                                        data: {
                                            enable: "1"
                                        },
                                        dataType : 'json',
                                        success : function(result) {
                                            if(result.success){
                                                 _this.data.enable = true;
                                                //重置按钮
                                                self.attr("data-on", "yes");
                                                self.removeClass("btn-info").addClass("btn-danger");
                                                self.find("i").removeClass("fa-play").addClass("fa-pause");
                                                self.find("span").text("停用防火墙");
                                                
                                                return true;
                                            }else{
                                                _this.showErrorTip("提示", result.msg || "开启防火墙发生错误");
                                                return false;
                                            }
                                        },
                                        error : function() {
                                            _this.showErrorTip("提示", "开启防火墙请求发生异常");
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
            var buildMatcherResult = L.Common.buildMatcher();
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
                                                
                                                _this.data.rules = result.data.access_rules;//重新设置数据
                                                _this.renderTable(result.data, _this.data.rules[_this.data.rules.length-1].id);//渲染table
                                                _this.makeTableListable();//list table
                                                
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
                                                _this.renderTable(result.data, rule_id);//渲染table
                                                _this.data.rules = result.data.access_rules;//重新设置数据
                                                _this.makeTableListable();//list table
                                                
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
                                             _this.renderTable(result.data);//渲染table
                                            _this.data.rules = result.data.access_rules;//重新设置数据
                                            _this.makeTableListable();//list table
                                            
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
                        _this.resetSwitchBtn(result.data.enable);
                        $("#switch-btn").show();
                        $("#view-btn").show();
                        _this.renderTable(result.data);//渲染table
                        _this.data.enable = result.data.enable;
                        _this.data.rules = result.data.access_rules;//重新设置数据
                        _this.makeTableListable();//list table

                    }else{
                        L.Common.showTipDialog("错误提示", "查询waf配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询waf配置请求发生异常");
                }
            });
        },

        resetSwitchBtn: function(enable){
            var self = $("#switch-btn");
            if(enable == true){//当前是开启状态，则应显示“关闭”按钮
                self.attr("data-on", "yes");
                self.removeClass("btn-info").addClass("btn-danger");
                self.find("i").removeClass("fa-play").addClass("fa-pause");
                self.find("span").text("停用防火墙");
            }else{
                self.attr("data-on", "no");
                self.removeClass("btn-danger").addClass("btn-info");
                self.find("i").removeClass("fa-pause").addClass("fa-play");
                self.find("span").text("启用防火墙");
            }
        },

        renderTable: function(data, highlight_id){
            highlight_id = highlight_id || 0;
            var tpl = $("#rule-item-tpl").html();
            data.highlight_id = highlight_id;
            var html = juicer(tpl, data);
            $("#rules").html(html);
        },

        makeTableListable: function(){
            // console.log("build table++++++++++++", $("#rules").html());
            // _this.data.ruletable = $('#operable-table').DataTable({
            //     paging: false, 
            //     searching: false, 
            //     sort:false,
            //     destory: true,
            // }).draw();
            // console.log("build table------------", $("#rules").html());
            
            $("#operable-table_filter").hide();
            $("#rule-search").hide();
        },

        search: function(word){
            if( _this.data.ruletable == null )
                return;
            _this.data.ruletable.search(word).draw();
        }


    };
}(APP));