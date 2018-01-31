(function(L) {
    var _this = null;
    L.PersistStat = L.PersistStat || {};
    _this = L.PersistStat = {
        data: {
            timer: null,
            requestChart: null,
            qpsChart: null,
            responseChart: null,
            trafficChart: null,
            interval: 10 * 1000,
            minutes: 15
        },

        init: function() {
            _this.initRequestStatus();
            _this.initQPSStatus();
            _this.initReponseStatus();
            _this.initTrafficStatus();

            _this.startTimer();

            var op_type = "persist";
            L.Common.loadConfigs("persist", _this, true);
            L.Common.initSwitchBtn(op_type, _this); //关闭、开启

            $("#time-set a").click(function() {
                $("#time-set a").each(function() {
                    $(this).removeClass("active")
                });

                $(this).addClass("active");
            });

            $(document).on("click", ".timer_interval", function() {
                var interval = parseInt($(this).attr("data-interval"));
                _this.data.interval = interval;
                _this.startTimer(interval);
            });

            $(document).on("click", ".time_range", function() {
                var minutes = parseInt($(this).attr("data-minutes"));
                _this.data.minutes = minutes;
                _this.getStatistic();
            });


        },


        startTimer: function() {

            if (_this.data.timer) {
                clearInterval(_this.data.timer);
            }

            setInterval(_this.getStatistic, _this.data.interval);

            _this.getStatistic();

        },

        formatDate: function(s) {
            return s.substr(0, s.length - 2) + '00';

            var time = new Date(s);
            var hour = time.getHours();
            var min = time.getMinutes();

            hour = hour < 10 ? '0' + hour : hour
            min = min < 10 ? '0' + min : min
            return hour + ':' + min;
        },

        getStatistic: function() {

            var seconds = 60;

            if (_this.data.minutes > 2880) {
                seconds = 86400;
            }

            var data = {
                minutes: _this.data.minutes
            };

            var ip = $("#ip-input").val();

            if (ip != '') {
                data['ip'] = ip;
            }

            var try_times;

            $.ajax({
                url: '/persist/statistic',
                type: 'get',
                cache: false,
                data: data,
                dataType: 'json',
                success: function(result) {
                    if (result.success) {

                        var data = result.data || {};

                        //request 统计
                        var requestOption = _this.data.requestChart.getOption();
                        var qpsOption = _this.data.qpsChart.getOption();
                        var responseOption = _this.data.responseChart.getOption();
                        var trafficOption = _this.data.trafficChart.getOption();

                        requestOption.series[0].data = [];
                        requestOption.series[1].data = [];
                        requestOption.series[2].data = [];
                        requestOption.series[3].data = [];
                        requestOption.series[4].data = [];

                        qpsOption.series[0].data = [];

                        responseOption.series[0].data = [];
                        responseOption.series[1].data = [];

                        trafficOption.series[0].data = [];
                        trafficOption.series[1].data = [];

                        requestOption.xAxis[0].data = [];
                        qpsOption.xAxis[0].data = [];
                        responseOption.xAxis[0].data = [];
                        trafficOption.xAxis[0].data = [];


                        for (var i = data.length - 1; i >= 0; i--) {

                            // request
                            requestOption.series[0].data.push(data[i].total_request_count);
                            requestOption.series[1].data.push(data[i].request_2xx);
                            requestOption.series[2].data.push(data[i].request_3xx);
                            requestOption.series[3].data.push(data[i].request_4xx);
                            requestOption.series[4].data.push(data[i].request_5xx);

                            // qps
                            qpsOption.series[0].data.push(data[i].total_request_count / seconds);

                            // response
                            responseOption.series[0].data.push(data[i].total_request_time);
                            responseOption.series[1].data.push(data[i].total_request_time / data[i].total_request_count);

                            // traffic
                            trafficOption.series[0].data.push(data[i].traffic_read / 1024);
                            trafficOption.series[1].data.push(data[i].traffic_write / 1024);

                            var op_time = (data[i].stat_time);

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
                error: function() {
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
        initRequestStatus: function() {
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
                        dataView: { readOnly: false },
                        saveAsImage: {}
                    }
                },
                xAxis: [{
                    type: 'category',
                    boundaryGap: false,
                    data: [],
                }],
                yAxis: [{
                    type: 'value',
                    scale: true,
                    name: '次数'
                }],
                series: [{
                    name: '全部请求',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#03A1F7'
                        }
                    },
                    data: []
                }, {
                    name: '2xx请求',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#269EBD'
                        }
                    },
                    data: []
                }, {
                    name: '3xx请求',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#F75903'
                        }
                    },
                    data: []
                }, {
                    name: '4xx请求',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#1C9361'
                        }
                    },
                    data: []
                }, {
                    name: '5xx请求',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#F75903'
                        }
                    },
                    data: []
                }]
            };

            var requestChart = echarts.init(document.getElementById('request-area'));
            requestChart.setOption(option);
            _this.data.requestChart = requestChart;
        },

        initQPSStatus: function() {
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
                        dataView: { readOnly: false },
                        saveAsImage: {}
                    }
                },
                xAxis: [{
                    type: 'category',
                    boundaryGap: false,
                    data: [],
                }],
                yAxis: [{
                    type: 'value',
                    scale: true,
                    name: 'Query'
                }],
                series: [{
                    name: 'QPS',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#ECA047'
                        }
                    },
                    areaStyle: { normal: {} },
                    data: []
                }]
            };

            var qpsChart = echarts.init(document.getElementById('qps-area'));
            qpsChart.setOption(option);
            _this.data.qpsChart = qpsChart;
        },

        initReponseStatus: function() {
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
                xAxis: [{
                    type: 'category',
                    boundaryGap: false,
                    data: [],
                }],
                yAxis: [{
                    type: 'value',
                    scale: true,
                    name: ''
                }],
                series: [{
                    name: '总时间(s)',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#8E704F'
                        }
                    },
                    data: []
                }, {
                    name: '平均响应时间(ms)',
                    type: 'line',
                    itemStyle: {
                        normal: {
                            color: '#AD8EAD'
                        }
                    },
                    data: []
                }]
            };

            var responseChart = echarts.init(document.getElementById('response-area'));
            responseChart.setOption(option);
            _this.data.responseChart = responseChart;
        },

        initTrafficStatus: function() {
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
                    data: ['总入(kb)', '总出(kb)']
                },
                xAxis: [{
                    type: 'category',
                    boundaryGap: false,
                    data: [],
                }],
                yAxis: [{
                    type: 'value',
                    scale: true,
                    name: ''
                }],
                series: [{
                    name: '总入(kb)',
                    type: 'line',
                    smooth: true,
                    data: []
                }, {
                    name: '总出(kb)',
                    type: 'line',
                    data: []
                }]
            };

            var trafficChart = echarts.init(document.getElementById('traffic-area'));
            trafficChart.setOption(option);
            _this.data.trafficChart = trafficChart;
        }

    };
}(APP));