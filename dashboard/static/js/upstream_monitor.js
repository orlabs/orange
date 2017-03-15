(function (L) {
    var _this = null;
    L.UpstreamMonitor = L.UpstreamMonitor || {};
    _this = L.UpstreamMonitor = {
        data: {
        },

        init: function () {
            _this.initEvents();
            var op_type = "upstream_monitor";
            $.ajax({
                url: '/' + op_type + '/configs',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {

                        $("#upstream-monitor-config").text('')
                        $.each(result.data.conf, function(name, value)
                        {
                            var text = "<span>"+ name + "</span>"
                            var input = text + "<br/> <textarea name= " + name + ">"+value+"</textarea>  <br/>"
                            $("#upstream-monitor-config").append(input)
                        });

                        $("#upstream-monitor-status").html("<pre>" + result.data.upstream_status + "</pre>")

                        L.Common.resetSwitchBtn(result.data.enable, op_type);
                        $("#switch-btn").show();
                        $("#view-btn").show();
                        var enable = result.data.enable;

                        //重新设置数据
                        _this.data.enable = enable;
                        $("#op-part").css("display", "block");
                    } else {
                        $("#op-part").css("display", "none");
                        L.Common.showErrorTip("错误提示", "查询" + op_type + "配置请求发生错误");
                    }
                },
                error: function () {
                    $("#op-part").css("display", "none");
                    L.Common.showErrorTip("提示", "查询" + op_type + "配置请求发生异常");
                }
            });

            $("#upstream-monitor-config-submit").click(function(){
                $.ajax({
                    url: '/' + op_type + '/configs',
                    type: 'post',
                    cache: false,
                    data: $('form').serialize(),
                    dataType: 'json',
                    success:function(result){
                        alert(result)

                    },
                    error:function() {
                        $("#op-part").css("display", "none");
                        L.Common.showErrorTip("提示", "查询" + op_type + "配置请求发生异常");
                    }
                });
            });
        },
        initEvents: function(){
            var op_type = "upstream_monitor";
            L.Common.initViewAndDownloadEvent(op_type, _this);
            L.Common.initSwitchBtn(op_type, _this);//redirect关闭、开启
            L.Common.initSyncDialog(op_type, _this);//编辑规则对话框
        },
    };
}(APP));
