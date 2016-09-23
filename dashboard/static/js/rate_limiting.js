(function (L) {
    var _this = null;
    L.RateLimiting = L.RateLimiting || {};
    _this = L.RateLimiting = {
        data: {
            rules: {},
        },

        init: function () {
            _this.loadConfigs();
            _this.initEvents();

        },

        initEvents: function(){
            L.Common.initRuleAddDialog("rate_limiting", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("rate_limiting", _this);//删除规则对话框
            L.Common.initRuleEditDialog("rate_limiting", _this);//编辑规则对话框
            L.Common.initSyncDialog("rate_limiting", _this);//编辑规则对话框

            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initViewAndDownloadEvent("rate_limiting");

            L.Common.initSwitchBtn("rate_limiting");//redirect关闭、开启
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
            var period = $("#rule-handle-period").val();
            period = parseInt(period);
            if(isNaN(period)){
                console.log("时间间隔错误：", period);
                result.success = false;
                result.data = "时间间隔选择错误，须是整数";
                return result;
            }
            handle.period = period;

            var count = $("#rule-handle-count").val();
            count = parseInt(count);
            if(isNaN(count)){
                console.log("最多访问次数输入错误：", count);
                result.success = false;
                result.data = "最多访问次数输入错误，须是整数";
                return result;
            }
            handle.count = count;

            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },

        loadConfigs: function () {
            $.ajax({
                url: '/rate_limiting/configs',
                type: 'get',
                cache:false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        if(result.data){
                            L.Common.resetSwitchBtn(result.data.enable, "rate_limiting");
                            $("#switch-btn").show();
                            $("#view-btn").show();
                            _this.renderTable(result.data);//渲染table
                            _this.data.enable = result.data.enable;
                            _this.data.rules = result.data.rules;//重新设置数据
                        }

                    }else{
                        L.Common.showTipDialog("错误提示", "查询访问限速配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询访问限速配置请求发生异常");
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
