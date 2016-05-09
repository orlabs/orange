(function (L) {
    var _this = null;
    L.UserManage = L.UserManage || {};
    _this = L.UserManage = {
        data: {
        },

        init: function () {
            _this.loadUsers();
            _this.initEvents();

        },

        initEvents: function () {
            $("#add-user-btn").click(function(){
                var content = $("#add-user-tpl").html()
                var d = dialog({
                    title: '添加Dashboard用户',
                    width: 480,
                    content: content,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function () {
                            var username =$("input[name=username]").val();
                            var password = $("input[name=password]").val();

                            var pattern = /^[A-Za-z][A-Za-z0-9_]+$/;
                            if(!username || username.length<4 || username.length>50 || !username.match(pattern)) {
                                L.Common.showErrorTip("提示", "用户名为4~50位, 只能输入字母、下划线、数字，必须以字母开头.");
                                return false;
                            }

                            if(!password || password.length<6 || password.length>50){
                                L.Common.showErrorTip("提示", "密码长度须为6~50位!");
                                return false;
                            }

                            var enable = $('input[name=enable]').is(':checked');
                            if(enable){
                                enable = 1;
                            }else{
                                enable = 0;
                            }
                       
                            $.ajax({
                                url: '/admin/user/new',
                                type: 'post',
                                cache: false,
                                data: {
                                    username: username,
                                    password: password,
                                    enable: enable
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则

                                        _this.data.users = result.data.users;//重新设置数据
                                        _this.renderTable(result.data, _this.data.users[_this.data.users.length - 1].id);//渲染table
                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "添加用户发生错误");
                                        return false;
                                    }
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "添加用户请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }
                    ]
                });
                d.show();
            });

            $(document).on("click", ".delete-user-btn", function(){
                var user_id = $(this).attr("data-id");
                var name = $(this).attr("data-name");
                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除用户【" + name + "】吗?",
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function () {
                            $.ajax({
                                url: '/admin/user/delete',
                                type: 'post',
                                cache:false,
                                data: {
                                    user_id: user_id
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.renderTable(result.data);//渲染table
                                        _this.data.users = result.data.users;//重新设置数据

                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除用户发生错误");
                                        return false;
                                    }
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "删除用户请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });

                d.show();
            });

            $(document).on("click", ".edit-user-btn", function () {
                var tpl = $("#edit-user-tpl").html();
                var user_id = $(this).attr("data-id");
                var username = $(this).attr("data-name");
                var enable = $(this).attr("data-enable");


                var html = juicer(tpl, {
                    u: {
                        username:username,
                        enable:enable
                    }
                });

                var d = dialog({
                    title: "编辑用户",
                    width: 680,
                    content: html,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '保存修改',
                        autofocus: false,
                        callback: function () {
                            var new_pwd = $("input[name=password]").val();

                            if(!new_pwd || new_pwd==""){
                               new_pwd=""
                            }else{
                                if(new_pwd.length<6 || new_pwd.length>50){
                                    L.Common.showErrorTip("提示", "新密码长度须为6~50位!");
                                    return false;
                                }
                            }

                            var enable = $('input[name=enable]').is(':checked');
                            if(enable){
                                enable = 1;
                            }else{
                                enable = 0;
                            }

                            $.ajax({
                                url: '/admin/user/modify',
                                type: 'post',
                                cache:false,
                                data: {
                                    user_id: user_id,
                                    new_pwd: new_pwd,
                                    enable: enable
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        //重新渲染规则
                                        _this.renderTable(result.data, user_id);//渲染table
                                        _this.data.users = result.data.users;//重新设置数据

                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "编辑用户发生错误");
                                        return false;
                                    }
                                },
                                error: function () {
                                    L.Common.showErrorTip("提示", "编辑用户请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }
                    ]
                });
                d.show();
            });
        },
       
  
        loadUsers: function () {
            $.ajax({
                url: '/admin/users',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function (result) {
                    if (result.success) {
                        _this.renderTable(result.data);//渲染table
                        _this.data.users = result.data.users;//重新设置数据

                    } else {
                        L.Common.showTipDialog("错误提示", "查询Dashboard用户请求发生错误");
                    }
                },
                error: function () {
                    L.Common.showTipDialog("提示", "查询Dashboard用户请求发生异常");
                }
            });
        },

        renderTable: function (data, highlight_id) {
            highlight_id = highlight_id || 0;
            var tpl = $("#user-item-tpl").html();
            data.highlight_id = highlight_id;
            var html = juicer(tpl, data);
            $("#users").html(html);
        }
    };
}(APP));