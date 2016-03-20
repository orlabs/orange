(function (L) {
    var _this = null;
    L.Rewrite = L.Rewrite || {};
    _this = L.Rewrite = {
        data: {},

        init: function () {
            _this.loadConfigs();

        },

        loadConfigs: function () {
            $.ajax({
                url: '/orange/dashboard/rewrite/configs',
                type: 'get',
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        var tpl = $("#rule-item-tpl").html();
                        var html = juicer(tpl, result.data);
                        $("#rules").html(html);
                    }else{
                        APP.Common.showTipDialog("错误提示", "查询rewrite配置请求发生错误");
                    }
                },
                error: function () {
                    APP.Common.showTipDialog("提示", "查询rewrite配置请求发生异常");
                }
            });
        },


    };
}(APP));