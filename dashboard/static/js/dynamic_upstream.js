function gen_ngx_fmt_upstream_servers_conf(upstream_name)
{
    if(upstream_name == "")
        return "";
    var usl = APP.DynamicUpstream.upstream_servers_list[upstream_name]
    var crlf = "\n"
    var tab = " "

    var res = "upstream " + upstream_name + " {  " + crlf ;

    for (var k in  usl){
        var addrs = usl[k]
        var line = '';

        for(var k in addrs){

            if(k == "addr"){
                continue;
            }

            line += tab + k + "=" + addrs[k];
        }
        line += ";" + crlf;

        var servers = addrs['addr']
        if(typeof(servers) == "object"){
            var tmp = '';

            for(var k in servers){
                tmp += tab + "server " + servers[k] + line;
            }

            line = tmp;
        }else{
            line  = tab + "server " + servers + line;
        }

        res += line ;
    }

    res += "}" + crlf

    return res;
}

(function (L) {
    var _this = null;
    L.DynamicUpstream = L.DynamicUpstream || {};
    _this = L.DynamicUpstream = {
        data: {
        },

        renderRulesCallback:function(rules){
            if(!rules || rules.length<1){
                return ;
            }

            for(var k in rules){
                var r = rules[k];
                r.handle.upstream_name_ngx_fmt = gen_ngx_fmt_upstream_servers_conf(r.handle.upstream_name);
            }
        },

        init: function () {
            L.Common.loadConfigs("dynamic_upstream", _this, true);
            _this.initEvents();
        },

        initEvents: function(){
            L.Common.initRuleAddDialog("dynamic_upstream", _this);//添加规则对话框
            L.Common.initRuleDeleteDialog("dynamic_upstream", _this);//删除规则对话框
            L.Common.initRuleEditDialog("dynamic_upstream", _this);//编辑规则对话框
            L.Common.initRuleSortEvent("dynamic_upstream", _this);

            L.Common.initSelectorAddDialog("dynamic_upstream", _this);
            L.Common.initSelectorDeleteDialog("dynamic_upstream", _this);
            L.Common.initSelectorEditDialog("dynamic_upstream", _this);
            L.Common.initSelectorSortEvent("dynamic_upstream", _this);
            L.Common.initSelectorClickEvent("dynamic_upstream", _this);

            L.Common.initSelectorTypeChangeEvent();//选择器类型选择事件
            L.Common.initConditionAddOrRemove();//添加或删除条件
            L.Common.initJudgeTypeChangeEvent();//judge类型选择事件
            L.Common.initConditionTypeChangeEvent();//condition类型选择事件

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件

            L.Common.initViewAndDownloadEvent("dynamic_upstream", _this);
            L.Common.initSwitchBtn("dynamic_upstream", _this);//redirect关闭、开启
            L.Common.initSyncDialog("dynamic_upstream", _this);//编辑规则对话框
        },

        buildRule: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    judge:{},
                    extractor: {},
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
            var uri_tmpl = $("#rule-handle-uri-template").val();
            if (uri_tmpl) {
                // refer this https://www.w3schools.com/jsref/jsref_trim_string.asp
                uri_tmpl = function(x) {
                    return x.replace(/^\s+|\s+$/gm,'');
                }(uri_tmpl);
            }

            if(uri_tmpl) {
                handle.uri_tmpl = uri_tmpl
            }

            var upstream_scheme = $("#rule-handle-upstream-scheme").val();
            if (!upstream_scheme) {
                result.success = false;
                result.data = "dynamic upstream 使用的upstream name不得为空";
                return result;
            }
            handle.upstream_scheme = upstream_scheme;

            var upstream_name = $("#rule-handle-upstream-name").val();
            if (!upstream_name) {
                result.success = false;
                result.data = "dynamic upstream 使用的upstream name不得为空";
                return result;
            }
            handle.upstream_name = upstream_name;


            var host = $("#rule-handle-host").val();
            if (!host) {
               host = false
            }

            handle.host = host;

            handle.log = ($("#rule-handle-log").val() === "true");
            result.success = true;
            result.handle = handle;
            return result;
        },
    };
}(APP));
