(function (L) {
    var _this = null;
    L.Monitor = L.Monitor || {};
    _this = L.Monitor = {
         data: {
            rules: {},
        },

        init: function () {
            _this.loadConfigs();
            _this.initEvents();

        },

        initEvents: function(){
            L.Common.initRuleAddDialog("monitor", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("monitor", _this);//删除规则对话框
            L.Common.initRuleEditDialog("monitor", _this);//编辑规则对话框
            L.Common.initSyncDialog("monitor", _this);//编辑规则对话框

            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            L.Common.initViewAndDownloadEvent("monitor");

            L.Common.initSwitchBtn("monitor");//redirect关闭、开启

            _this.initStatisticBtnEvent();
        },

        buildRule: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    judge:{},
                    handle:{}
                }
            };

            //build name and judge
            var buildJudgeResult = L.Common.buildJudge();
            if(buildJudgeResult.success == true){
                result.data.name = buildJudgeResult.data.name;
                result.data.judge = buildJudgeResult.data.judge;
            }else{
                result.success = false;
                result.data = buildJudgeResult.data;
                return result;
            }

            //build handle
            var buildHandleResult = _this.buildHandle();
            if(buildHandleResult.success == true){
                result.data.handle = buildHandleResult.handle;
            }else{
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


        buildHandle: function(){
            var result = {};
            var handle = {};
            handle.continue = ($("#rule-handle-continue").val() === "true");
            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },

        initStatisticBtnEvent:function(){
            $(document).on( "click",".statistic-btn", function(){
                var self = $(this);
                var rule_id = self.attr("data-id");
                var rule_name = self.attr("data-name");
                if(!rule_id){
                    return;
                }
                window.location.href = "/monitor/rule/statistic?rule_id="+rule_id+"&rule_name="+encodeURI(rule_name);
            });

        },

        loadConfigs: function () {
            $.ajax({
                url: '/monitor/configs',
                type: 'get',
                cache:false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        if(result.data){
                            L.Common.resetSwitchBtn(result.data.enable, "monitor");
                            $("#switch-btn").show();
                            $("#view-btn").show();
                            _this.renderTable(result.data);//渲染table
                            _this.data.enable = result.data.enable;
                            _this.data.rules = result.data.rules;//重新设置数据
                        }

                    }else{
                        L.Common.showTipDialog("错误提示", "查询自定义监控配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询自定义监控配置请求发生异常");
                }
            });
        },

        renderTable: function(data, highlight_id){
            highlight_id = highlight_id || 0;
            var tpl = $("#rule-item-tpl").html();
            data.highlight_id = highlight_id;
            var html = juicer(tpl, data);
            $("#rules").html(html);
        }
    };
}(APP));