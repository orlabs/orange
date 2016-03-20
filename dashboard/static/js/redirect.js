(function (L) {
    var _this = null;
    L.Redirect = L.Redirect || {};
    _this = L.Redirect = {
        data: {},

        init: function () {
            _this.loadConfigs();

        },

        loadConfigs: function () {
            $.ajax({
                url: '/orange/dashboard/redirect/configs',
                type: 'get',
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        var tpl = $("#rule-item-tpl").html();
                        var html = juicer(tpl, result.data);
                        $("#rules").html(html);
                    }else{
                        APP.Common.showTipDialog("错误提示", "查询redirect配置请求发生错误");
                    }
                },
                error: function () {
                    APP.Common.showTipDialog("提示", "查询redirect配置请求发生异常");
                }
            });
        },


    };
}(APP));