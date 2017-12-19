(function (L) {
    var _this = null;
    L.NodeManage = L.NodeManage || {};
    _this = L.NodeManage = {
        data: {},

        init: function () {
            _this.loadNodes();
            _this.initEvents();

        },

        initEvents: function () {
            $("#add-node-btn").click(function () {
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
                        callback: function () {
                            var name = $("input[name=name]").val();
                            var ip = $("input[name=ip]").val();
                            var port = $("input[name=port]").val();
                            var api_username = $("input[name=api_username]").val();
                            var api_password = $("input[name=api_password]").val();

                            var pattern = /^[A-Za-z][A-Za-z0-9_]+$/;
                            if (!name || name.length < 1 || name.length > 20 || !name.match(pattern)) {
                                L.Common.showErrorTip("提示", "节点名称为1~20位, 只能输入字母、下划线、数字，必须以字母开头.");
                                return false;
                            }

                            var ipPattern = /^\d{1,3}(\.\d{1,3}){3}$/;
                            if (!ip || ip.length < 7 || ip.length > 15 || !(ipPattern.test(ip))) {
                                L.Common.showErrorTip("提示", "IP 长度须为7~15位!");
                                return false;
                            }

                            if (!port || port < 1 || port > 65535) {
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
                                success: function (result) {
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
                                error: function () {
                                    L.Common.showErrorTip("提示", "添加用户请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });
                d.show();
            });

            $(document).on("click", ".delete-node-btn", function () {
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
                        callback: function () {
                            $.ajax({
                                url: '/admin/node/delete',
                                type: 'post',
                                cache: false,
                                data: {
                                    id: id
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.renderTable(result.data); //渲染table
                                        _this.data.nodes = result.data.nodes; //重新设置数据

                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除节点发生错误");
                                        return false;
                                    }
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "删除节点请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });

                d.show();
            });

            $(document).on("click", ".edit-node-btn", function () {
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
                        callback: function () {

                            var name = $("input[name=name]").val();
                            var ip = $("input[name=ip]").val();
                            var port = $("input[name=port]").val();
                            var api_username = $("input[name=api_username]").val();
                            var api_password = $("input[name=api_password]").val();

                            var pattern = /^[A-Za-z][A-Za-z0-9_]+$/;
                            if (!name || name.length < 1 || name.length > 20 || !name.match(pattern)) {
                                L.Common.showErrorTip("提示", "节点名称为1~20位, 只能输入字母、下划线、数字，必须以字母开头.");
                                return false;
                            }
                            
                            var ipPattern = /^\d{1,3}(\.\d{1,3}){3}$/;
                            if (!ip || ip.length < 7 || ip.length > 15 || !(ipPattern.test(ip))) {
                                L.Common.showErrorTip("提示", "IP 长度须为7~15位!");
                                return false;
                            }

                            if (!port || port < 1 || port > 65535) {
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
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.renderTable(result.data, id); //渲染table
                                        _this.data.nodes = result.data.nodes; //重新设置数据

                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "编辑节点发生错误");
                                        return false;
                                    }
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "编辑节点请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });
                d.show();
            });


            $("#sync-node-btn").click(function () {
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
                        callback: function () {

                            $.ajax({
                                url: '/admin/node/sync',
                                type: 'post',
                                cache: false,
                                data: {},
                                dataType: 'json',
                                success: function (result) {
                                    L.Common.showTipDialog("提示", result.msg);
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "添加用户请求发生异常");
                                    return false;
                                }
                            });

                        }
                    }]
                });
                d.show();
            });
        },


        loadNodes: function () {
            $.ajax({
                url: '/admin/nodes',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        _this.renderTable(result.data); //渲染table
                        _this.data.nodes = result.data.nodes; //重新设置数据

                    } else {
                        L.Common.showTipDialog("错误提示", "查询节点请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询节点请求发生异常");
                }
            });
        },

        renderTable: function (data, highlight_id) {
            console.log(data, highlight_id);

            highlight_id = highlight_id || 0;
            var tpl = $("#node-item-tpl").html();
            data.highlight_id = highlight_id;
            var html = juicer(tpl, data);
            $("#nodes").html(html);
        }
    };
}(APP));
