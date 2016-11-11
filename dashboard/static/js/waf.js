(function (L) {
    var _this = null;
    L.WAF = L.WAF || {};
    _this = L.WAF = {
        data: {
        },

        init: function () {
             L.Common.loadConfigs("waf", _this, true);
            _this.initEvents();
        },

        initEvents: function () {
            var op_type = "waf";
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
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            _this.initHandleTypeChangeEvent();//handle类型选择事件
            _this.initStatBtnEvent();//统计按钮事件

            L.Common.initViewAndDownloadEvent(op_type, _this);
            L.Common.initSwitchBtn(op_type, _this);//redirect关闭、开启
            L.Common.initSyncDialog(op_type, _this);//编辑规则对话框
        },

        initStatBtnEvent: function () {
            $("#stat-btn").click(function () {//试图转换
                var self = $(this);
                var now_state = $(this).attr("data-show");
                if (now_state == "true") {
                    self.attr("data-show", "false");
                    $.ajax({
                        url: '/waf/stat',
                        type: 'get',
                        cache:false,
                        data: {},
                        dataType: 'json',
                        success: function (result) {
                            if (result.success) {
                                if (result.data && result.data.statistics) {
                                    $("#stat-area").html('');
                                    $("#stat-view").show();
                                    $("#stat-area").css("height", "400px");
                                    _this.initStatChart(result.data);
                                } else {
                                    $("#stat-area").html('<p style="text-align: center">没有统计数据</p>');
                                    $("#stat-area").css("height", "100px");
                                    $("#stat-view").show();
                                }

                            } else {
                                L.Common.showTipDialog("错误提示", "查询waf统计请求发生错误");
                            }
                        },
                        error: function () {
                            L.Common.showTipDialog("提示", "查询waf统计请求发生异常");
                        }
                    });
                } else {
                    self.attr("data-show", "true");
                    $("#stat-view").hide();
                }
            });
        },

        initStatChart: function (data) {
            var keys = [];
            var outer_data = [];

            var statistics = data.statistics;
            for(var i=0; i < statistics.length;i++){
                var s = statistics[i];
                keys.push(s.rule_id);
                
                outer_data.push({
                    value: s.count,
                    name: s.rule_id
                });
            }

            var option = {
                tooltip: {
                    trigger: 'item',
                    formatter: "{a} <br/>{b}: {c} ({d}%)"
                },
                legend: {
                    orient: 'vertical',
                    x: 'left',
                    data: keys
                },
                series: [
                    
                    {
                        name: '规则',
                        type: 'pie',

                        data: outer_data
                    }
                ]
            };

            var statChart = echarts.init(document.getElementById('stat-area'));
            statChart.setOption(option);
        },

        //handle类型选择事件
        initHandleTypeChangeEvent: function () {
            $(document).on("change", '#rule-handle-perform', function () {
                var handle_type = $(this).val();

                if (handle_type == "allow") {
                    $(this).parents(".handle-holder").find(".handle-code-hodler").hide();
                } else {
                    $(this).parents(".handle-holder").find(".handle-code-hodler").show();
                }
            });
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
            var handle_perform = $("#rule-handle-perform").val();
            if (handle_perform != "deny" && handle_perform != "allow") {
                result.success = false;
                result.data = "执行动作类型不合法，只能是deny或allow";
                return result;
            }
            handle.perform = handle_perform;

            if (handle_perform == "deny") {
                var handle_code = $("#rule-handle-code").val();
                if (!handle_code) {
                    result.success = false;
                    result.data = "执行deny的状态码不能为空";
                    return result;
                }

                handle.code = parseInt(handle_code);
            }

            handle.stat = ($("#rule-handle-stat").val() === "true");
            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },
    };
}(APP));
