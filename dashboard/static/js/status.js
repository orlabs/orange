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
        	interval: 1
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
        		_this.data.interval = interval/1000;
        		_this.startTimer(interval);
        	});
        },

       	startTimer:function(interval){
        	interval = interval || 1000;
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
                                data0.push((data.total_count - lastTotalRequstCount)/_this.data.interval);
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
                            data0.push(Math.round(data.traffic_read/1024));
                            data1.shift();
                            data1.push(Math.round(data.traffic_write/1024));
                            trafficOption.xAxis[0].data.shift();
                            trafficOption.xAxis[0].data.push(axisData);
                            _this.data.trafficChart.setOption(trafficOption);

                            for(var i=2;i<=5;i++){
                                var option = _this.data.stateChart[i+"xx"].getOption();
                                data0 = option.series[0].data;
                                data0.shift();
                                data0.push( data["request_" + i + "xx"]);
                                option.xAxis[0].data.shift();
                                option.xAxis[0].data.push(axisData);
                                _this.data.stateChart[i+"xx"].setOption(option);
                            }

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
	                subtext: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['全部请求','失败请求']
	            },
	            toolbox: {
	                show: true,
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
	                    name:'失败请求',
	                    type:'line',
	                    itemStyle: {normal: {areaStyle: {type: 'default'}}},
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

	        var requestChart = echarts.init(document.getElementById('request-area'));
	        requestChart.setOption(option);
	        _this.data.requestChart = requestChart;
        },

        initQPSStatus: function(){
        	var option = {
	            title : {
                    text: 'QPS统计',
                    subtext: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['QPS']
	            },
	             toolbox: {
                     show: true,
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

	        var qpsChart = echarts.init(document.getElementById('qps-area'));
	        qpsChart.setOption(option);
	        _this.data.qpsChart = qpsChart;
        },

        initReponseStatus: function(){
        	var option = {
	            title : {
                    text: '请求时间统计',
                    subtext: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['响应时间']
	            },
	             toolbox: {
                     show: true,
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
	                    name : '秒'
	                }
	            ],
	            series : [
	                {
	                    name:'秒',
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
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['in','out']
	            },
	             toolbox: {
                     show: true,
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
	                    name : 'kbytes'
	                }
	            ],
	            series : [
	                {
	                    name:'in',
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
	                    name:'out',
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
        	var color = "rgb(182, 207, 220)";
        	if(code == "4xx" || code == "5xx"){
        		color = "rgb(238, 109, 68)";
        	}

        	var option = {
	            title : {
                    text: code + '请求统计',
                    subtext: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:[code+"请求"]
	            },
	             toolbox: {
                     show: true,
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
	                        var len = 50;
	                        while (len--) {
	                            res.unshift(APP.Common.formatTime());
	                            now = new Date(now - 400);
	                        }
	                        return res;
	                    })()
	                }
	            ],
	            yAxis : [
	                {
	                    type : 'value',
	                    scale: true,
	                    name : '次'
	                }
	            ],
	            series : [
	                {
	                    name:'请求',
	                    type:'line',
	                    data:(function (){
	                        var res = [];
	                        var len = 50;
	                        while (len--) {
	                          res.push(0);
	                        }
	                        return res;
	                    })()
	                }
	            ]
	        };

	        var chart = echarts.init(document.getElementById(code+'-area'));
	        chart.setOption(option);
	        _this.data.stateChart[code] = chart;
        },

    };
}(APP));