(function (L) {
    var _this = null;
    L.DynamicSSL = L.DynamicSSL || {};
    _this = L.DynamicSSL = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("dynamic_ssl", _this, true);
            _this.initEvents();
        },

        initEvents: function(){
            var op_type = "dynamic_ssl";
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

            L.Common.initExtractionAddOrRemove();//添加或删除条件
            L.Common.initExtractionTypeChangeEvent();//extraction类型选择事件
            L.Common.initExtractionAddBtnEvent();//添加提前项按钮事件
            L.Common.initExtractionHasDefaultValueOrNotEvent();//提取项是否有默认值选择事件


            L.Common.initHeaderAddBtnEvent();
            L.Common.initHeaderAddOrRemove();

            L.Common.initViewAndDownloadEvent(op_type, _this);
            L.Common.initSwitchBtn(op_type, _this);//插件关闭、开启
            L.Common.initSyncDialog(op_type, _this);//编辑规则对话框
        },


        buildRule: function(){
            var result = {
                success: false,
                data: {
                    name: null,
                    judge:{},
                    extractor: {},
                    handle:{},
                    headers:{}
                }
            };

            //build name and judge
            var temp_result = L.Common.buildName();
            if(!temp_result.success){
                return temp_result;
            }else{
                result.data.name = temp_result.data.name
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
            handle.log = ($("#rule-handle-log").val() === "true");

            var sni = $("#rule-handle-sni").val();
            if(!sni)
            {
                result.success = false
                result.data = "sni 不能为空"
                return result
            }
            handle.sni = sni


            var cert = $("#rule-handle-cert-pem").val();
            if(!cert)
            {
                result.success = false
                result.data = "证书 cert 字段不能为空"
                return result
            }
            handle.cert = cert

            var pkey = $("#rule-handle-pkey-pem").val();
            if(!pkey)
            {
                result.success = false
                result.data = "私钥 pkey 字段不能为空"
                return result
            }
            handle.pkey = pkey

            result.success = true;
            result.handle = handle;
            return result;
        }
    };
}(APP));
