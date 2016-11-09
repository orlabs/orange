(function (L) {
    var _this = null;
    L.Redirect = L.Redirect || {};
    _this = L.Redirect = {
        data: {
            rules: {},
        },

        init: function () {
            _this.loadConfigs(true);
            _this.initEvents();

        },

        initEvents: function () {
            L.Common.initRuleAddDialog("redirect", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("redirect", _this);//删除规则对话框
            L.Common.initRuleEditDialog("redirect", _this);//编辑规则对话框

            L.Common.initSelectorAddDialog("redirect", _this);
            L.Common.initSelectorDeleteDialog("redirect", _this);
            L.Common.initSelectorEditDialog("redirect", _this);
            L.Common.initSelectorSortEvent("redirect", _this);
            L.Common.initSelectorClickEvent("redirect", _this);

            L.Common.initSyncDialog("redirect", _this);//编辑规则对话框

            L.Common.initSelectorTypeChangeEvent();//选择器类型选择事件
            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            L.Common.initViewAndDownloadEvent("redirect");

            L.Common.initSwitchBtn("redirect");//redirect关闭、开启

        },

        buildRule: function () {
            var result = {
                success: false,
                data: {
                    name: null,
                    judge: {},
                    extractor: {},
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

            //build extractor
            var buildExtractorResult = L.Common.buildExtractor();
            if (buildExtractorResult.success == true) {
                result.data.extractor = buildExtractorResult.data.extractor;
            } else {
                result.success = false;
                result.data = buildExtractorResult.data;
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
            var url_tmpl = $("#rule-handle-url-template").val();
            if (!url_tmpl) {
                result.success = false;
                result.data = "要跳转到的url template不得为空";
                return result;
            }
            handle.url_tmpl = url_tmpl;
            handle.trim_qs = ($("#rule-handle-trim-qs").val() === "true");
            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },

        loadConfigs: function (page_load) {
            $.ajax({
                url: '/redirect/selectors',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        L.Common.resetSwitchBtn(result.data.enable, "redirect");
                        $("#switch-btn").show();
                        $("#view-btn").show();

                        var enable = result.data.enable;
                        var meta = result.data.meta;
                        var selectors = result.data.selectors;

                        //重新设置数据
                        _this.data.enable = enable;
                        _this.data.meta = meta;
                        _this.data.selectors = selectors;

                        _this.renderSelectors(meta, selectors);

                        if(page_load){//第一次加载页面
                            var selector_lis = $("#selector-list li");
                            if(selector_lis && selector_lis.length>0){
                                $(selector_lis[0]).click();
                            }
                        }

                    } else {
                        L.Common.showTipDialog("错误提示", "查询redirect配置请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询redirect配置请求发生异常");
                }
            });
        },

        loadRules: function (selector_id) {
            $.ajax({
                url: '/redirect/selectors/' + selector_id + "/rules",
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        $("#switch-btn").show();
                        $("#view-btn").show();

                        //重新设置数据
                        _this.data.selector_rules = _this.data.selector_rules || {};
                        _this.data.selector_rules[selector_id] = result.data.rules;
                        _this.renderRules(result.data);
                    } else {
                        L.Common.showTipDialog("错误提示", "查询redirect规则发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询redirect规则发生异常");
                }
            });
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
        }
    };
}(APP));
