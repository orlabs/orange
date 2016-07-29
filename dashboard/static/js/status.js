(function (L) {
    var _this = null;
    L.Status = L.Status || {};
    _this = L.Status = {
        data: {
        	timer: null,
        	requestChart: null,
        	qpsChart: null,
        	responseChart: null,
        	trafficChart: null,
        	stateChart: [],
        	interval: 3000
        },
 
        init: function () {
        	_this.initRequestStatus();
        	_this.initQPSStatus();
        	_this.initReponseStatus();
        	_this.initTrafficStatus();
        	_this.initStateStatus("2xx");
        	_this.initStateStatus("3xx");
        	_this.initStateStatus("4xx");
        	_this.initStateStatus("5xx");

        	_this.startTimer();

        	$("#time-set a").click(function(){
        		$("#time-set a").each(function(){
	                $(this).removeClass("active")
	            });

	            $(this).addClass("active");
        	})

        	$(document).on("click", ".timer_interval", function(){
        		var interval  = parseInt($(this).attr("data-interval"));
        		_this.data.interval = interval;
        		_this.startTimer(interval);
        	});
        },

       	startTimer:function(interval){
        	interval = interval || 3000; //默认3秒请求一次
        	if(_this.data.timer){
	        	clearInterval(_this.data.timer);
	        }

	        var try_times = 5;
	        var lastTotalRequstCount = 0;
	        var is_first_request = true;
	        _this.data.timer =  setInterval(function (){
	        	
	        	$.ajax({
	                url : '/stat/status',
	                type : 'get',
	                cache:false,
	                data : {},
	                dataType : 'json',
	                success : function(result) {
	                    if(result.success){
	                    	var axisData = APP.Common.formatTime();
	            			var data = result.data || {};

                            //request 统计
				            var requestOption = _this.data.requestChart.getOption();
				            var data0 = requestOption.series[0].data;
    						var data1 = requestOption.series[1].data;
    						data0.shift();
						    data0.push(data.total_count);
						    data1.shift();
						    data1.push(data.total_count - data.total_success_count);
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
                            data0.shift();
                            data0.push(data.total_request_time);
                            responseOption.xAxis[0].data.shift();
                            responseOption.xAxis[0].data.push(axisData);
                            _this.data.responseChart.setOption(responseOption);

                            //流量统计
                            var trafficOption = _this.data.trafficChart.getOption();
                            var data0 = trafficOption.series[0].data;
                            var data1 = trafficOption.series[1].data;
                            data0.shift();
                            data0.push(Math.round(data.traffic_read/1024/1024));
                            data1.shift();
                            data1.push(Math.round(data.traffic_write/1024/1024));
                            trafficOption.xAxis[0].data.shift();
                            trafficOption.xAxis[0].data.push(axisData);
                            _this.data.trafficChart.setOption(trafficOption);

                            //HTTP status统计
                            var stateOption = _this.data.stateChart.getOption();
                            data0 = stateOption.series[0].data;
                            data0.shift();
                            data0.push( data["request_2xx"]);

                            data1 = stateOption.series[1].data;
                            data1.shift();
                            data1.push( data["request_3xx"]);

                            var data2 = stateOption.series[2].data;
                            data2.shift();
                            data2.push( data["request_4xx"]);

                            var data3 = stateOption.series[3].data;
                            data3.shift();
                            data3.push( data["request_5xx"]);
                            _this.data.stateChart.setOption(stateOption);


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
	                data:['全部请求','失败请求']
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
	                    name:'失败请求',
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
	                data:['响应时间']
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
	                    name : '秒'
	                }
	            ],
	            series : [
	                {
	                    name:'响应时间',
	                    type:'line',
	                    smooth: true,
	                    symbol: 'none',
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
	                data:['流入','流出']
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
	                    name : 'mbytes'
	                }
	            ],
	            series : [
	                {
	                    name:'流入',
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
	                },

	                {
	                    name:'流出',
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

        initStateStatus: function(code){
            var option = {
                title : {
                    text: 'HTTP Status 统计',
                    left:'26px',
                    subtext: ''
                },
                grid: {
                    left: '36px',
                    right: '30px',
                    bottom: '30px',
                    containLabel: true
                },
                tooltip : {
                    trigger: 'axis',
                    axisPointer : {// 坐标轴指示器，坐标轴触发有效
                        type : 'shadow'// 默认为直线，可选为：'line' | 'shadow'
                    }
                },
                legend: {
                    data:['2xx请求', '3xx请求','4xx请求','5xx请求']
                },
                xAxis : [
                    {
                        type : 'value'
                    }
                ],
                yAxis : [
                    {
                        type : 'category',
                        axisTick : {show: false},
                        data : ['']
                    }
                ],
                series : [
                    {
                        name:'2xx请求',
                        type:'bar',
                        label: {
                            normal: {
                                show: true,
                                position: 'inside'
                            }
                        },
                        itemStyle: {
                            normal: {
                                color: '#269EBD'
                            }
                        },
                        data:[0]
                    },
                    {
                        name:'3xx请求',
                        type:'bar',
                        label: {
                            normal: {
                                show: true
                            }
                        },
                        data:[0]
                    },
                    {
                        name:'4xx请求',
                        type:'bar',
                        label: {
                            normal: {
                                show: true
                            }
                        },
                        itemStyle: {
                            normal: {
                                color: '#B94D23'
                            }
                        },
                        data:[0]
                    },
                    {
                        name:'5xx请求',
                        type:'bar',
                        label: {
                            normal: {
                                show: true
                            }
                        },
                        itemStyle: {
                            normal: {
                                color: '#F75903'
                            }
                        },
                        data:[0]
                    },


                ]
            };
	        var chart = echarts.init(document.getElementById('status-area'));
	        chart.setOption(option);
	        _this.data.stateChart = chart;
        },

    };
}(APP));
