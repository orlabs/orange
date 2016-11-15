(function (L) {
    var _this = null;
    L.MonitorStat = L.MonitorStat || {};
    _this = L.MonitorStat = {
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

            $("#time-set a").click(function(){
                $("#time-set a").each(function(){
                    $(this).removeClass("active")
                });

                $(this).addClass("active");
            });

            $(document).on("click", ".timer_interval", function(){
                var interval  = parseInt($(this).attr("data-interval"));
                _this.data.interval = interval;
                _this.startTimer(interval);
            });
        },


        startTimer:function(interval){
            interval = interval || 3000;//默认3s请求一次
            if(_this.data.timer){
                clearInterval(_this.data.timer);
            }

            var try_times = 5;
            var lastTotalRequstCount = 0;
            var is_first_request = true;
            _this.data.timer =  setInterval(function (){

                $.ajax({
                    url : '/monitor/stat',
                    type : 'get',
                    cache: false,
                    data : {
                        rule_id: $("#rule-id-input").val()
                    },
                    dataType : 'json',
                    success : function(result) {
                        if(result.success){
                            var axisData = APP.Common.formatTime();
                            var data = result.data || {};

                            //request 统计
                            var requestOption = _this.data.requestChart.getOption();
                            var data0 = requestOption.series[0].data;
                            var data1 = requestOption.series[1].data;
                            var data2 = requestOption.series[2].data;
                            var data3 = requestOption.series[3].data;
                            var data4 = requestOption.series[4].data;
                            data0.shift();
                            data0.push(data.total_count);
                            data1.shift();
                            data1.push(data.request_2xx);
                            data2.shift();
                            data2.push(data.request_3xx);
                            data3.shift();
                            data3.push(data.request_4xx);
                            data4.shift();
                            data4.push(data.request_5xx);

                            requestOption.xAxis[0].data.shift();
                            requestOption.xAxis[0].data.push(axisData);
                            _this.data.requestChart.setOption(requestOption);

                            //qps统计
                            var qpsOption = _this.data.qpsChart.getOption();
                            if(is_first_request){
                                is_first_request=false;
                            }else{
                                data0 = qpsOption.series[0].data;
                                data0.shift();
                                data0.push((data.total_count - lastTotalRequstCount)/(_this.data.interval/1000));
                                qpsOption.xAxis[0].data.shift();
                                qpsOption.xAxis[0].data.push(axisData);
                                _this.data.qpsChart.setOption(qpsOption);
                            }
                            lastTotalRequstCount = data.total_count;

                            //请求时间统计
                            var responseOption = _this.data.responseChart.getOption();
                            data0 = responseOption.series[0].data;
                            data1 = responseOption.series[1].data;
                            data0.shift();
                            data0.push(data.total_request_time);
                            data1.shift();
                            data1.push(data.average_request_time*1000);
                            responseOption.xAxis[0].data.shift();
                            responseOption.xAxis[0].data.push(axisData);
                            _this.data.responseChart.setOption(responseOption);

                            //流量统计
                            var trafficOption = _this.data.trafficChart.getOption();
                            data0 = trafficOption.series[0].data;
                            data1 = trafficOption.series[1].data;
                            data2 = trafficOption.series[2].data;
                            data3 = trafficOption.series[3].data;
                            data0.shift();
                            data0.push(Math.round(data.traffic_read/1024));
                            data1.shift();
                            data1.push(Math.round(data.traffic_write/1024));
                            data2.shift();
                            data2.push(Math.round(data.average_traffic_read));
                            data3.shift();
                            data3.push(Math.round(data.average_traffix_write));
                            trafficOption.xAxis[0].data.shift();
                            trafficOption.xAxis[0].data.push(axisData);
                            _this.data.trafficChart.setOption(trafficOption);

                        }else{
                            APP.Common.showTipDialog("错误提示", result.msg);
                            try_times--;
                            if(try_times<0){
                                clearInterval(_this.data.timer);
                                APP.Common.showTipDialog("错误提示", "查询请求发生错误次数太多，停止查询");
                            }
                        }
                    },
                    error : function() {
                        try_times--;
                        if(try_times<0){
                            clearInterval(_this.data.timer);
                            APP.Common.showTipDialog("错误提示", "查询请求发生异常次数太多，停止查询");

                        }else{
                            APP.Common.showTipDialog("提示", "查询请求发生异常");
                        }

                    }
                });
            }, interval);

        },

        initRequestStatus: function(){
            var option = {
                title : {
                    text: '请求统计',
                    subtext: '',
                    left:'10px'
                },
                grid: {
                    left: '20px',
                    right: '20px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip : {
                    trigger: 'axis'
                },
                legend: {
                    data:['全部请求','2xx请求','3xx请求','4xx请求','5xx请求']
                },
                toolbox: {
                    show: true,
                    right:"20px",
                    feature: {
                        dataView: {readOnly: false},
                        saveAsImage: {}
                    }
                },
                xAxis : [
                    {
                        type : 'category',
                        boundaryGap : false,
                        data : (function (){
                            var now = new Date();
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.unshift(APP.Common.formatTime());
                                now = new Date(now - 200);
                            }
                            return res;
                        })()
                    }
                ],
                yAxis : [
                    {
                        type : 'value',
                        scale: true,
                        name : '次数'
                    }
                ],
                series : [
                    {
                        name:'全部请求',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#03A1F7'
                            }
                        },
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },
                    {
                        name:'2xx请求',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#269EBD'
                            }
                        },
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },
                    {
                        name:'3xx请求',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#F75903'
                            }
                        },
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },
                    {
                        name:'4xx请求',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#1C9361'
                            }
                        },
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },
                    {
                        name:'5xx请求',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#F75903'
                            }
                        },
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    }
                ]
            };

            var requestChart = echarts.init(document.getElementById('request-area'));
            requestChart.setOption(option);
            _this.data.requestChart = requestChart;
        },

        initQPSStatus: function(){
            var option = {
                title : {
                    text: 'QPS统计',
                    subtext: '',
                    left:'26px'
                },
                grid: {
                    left: '33px',
                    right: '33px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip : {
                    trigger: 'axis'
                },
                legend: {
                    data:['QPS']
                },
                toolbox: {
                    show: true,
                    right:"34px",
                    feature: {
                        dataView: {readOnly: false},
                        saveAsImage: {}
                    }
                },
                xAxis : [
                    {
                        type : 'category',
                        boundaryGap : false,
                        data : (function (){
                            var now = new Date();
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.unshift(APP.Common.formatTime());
                                now = new Date(now - 200);
                            }
                            return res;
                        })()
                    }
                ],
                yAxis : [
                    {
                        type : 'value',
                        scale: true,
                        name : 'Query'
                    }
                ],
                series : [
                    {
                        name:'QPS',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#ECA047'
                            }
                        },
                        areaStyle: {normal: {}},
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    }
                ]
            };

            var qpsChart = echarts.init(document.getElementById('qps-area'));
            qpsChart.setOption(option);
            _this.data.qpsChart = qpsChart;
        },

        initReponseStatus: function(){
            var option = {
                title : {
                    text: '请求时间统计',
                    left:'10px',
                    subtext: ''
                },
                grid: {
                    left: '15px',
                    right: '10px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip : {
                    trigger: 'axis'
                },
                legend: {
                    data:['总时间(s)','平均响应时间(ms)']
                },
                xAxis : [
                    {
                        type : 'category',
                        boundaryGap : false,
                        data : (function (){
                            var now = new Date();
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.unshift(APP.Common.formatTime());
                                now = new Date(now - 200);
                            }
                            return res;
                        })()
                    }
                ],
                yAxis : [
                    {
                        type : 'value',
                        scale: true,
                        name : ''
                    }
                ],
                series : [
                    {
                        name:'总时间(s)',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#8E704F'
                            }
                        },
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },
                    {
                        name:'平均响应时间(ms)',
                        type:'line',
                        itemStyle: {
                            normal: {
                                color: '#AD8EAD'
                            }
                        },
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    }
                ]
            };

            var responseChart = echarts.init(document.getElementById('response-area'));
            responseChart.setOption(option);
            _this.data.responseChart = responseChart;
        },

        initTrafficStatus: function(){
            var option = {
                title : {
                    text: '流量统计',
                    subtext: ''
                },
                grid: {
                    left: '15px',
                    right: '10px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip : {
                    trigger: 'axis'
                },
                legend: {
                    data:['总入(kb)','总出(kb)','均入(bytes)','均出(bytes)']
                },
                xAxis : [
                    {
                        type : 'category',
                        boundaryGap : false,
                        data : (function (){
                            var now = new Date();
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.unshift(APP.Common.formatTime());
                                now = new Date(now - 200);
                            }
                            return res;
                        })()
                    }
                ],
                yAxis : [
                    {
                        type : 'value',
                        scale: true,
                        name : ''
                    }
                ],
                series : [
                    {
                        name:'总入(kb)',
                        type:'line',
                        smooth: true,
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },{
                        name:'总出(kb)',
                        type:'line',
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },{
                        name:'均入(bytes)',
                        type:'line',
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    },{
                        name:'均出(bytes)',
                        type:'line',
                        data:(function (){
                            var res = [];
                            var len = 100;
                            while (len--) {
                                res.push(0);
                            }
                            return res;
                        })()
                    }
                ]
            };

            var trafficChart = echarts.init(document.getElementById('traffic-area'));
            trafficChart.setOption(option);
            _this.data.trafficChart = trafficChart;
        },

    };
}(APP));
