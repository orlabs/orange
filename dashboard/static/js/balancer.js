(function (L) {
    var _this = null;
    L.Balancer = L.Balancer || {};
    _this = L.Balancer = {
        data: {
        },

        init: function () {
            L.Common.loadConfigs("balancer", _this, true);
            _this.initEvents();
        },

        initEvents: function () {
            var op_type = "balancer";

            _this.initUpstreamAddDialog(_this);         //添加Upstream对话框
            _this.initUpstreamDeleteDialog(_this);      //删除Upstream对话框
            _this.initUpstreamEditDialog(_this);        //编辑Upstream对话框
            _this.initUpstreamClickEvent(_this);        //点击Upstream显示对应的Host列表

            _this.initHostAddDialog(_this);             //添加Host对话框
            _this.initHostDeleteDialog(_this);          //删除Host对话框
            _this.initHostEditDialog(_this);            //编辑Host对话框

            L.Common.initViewAndDownloadEvent(op_type, _this);  // 数据视图转换和下载事件
            L.Common.initSyncDialog(op_type, _this);            //同步配置对话框
            L.Common.initSwitchBtn(op_type, _this);     //redirect关闭、开启
        },

        initUpstreamAddDialog: function(context) {
            $("#add-selector-btn").click(function() {
                var current_selected_id;
                var current_selected_selector = $("#selector-list li.selected-selector");
                if (current_selected_selector) {
                    current_selected_id = $(current_selected_selector[0]).attr("data-id");
                }

                var content = $("#add-selector-tpl").html();
                var d = dialog({
                    title: '添加Upstream',
                    width: 680,
                    content: content,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '预览',
                        autofocus: false,
                        callback: function() {
                            var s = _this.buildUpstream();
                            _this.showPreview("upstream", s);
                            return false;
                        }
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function() {
                            var result = _this.buildUpstream();

                            if (result.success) {
                                $.ajax({
                                    url: '/balancer/selectors',
                                    type: 'post',
                                    data: {
                                        selector: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function(result) {
                                        if (result.success) {
                                            // 重新渲染
                                            L.Common.loadConfigs("balancer", context, false, function() {
                                                $("#selector list li[data-id=" + current_selected_id + "]").addClass("selected-selector");
                                            });
                                            return true;
                                        } else {
                                            L.Comman.showErrorTip("提示", result.msg || "添加Upstream发生错误");
                                            return false;
                                        }
                                    }
                                });
                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }

                        }

                    }]
                });

                d.show();
            });
        },

        initUpstreamDeleteDialog: function (context) {
            $(document).on("click", ".delete-selector-btn", function(e) {
                e.stopPropagation();    // 阻止冒泡
                var name = $(this).attr("data-name");
                var selector_id = $(this).attr("data-id");
                if (!selector_id) {
                    L.Common.showErrorTip("提示", "参数错误，要删除的Upstream不存在！");
                    return;
                }

                var current_selected_id;
                var current_selected_selector = $("#selector-list li.selected-selector");
                if (current_selected_selector) {
                    current_selected_id = $(current_selected_selector[0]).attr("data-id");
                }

                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除Upstream【" + name + "】吗？删除Upstream将同时删除它的所有Host!",
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function () {
                            $.ajax({
                                url: '/balancer/selectors',
                                type: 'delete',
                                data: {
                                    selector_id: selector_id
                                },
                                dataType: 'json',
                                success: function (result) {
                                    if (result.success) {
                                        // 重新渲染
                                        L.Common.loadConfigs("balancer", context, false, function() {
                                            // 删除的是原来选中的Upstream，重新选中第一个
                                            if (current_selected_id == selector_id) {
                                                var selector_list = $("#selector-list li");
                                                if (selector_list && selector_list.length > 0) {
                                                    $(selector_list[0]).click();
                                                } else {
                                                    _this.emptyHosts();
                                                }
                                            } else {
                                                if (current_selected_id) {
                                                    $("#selector-list li[data-id=" + current_selected_id + "]").addClass("selected-selector");
                                                } else {
                                                    _this.emptyHosts();
                                                }
                                            }
                                        });

                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除Upstream发生错误");
                                        return false;
                                    }
                                },
                                error: function() {
                                    L.Common.showErrorTip("提示", "删除Upstream请求发生异常");
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

        initUpstreamEditDialog: function(context) {
            $(document).on("click", ".edit-selector-btn", function(e) {
                e.stopPropagation(); // 阻止冒泡
                var tpl = $("#edit-selector-tpl").html();
                var selector_id = $(this).attr("data-id");
                var selectors = context.data.selectors;
                selector = selectors[selector_id];

                if (!selector_id || !selector) {
                    L.Common.showErrorTip("提示", "要编辑的Upstream不存在或者查找出错");
                    return;
                }

                var html = juicer(tpl, {
                    s: selector
                });

                var d = dialog({
                    title: "编辑Upstream",
                    width: 680,
                    content: html,
                    model: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '预览',
                        autofocus: false,
                        callback: function() {
                            var s = _this.buildUpstream();
                            _this.showPreview("upstream", s);
                            return false;
                        }
                    }, {
                        value: '保存修改',
                        autofocus: false,
                        callback: function() {
                            var result = _this.buildUpstream();
                            result.data.id = selector.id; //拼上要修改的id
                            result.data.rules = selector.rules;//拼上已有的rules

                            if (result.success == true) {
                                $.ajax({
                                    url: 'balancer/selectors',
                                    type: 'put',
                                    data: {
                                        selector: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function(result) {
                                        if (result.success) {
                                            //重新渲染
                                            L.Common.loadConfigs("balancer", context);
                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "编辑Upstream发生错误");
                                            return false;
                                        }
                                    },
                                    error: function() {
                                        L.Common.showErrorTip("提示", "编辑Upstream请求发生异常");
                                        return false;
                                    }
                                });
                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }
                        }
                    }]
                });

                d.show();
            });
        },

        initUpstreamClickEvent: function(context) {
            $(document).on("click", ".selector-item", function() {
                var self = $(this);
                var selector_id = self.attr("data-id");
                var selector_name = self.attr("data-name");
                if (selector_name) {
                    $("#rules-section-header").text("Upstream【" + selector_name + "】hosts 列表");
                }

                $(".selector-item").each(function() {
                    $(this).removeClass("selected-selector");
                })
                self.addClass("selected-selector");

                $("#add-btn").attr("data-id", selector_id);
                _this.loadHosts(context, selector_id);
            });
        },

        initHostAddDialog: function(context) {
            var rules_key = "rules";

            $("#add-btn").click(function() {
                var selector_id = $("#add-btn").attr("data-id");
                if (!selector_id) {
                    L.Common.showErrorTip("错误提示", "添加host前请先选择【Upstream】!");
                    return;
                }
                var content = $("#add-tpl").html()
                var d = dialog({
                    title: "添加Host",
                    width: 720,
                    content: content,
                    model: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '预览',
                        autofocus: false,
                        callback: function() {
                            var host = _this.buildHost();
                            _this.showPreview("host", host);
                            return false;
                        }
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function() {
                            var result = _this.buildHost();
                            if (result.success == true) {
                                $.ajax({
                                    url: '/balancer/selectors/' + selector_id + "/rules",
                                    type: 'post',
                                    data: {
                                        rule: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function(result) {
                                        if (result.success) {
                                            // 重新渲染host
                                            _this.loadHosts(context, selector_id);
                                            // 刷新缓存
                                            L.Common.refreshConfigs("balancer", context);
                                        } else {
                                            L.Common.showErrorTip("提示", "添加Host发生错误");
                                            return false;
                                        }
                                    },
                                    error: function() {
                                        L.Common.showErrorTip("提示", "添加Host请求发生异常");
                                        return false;
                                    }
                                });
                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }
                        }
                    }]
                });

                d.show();
            })
        },

        initHostDeleteDialog: function(context) {
            $(document).on("click", ".delete-btn", function() {
                var name = $(this).attr("data-name");
                var rule_id = $(this).attr("data-id");
                var selector_id = $("#add-btn").attr("data-id");

                var d = dialog({
                    title: '提示',
                    width: 480,
                    content: "确定要删除Host【" + name+ "】吗？",
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '确定',
                        autofocus: false,
                        callback: function() {
                            $.ajax({
                                url: '/balancer/selectors/' + selector_id + '/rules',
                                type: 'delete',
                                data: {
                                    rule_id: rule_id
                                },
                                dataType: 'json',
                                success: function(result) {
                                    if (result.success) {
                                        // 重新渲染规则
                                        _this.loadHosts(context, selector_id);
                                        // 刷新本地缓存
                                        L.Common.refreshConfigs("balancer", context);
                                        return true;
                                    } else {
                                        L.Common.showErrorTip("提示", result.msg || "删除Host发生错误");
                                        return false;
                                    }
                                },
                                error: function() {
                                    L.Common.showErrorTip("提示", "删除Host请求发生异常");
                                    return false;
                                }
                            });
                        }
                    }]
                });
                d.show();
            });
        },

        initHostEditDialog: function(context) {
            $(document).on("click", ".edit-btn", function() {
                var selector_id = $("#add-btn").attr("data-id");

                var tpl = $("#edit-tpl").html();
                var rule_id = $(this).attr("data-id");
                var rule = {};
                var rules = context.data.selector_rules[selector_id];

                for (var i = 0; i < rules.length; i++) {
                    var r = rules[i];
                    if (r.id == rule_id) {
                        rule = r;
                        break;
                    }
                }

                if (!rule_id || !rule) {
                    L.Common.showErrorTip("提示", "要编辑的Host不存在或者查找出错");
                    return;
                }

                var html = juicer(tpl, {
                    r: rule
                });

                var d = dialog({
                    title: "编辑Host",
                    width: 680,
                    content: html,
                    modal: true,
                    button: [{
                        value: '取消'
                    }, {
                        value: '预览',
                        autofocus: false,
                        callback: function() {
                            var host = _this.buildHost();
                            _this.showPreview("host", host);
                            return false;
                        }
                    }, {
                        value: '保存修改',
                        autofocus: false,
                        callback: function() {
                            var result = _this.buildHost();
                            result.data.id = rule.id; // 拼上要修改的id

                            if (result.success == true) {
                                $.ajax({
                                    url: '/balancer/selectors/' + selector_id + '/rules',
                                    type: 'put',
                                    data: {
                                        rule: JSON.stringify(result.data)
                                    },
                                    dataType: 'json',
                                    success: function(result) {
                                        if (result.success) {
                                            // 重新渲染Hosts
                                            _this.loadHosts(context, selector_id);
                                            return true;
                                        } else {
                                            L.Common.showErrorTip("提示", result.msg || "编辑Host发生错误");
                                            return false;
                                        }
                                    },
                                    error: function() {
                                        L.Common.showErrorTip("提示", "编辑Host请求发生异常");
                                        return false;
                                    }
                                });
                            } else {
                                L.Common.showErrorTip("错误提示", result.data);
                                return false;
                            }
                        }
                    }]
                });
                d.show();
            });
        },

        loadHosts: function(context, selector_id) {
            $.ajax({
                url: '/balancer/selectors/' + selector_id + '/rules',
                type: 'get',
                cache: false,
                data: {},
                dataType: 'json',
                success: function(result) {
                    if (result.success) {
                        $("view-btn").show();

                        // 重新设置数据
                        context.data.selector_rules = context.data.selector_rules || {};
                        context.data.selector_rules[selector_id] = result.data.rules;
                        _this.renderHosts(result.data);
                    } else {
                        L.Common.showErrorTip("错误提示", "查询 balancer 规则发生错误");
                    }
                },
                error: function() {
                    L.Common.showErrorTip("提示", "查询 balancer 规则发生异常");
                }
            });
        },

        renderHosts: function(data) {
            data = data || {};
            if (!data.rules || data.rules.length < 1) {
                var html = '<div class="alert alert-warning" style="margin: 25px 0 10px 0;">'+
                        '<p>该Upstream下没有Host,请添加!</p>'+
                '</div>';
                $("#rules").html(html);
            } else {
                var tpl = $("#rule-item-tpl").html();
                var html = juicer(tpl, data);
                $("#rules").html(html);
            }
        },

        emptyHosts: function() {
            $("#rules-section-header").text("Upstream-hosts 列表")
            $("#rules").html("");
            $("#add-btn").removeAttr("data-id");
        },

        showPreview: function(type, json_data) {
            var content = "";

            if (json_data.success == true) {
                content = '<pre id="preview_data"><code></code></pre>';
            } else {
                content = json_data.data;
            }

            var d = dialog({
                title: type + ' 预览',
                width: 500,
                content: content,
                modal: true,
                button: [{
                    value: '返回',
                    callback: function() {
                        d.close().remove();
                    }
                }]
            });
            d.show();

            $("#preview_data code").text(JSON.stringify(json_data.data, null, 2));
            $('pre code').each(function() {
                hljs.highlightBlock($(this)[0]);
            });
        },


        buildUpstream: function() {
            var result = {
                success: false,
                data: {
                    name: null,
                    connection_timeout: 60000,
                    read_timeout: 60000,
                    send_timeout: 60000,
                    retries: 3,
                    slots: 1000
                }
            };

            // build name
            var name = $("#selector-name").val();
            if (!name) {
                result.success = false;
                result.data = "名称不能为空";
                return result;
            }
            result.data.name = name;

            var connection_timeout = $("#selector-connection-timeout").val();
            if (!connection_timeout) {
                // do nothing and use the default 60000
            } else if (isNaN(connection_timeout)) {
                result.success = false;
                result.data = "connection-timeout 应该为整数";
                return result;
            } else {
                result.data.connection_timeout = Math.abs(parseInt(connection_timeout));
            }

            var read_timeout = $("#selector-read-timeout").val();
            if (!read_timeout) {
                // do noting and use the default 60000
            } else if (isNaN(read_timeout)) {
                result.success = false;
                result.data = "read-timout 应该为整数";
                return result;
            } else {
                result.data.read_timeout = Math.abs(parseInt(read_timeout));
            }

            var send_timeout = $("#selector-send-timeout").val();
            if (!send_timeout) {
                // do nothing and use the default 60000
            } else if (isNaN(send_timeout)) {
                result.success = false;
                result.data = "send-timeout 应该为整数";
                return result;
            } else {
                result.data.send_timeout = Math.abs(parseInt(send_timeout));
            }

            var retries = $("#selector-retries").val();
            if (!retries) {
                // keep the default
            } else if (isNaN(retries)) {
                result.success = false;
                result.data = "retries 应该为整数";
                return result;
            } else {
                result.data.retries = Math.abs(parseInt(retries));
            }

            var slots = $("#selector-slots").val();
            if (!slots) {
                // keep the default
            } else if (isNaN(slots)) {
                result.success = false;
                result.data = "slots 应该为整数";
                return result;
            } else {
                result.data.slots = Math.abs(parseInt(slots));
            }

            var enable = $('#selector-enable').is(':checked');
            result.data.enable = enable;

            result.success = true;
            return result;
        },

        buildHost: function () {
            var result = {
                success: false,
                data: {
                    target: null,
                    weight: 10
                }
            };

            var target = $("#rule-name").val();
            if (!target) {
                result.data = "Host target不能为空";
                return result;
            }
            result.data.target = target;

            var weight = $("#rule-weight").val();
            if (!weight) {
                // keep the default
            } else if (isNaN(weight)) {
                result.data = "weight 应该为整数";
                return result;
            } else {
                result.data.weight = Math.abs(parseInt(weight));
            }

            var enable = $("#rule-enable").is(':checked');
            result.data.enable = enable;

            result.success = true;
            return result;
        },
    };
}(APP));
