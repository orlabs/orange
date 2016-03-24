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
	                url : '/orange/dashboard/stat/status',
	                type : 'get',
	                data : {},
	                dataType : 'json',
	                success : function(result) {
	                    if(result.success){
	                    	var axisData = APP.Common.formatTime();

	            			var data = result.data || {};
	            			
				            _this.data.requestChart.addData([
				                [
				                    0,        // 系列索引
				                    data.total_count, // 新增数据
				                    false,     // 新增数据是否从队列头部插入
				                    false,     // 是否增加队列长度，false则自定删除原有数据，队头插入删队尾，队尾插入删队头
				                ],
				                [
				                    1,
				                    data.total_count - data.total_success_count,
				                    false,
				                    false,
				                    axisData
				                ]
				            ]);

				            if(is_first_request){
					            is_first_request=false;
				            }else{
				            	_this.data.qpsChart.addData([
					                [
					                    0,
					                    (data.total_count - lastTotalRequstCount)/_this.data.interval,
					                    false,
					                    false,
					                    axisData
					                ]
					            ]);
				            }
				            lastTotalRequstCount = data.total_count;

				            _this.data.responseChart.addData([
				                [
				                    0,
				                    data.total_request_time,
				                    false,
				                    false,
				                    axisData
				                ]
				            ]);

				            _this.data.trafficChart.addData([
				                [
				                    0,
				                    Math.round(data.traffic_read/1024),
				                    false,
				                    false
				                ],
				                [
				                    1,
				                    Math.round(data.traffic_write/1024),
				                    false,
				                    false,
				                    axisData
				                ]
				            ]);

				            // state stat
				            _this.data.stateChart["2xx"].addData([
				                [
				                    0,
				                    data.request_2xx,
				                    false,
				                    false,
				                    axisData
				                ]
				            ]);
				            _this.data.stateChart["3xx"].addData([
				                [
				                    0,
				                    data.request_3xx,
				                    false,
				                    false,
				                    axisData
				                ]
				            ]);
				            _this.data.stateChart["4xx"].addData([
				                [
				                    0,
				                    data.request_4xx,
				                    false,
				                    false,
				                    axisData
				                ]
				            ]);
				             _this.data.stateChart["5xx"].addData([
				                [
				                    0,
				                    data.request_5xx,
				                    false,
				                    false,
				                    axisData
				                ]
				            ]);

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
	                text: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['全部请求','失败请求']
	            },
	            toolbox: {
	                show : false,
	            },
	            xAxis : [
	                {
	                    type : 'category',
	                    boundaryGap : false,
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    },
	                    // axisLabel: {
	                    //     interval: 4
	                    // },
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
	                    name : '次数',
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    }
	                }
	            ],
	            series : [
	                {
	                    name:'全部请求',
	                    type:'line',
	                    smooth: true,
	                    symbol: 'none',
	                    itemStyle: {
	                        normal: {
	                            color:"#97BBCD",
	                            areaStyle: {
	                                type: 'default',
	                                color: "rgba(151, 187, 205,0.7)"
	                            },
	                            lineStyle:{
	                                color: "#97BBCD",
	                                shadownColor: "#97BBCD"
	                            }
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
	                text: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['QPS']
	            },
	             toolbox: {
	                show : false,
	            },
	            xAxis : [
	                {
	                    type : 'category',
	                    boundaryGap : false,
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    },
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
	                    name : 'Query',
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    }
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
	                text: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['响应时间']
	            },
	             toolbox: {
	                show : false,
	            },
	            xAxis : [
	                {
	                    type : 'category',
	                    boundaryGap : false,
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    },
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
	                    name : '秒',
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    }
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
	                text: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:['in','out']
	            },
	             toolbox: {
	                show : false,
	            },
	            xAxis : [
	                {
	                    type : 'category',
	                    boundaryGap : false,
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    },
	                    // axisLabel: {
	                    //     interval: 4
	                    // },
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
	                    name : 'kbytes',
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    }
	                }
	            ],
	            series : [
	                {
	                    name:'in',
	                    type:'line',
	                    smooth: true,
	                    symbol: 'none',
	                    itemStyle: {
	                        normal: {
	                            color:"#97BBCD",
	                            areaStyle: {
	                                type: 'default',
	                                color: "rgba(151, 187, 205,0.7)"
	                            },
	                            lineStyle:{
	                                color: "#97BBCD",
	                                shadownColor: "#97BBCD"
	                            }
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
	                    name:'out',
	                    type:'line',
	                    itemStyle: {normal: {areaStyle: {type: 'default'}}},
	                    symbol: 'none',
	                    itemStyle: {
	                        normal: {
	                            color:"rgb(228, 235, 239)",
	                            areaStyle: {
	                                type: 'default',
	                                color: "rgba(228, 235, 239,0.7)"
	                            },
	                            lineStyle:{
	                                color: "rgb(228, 235, 239)",
	                                shadownColor: "rgb(228, 235, 239)"
	                            }
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
	                text: ''
	            },
	            tooltip : {
	                trigger: 'axis'
	            },
	            legend: {
	                data:[code+"请求"]
	            },
	             toolbox: {
	                show : false,
	            },
	            xAxis : [
	                {
	                    type : 'category',
	                    boundaryGap : false,
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    },
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
	                    name : '次',
	                    axisLine:{
	                        lineStyle:{
	                            color: '#aaa',
	                            width: 2,
	                            type: 'solid'
	                        } 
	                    }
	                }
	            ],
	            series : [
	                {
	                    name:'请求',
	                    type:'line',
	                    symbol: 'none',
	                    itemStyle: {
	                        normal: {
	                            color: color,
	                            lineStyle:{
	                                color: color,
	                                shadownColor: color
	                            }
	                        }
	                    },
	                  
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