(function(L) {
    var _this = null;
    L.NodeManage = L.NodeManage || {};

    _this = L.NodeManage = {
        data: {},

        init: function() {
            _this.loadNodes();
            L.Common.loadConfigs("node", _this, true);
            _this.initEvents();
            _this.initStatisticBtnEvent();
        },

        initEvents: function() {

            var op_type = "node";
            L.Common.initSwitchBtn(op_type, _this); //关闭、开启

            $("#add-node-btn").click(function() {
                var content = $("#add-node-tpl").html()
                var d = dialog({
                    title: '添加 orange 节点',
                    width: 480,
                    content: content,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function() {
                            var name = $("input[name=name]").val();
                            var ip = $("input[name=ip]").val();
                            var port = parseInt($("input[name=port]").val());
                            var api_username = $("input[name=api_username]").val();
                            var api_password = $("input[name=api_password]").val();

                            var name_pattern = /^.{1,20}$/;
                            if (!name || !name.match(name_pattern)) {
                                L.Common.showErrorTip("提示", "节点名称为1~20位");
                                return false;
                            }

                            // 取消ip验证
                            // var ip_pattern = /^\d+\.\d+\.\d+\.\d+$/;
                            // if (!ip || !ip.match(ip_pattern)) {
                            //     L.Common.showErrorTip("提示", "IP 格式不正确!");
                            //     return false;
                            // }

                            var port_pattern = /^\d+$/;
                            if (!port || isNaN(port) || port < 1 || port > 65535 || !port.toString().match(port_pattern)) {
                                L.Common.showErrorTip("提示", "端口为 1~65535 间的数字!");
                                return false;
                            }

                            $.ajax({
                                url: '/admin/node/new',
                                type: 'post',
                                cache: false,
                                data: {
                                    name: name,
                                    ip: ip,
                                    port: port,
                                    api_username: api_username,
                                    api_password: api_password
                                },
                                dataType: 'json',
                                success: function(result) {
                                    if (result.success) {
                                        //重新渲染规则

                                        _this.data.nodes = result.data.nodes; //重新设置数据
                                        _this.renderTable(result.data, _this.data.nodes[_this.data.nodes.length - 1].id); //渲染table
                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "添加节点发生错误");
                                        return false;
                                    }
                                },
                                error: function() {
                                    L.Common.showErrorTip("提示", "添加节点请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });
                d.show();
            });

            $(document).on("click", ".delete-node-btn", function() {
                var id = $(this).attr("data-id");
                var name = $(this).attr("data-name");

                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除【" + name + "】节点吗?",
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function() {
                            $.ajax({
                                url: '/admin/node/delete',
                                type: 'post',
                                cache: false,
                                data: {
                                    id: id
                                },
                                dataType: 'json',
                                success: function(result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.renderTable(result.data); //渲染table
                                        _this.data.nodes = result.data.nodes; //重新设置数据
                                        L.Common.showTipDialog("提示", result.msg || "删除节点信息成功")
                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除节点发生错误");
                                        return false;
                                    }
                                },
                                error: function() {
                                    L.Common.showErrorTip("提示", "删除节点请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });

                d.show();
            });

            $(document).on("click", "#clear-error-node-btn", function() {

                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除所有发生错误的节点？",
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function() {
                            $.ajax({
                                url: '/admin/node/remove_error_nodes',
                                type: 'post',
                                cache: false,
                                dataType: 'json',
                                success: function(result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.renderTable(result.data); //渲染table
                                        _this.data.nodes = result.data.nodes; //重新设置数据
                                        L.Common.showTipDialog("提示", result.msg || "删除节点信息成功")
                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除节点发生错误");
                                        return false;
                                    }
                                },
                                error: function() {
                                    L.Common.showErrorTip("提示", "删除节点请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });

                d.show();
            });

            $(document).on("click", ".edit-node-btn", function() {
                var tpl = $("#edit-node-tpl").html();
                var id = $(this).attr("data-id");
                var name = $(this).attr("data-name");
                var ip = $(this).attr("data-ip");
                var port = $(this).attr("data-port");
                var api_username = $(this).attr("data-api_username");
                var api_password = $(this).attr('data-api_password');

                var html = juicer(tpl, {
                    n: {
                        id: id,
                        name: name,
                        ip: ip,
                        port: port,
                        api_username: api_username,
                        api_password: api_password
                    }
                });

                var d = dialog({
                    title: "编辑节点",
                    width: 680,
                    content: html,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '保存修改',
                        autofocus: false,
                        callback: function() {

                            var name = $("input[name=name]").val();
                            var ip = $("input[name=ip]").val();
                            var port = parseInt($("input[name=port]").val());
                            var api_username = $("input[name=api_username]").val();
                            var api_password = $("input[name=api_password]").val();

                            var name_pattern = /^.{1,20}$/;
                            if (!name || !name.match(name_pattern)) {
                                L.Common.showErrorTip("提示", "节点名称为1~20位");
                                return false;
                            }

                            // var ip_pattern = /^\d+\.\d+\.\d+\.\d+$/;
                            // if (!ip || !ip.match(ip_pattern)) {
                            //     L.Common.showErrorTip("提示", "IP 格式不正确!");
                            //     return false;
                            // }

                            var port_pattern = /^\d+$/;
                            if (!port || isNaN(port) || port < 1 || port > 65535 || !port.toString().match(port_pattern)) {
                                L.Common.showErrorTip("提示", "端口为 1~65535 间的数字!");
                                return false;
                            }

                            $.ajax({
                                url: '/admin/node/modify',
                                type: 'post',
                                cache: false,
                                data: {
                                    id: id,
                                    name: name,
                                    ip: ip,
                                    port: port,
                                    api_username: api_username,
                                    api_password: api_password
                                },
                                dataType: 'json',
                                success: function(result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.renderTable(result.data, id); //渲染table
                                        _this.data.nodes = result.data.nodes; //重新设置数据
                                        L.Common.showTipDialog("提示", result.msg || "修改节点信息成功")
                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "编辑节点发生错误");
                                        return false;
                                    }
                                },
                                error: function() {
                                    L.Common.showErrorTip("提示", "编辑节点请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });
                d.show();
            });

            $('#reg-node-btn').click(function() {
                $.ajax({
                    url: '/admin/node/register',
                    type: 'post',
                    cache: false,
                    data: {},
                    dataType: 'json',
                    success: function(result) {
                        if (result.success) {
                            _this.renderTable(result.data); //渲染table
                            _this.data.nodes = result.data.nodes; //重新设置数据
                            L.Common.showTipDialog("提示", "注册节点请求已发送");
                        } else {
                            L.Common.showErrorTip("错误提示", "注册节点请求发生错误");
                        }
                    },
                    error: function() {
                        L.Common.showErrorTip("提示", "注册节点请求发生异常");
                    }
                });
            })


            $("#sync-node-btn").click(function() {
                var content = $("#sync-node-tpl").html()
                var d = dialog({
                    title: '同步 orange 节点',
                    width: 480,
                    content: content,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function() {

                            $.ajax({
                                url: '/admin/node/sync',
                                type: 'post',
                                cache: false,
                                data: {},
                                dataType: 'json',
                                success: function(result) {

                                    //重新渲染规则
                                    _this.renderTable(result.data); //渲染table
                                    _this.data.nodes = result.data.nodes; //重新设置数据

                                    L.Common.showTipDialog("提示", result.msg);
                                },
                                error: function() {
                                    L.Common.showErrorTip("提示", "同步 orange 节点请求发生异常");
                                    return false;
                                }
                            });

                        }
                    }]
                });
                d.show();
            });
        },


        loadNodes: function() {
            $.ajax({
                url: '/admin/nodes',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function(result) {
                    if (result.success) {
                        _this.renderTable(result.data); //渲染table
                        _this.data.nodes = result.data.nodes; //重新设置数据

                    } else {
                        L.Common.showErrorTip("错误提示", "查询节点请求发生错误");
                    }
                },
                error: function() {
                    L.Common.showErrorTip("提示", "查询节点请求发生异常");
                }
            });
        },

        initStatisticBtnEvent: function() {
            $(document).on("click", ".statistic-btn", function() {
                var self = $(this);
                var id = self.attr("data-id");
                var ip = self.attr("data-ip");
                if (!id) {
                    return;
                }
                window.location.href = "/admin/node/persist?id=" + id + '&ip=' + ip;
            });

        },

        renderTable: function(data, highlight_id) {
            highlight_id = highlight_id || 0;
            var tpl = $("#node-item-tpl").html();
            data.highlight_id = highlight_id;
            var html = juicer(tpl, data);
            $("#nodes").html(html);
        }
    };
}(APP));
