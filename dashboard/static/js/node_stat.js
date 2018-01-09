(function (L) {
    var _this = null;
    L.NodeStat = L.NodeStat || {};
    _this = L.NodeStat = {
        data: {
            timer: null,
            requestChart: null,
            qpsChart: null,
            responseChart: null,
            trafficChart: null,
            interval: 3000
        },

        init: function () {
            _this.initRequestStatus();
            _this.initQPSStatus();
            _this.initReponseStatus();
            _this.initTrafficStatus();

            _this.startTimer();

            $("#time-set a").click(function () {
                $("#time-set a").each(function () {
                    $(this).removeClass("active")
                });

                $(this).addClass("active");
            });

            $(document).on("click", ".timer_interval", function () {
                var interval = parseInt($(this).attr("data-interval"));
                _this.data.interval = interval;
                _this.startTimer(interval);
            });
        },


        startTimer: function (interval) {
            interval = interval || 3000;//默认3s请求一次
            if (_this.data.timer) {
                clearInterval(_this.data.timer);
            }

            function format_date(s) {
                var time = new Date(s);
                var hour = time.getHours();
                var min = time.getMinutes();

                hour = hour < 10 ? '0' + hour : hour
                min = min < 10 ? '0' + min : min

                return hour + ':' + min;
            }


            $.ajax({
                url: '/admin/node/stat',
                type: 'get',
                cache: false,
                data: {
                    ip: $("#ip-input").val()
                },
                dataType: 'json',
                success: function (result) {
                    if (result.success) {

                        var data = result.data || {};

                        //request 统计
                        var requestOption = _this.data.requestChart.getOption();
                        var qpsOption = _this.data.qpsChart.getOption();
                        var responseOption = _this.data.responseChart.getOption();
                        var trafficOption = _this.data.trafficChart.getOption();

                        for (var i = 0; i < data.length; i++) {

                            // request
                            requestOption.series[0].data.push(data[i].total_request_count);
                            requestOption.series[1].data.push(data[i].request_2xx);
                            requestOption.series[2].data.push(data[i].request_3xx);
                            requestOption.series[3].data.push(data[i].request_4xx);
                            requestOption.series[4].data.push(data[i].request_5xx);

                            // qps
                            qpsOption.series[0].data.push(data[i].total_success_request_count / 60);

                            // response
                            responseOption.series[0].data.push(data[i].total_request_time);

                            // traffice
                            trafficOption.series[0].data.push(data[i].traffic_read);
                            trafficOption.series[1].data.push(data[i].traffic_write);

                            var op_time = format_date(data[i].op_time);

                            console.log(op_time);

                            requestOption.xAxis[0].data.push(op_time);
                            qpsOption.xAxis[0].data.push(op_time);
                            responseOption.xAxis[0].data.push(op_time);
                            trafficOption.xAxis[0].data.push(op_time);
                        }

                        _this.data.requestChart.setOption(requestOption);
                        _this.data.qpsChart.setOption(qpsOption);
                        _this.data.responseChart.setOption(responseOption);
                        _this.data.trafficChart.setOption(trafficOption);

                        //
                        // //请求时间统计
                        // var responseOption = _this.data.responseChart.getOption();
                        // data0 = responseOption.series[0].data;
                        // data1 = responseOption.series[1].data;
                        // data0.shift();
                        // data0.push(data.total_request_time);
                        // data1.shift();
                        // data1.push(data.average_request_time * 1000);
                        // responseOption.xAxis[0].data.shift();
                        // responseOption.xAxis[0].data.push(axisData);
                        // _this.data.responseChart.setOption(responseOption);
                        //
                        // //流量统计
                        // var trafficOption = _this.data.trafficChart.getOption();
                        // data0 = trafficOption.series[0].data;
                        // data1 = trafficOption.series[1].data;
                        // data2 = trafficOption.series[2].data;
                        // data3 = trafficOption.series[3].data;
                        // data0.shift();
                        // data0.push(Math.round(data.traffic_read / 1024));
                        // data1.shift();
                        // data1.push(Math.round(data.traffic_write / 1024));
                        // data2.shift();
                        // data2.push(Math.round(data.average_traffic_read));
                        // data3.shift();
                        // data3.push(Math.round(data.average_traffix_write));
                        // trafficOption.xAxis[0].data.shift();
                        // trafficOption.xAxis[0].data.push(axisData);
                        // _this.data.trafficChart.setOption(trafficOption);

                    } else {
                        APP.Common.showTipDialog("错误提示", result.msg);
                        try_times--;
                        if (try_times < 0) {
                            clearInterval(_this.data.timer);
                            APP.Common.showTipDialog("错误提示", "查询请求发生错误次数太多，停止查询");
                        }
                    }
                },
                error: function () {
                    try_times--;
                    if (try_times < 0) {
                        clearInterval(_this.data.timer);
                        APP.Common.showTipDialog("错误提示", "查询请求发生异常次数太多，停止查询");

                    } else {
                        APP.Common.showTipDialog("提示", "查询请求发生异常");
                    }

                }
            });

        },

        initRequestStatus: function () {
            var option = {
                title: {
                    text: '请求统计',
                    subtext: '',
                    left: '10px'
                },
                grid: {
                    left: '20px',
                    right: '20px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip: {
                    trigger: 'axis'
                },
                legend: {
                    data: ['全部请求', '2xx请求', '3xx请求', '4xx请求', '5xx请求']
                },
                toolbox: {
                    show: true,
                    right: "20px",
                    feature: {
                        dataView: {readOnly: false},
                        saveAsImage: {}
                    }
                },
                xAxis: [
                    {
                        type: 'category',
                        boundaryGap: false,
                        data: [],
                    }
                ],
                yAxis: [
                    {
                        type: 'value',
                        scale: true,
                        name: '次数'
                    }
                ],
                series: [
                    {
                        name: '全部请求',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#03A1F7'
                            }
                        },
                        data: []
                    },
                    {
                        name: '2xx请求',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#269EBD'
                            }
                        },
                        data: []
                    },
                    {
                        name: '3xx请求',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#F75903'
                            }
                        },
                        data: []
                    },
                    {
                        name: '4xx请求',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#1C9361'
                            }
                        },
                        data: []
                    },
                    {
                        name: '5xx请求',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#F75903'
                            }
                        },
                        data: []
                    }
                ]
            };

            var requestChart = echarts.init(document.getElementById('request-area'));
            requestChart.setOption(option);
            _this.data.requestChart = requestChart;
        },

        initQPSStatus: function () {
            var option = {
                title: {
                    text: 'QPS统计',
                    subtext: '',
                    left: '26px'
                },
                grid: {
                    left: '33px',
                    right: '33px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip: {
                    trigger: 'axis'
                },
                legend: {
                    data: ['QPS']
                },
                toolbox: {
                    show: true,
                    right: "34px",
                    feature: {
                        dataView: {readOnly: false},
                        saveAsImage: {}
                    }
                },
                xAxis: [
                    {
                        type: 'category',
                        boundaryGap: false,
                        data: [],
                    }
                ],
                yAxis: [
                    {
                        type: 'value',
                        scale: true,
                        name: 'Query'
                    }
                ],
                series: [
                    {
                        name: 'QPS',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#ECA047'
                            }
                        },
                        areaStyle: {normal: {}},
                        data: []
                    }
                ]
            };

            var qpsChart = echarts.init(document.getElementById('qps-area'));
            qpsChart.setOption(option);
            _this.data.qpsChart = qpsChart;
        },

        initReponseStatus: function () {
            var option = {
                title: {
                    text: '请求时间统计',
                    left: '10px',
                    subtext: ''
                },
                grid: {
                    left: '15px',
                    right: '10px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip: {
                    trigger: 'axis'
                },
                legend: {
                    data: ['总时间(s)', '平均响应时间(ms)']
                },
                xAxis: [
                    {
                        type: 'category',
                        boundaryGap: false,
                        data: [],
                    }
                ],
                yAxis: [
                    {
                        type: 'value',
                        scale: true,
                        name: ''
                    }
                ],
                series: [
                    {
                        name: '总时间(s)',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#8E704F'
                            }
                        },
                        data: []
                    },
                    {
                        name: '平均响应时间(ms)',
                        type: 'line',
                        itemStyle: {
                            normal: {
                                color: '#AD8EAD'
                            }
                        },
                        data: []
                    }
                ]
            };

            var responseChart = echarts.init(document.getElementById('response-area'));
            responseChart.setOption(option);
            _this.data.responseChart = responseChart;
        },

        initTrafficStatus: function () {
            var option = {
                title: {
                    text: '流量统计',
                    subtext: ''
                },
                grid: {
                    left: '15px',
                    right: '10px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip: {
                    trigger: 'axis'
                },
                legend: {
                    data: ['总入(kb)', '总出(kb)', '均入(bytes)', '均出(bytes)']
                },
                xAxis: [
                    {
                        type: 'category',
                        boundaryGap: false,
                        data: [],
                    }
                ],
                yAxis: [
                    {
                        type: 'value',
                        scale: true,
                        name: ''
                    }
                ],
                series: [
                    {
                        name: '总入(kb)',
                        type: 'line',
                        smooth: true,
                        data: []
                    }, {
                        name: '总出(kb)',
                        type: 'line',
                        data: []
                    }, {
                        name: '均入(bytes)',
                        type: 'line',
                        data: (function () {
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    }, {
                        name: '均出(bytes)',
                        type: 'line',
                        data: []
                    }
                ]
            };

            var trafficChart = echarts.init(document.getElementById('traffic-area'));
            trafficChart.setOption(option);
            _this.data.trafficChart = trafficChart;
        },

    };
}(APP));
