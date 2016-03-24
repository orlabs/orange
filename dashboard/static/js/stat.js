(function (L) {
    var _this = null;
    L.Status = L.Status || {};
    _this = L.Status = {
        data: {
        	max_axis_count: 24,
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
	                    	var axis = APP.Common.formatTime();

	            			var data = result.data || {};
	            			//data.total_count - data.total_success_count,
	            			//qps: (data.total_count - lastTotalRequstCount)/_this.data.interval
	            			//data.total_request_time,
	            			//data.traffic_read/1024
	            			
				            lastTotalRequstCount = data.total_count;

				            var this_data = _this.data;
				            this_data.requestChart.addData([data.total_count, data.total_count - data.total_success_count], axis);
				            this_data.qpsChart.addData([ (data.total_count - lastTotalRequstCount)/_this.data.interval ], axis);
				            this_data.responseChart.addData([data.total_request_time], axis);
				            this_data.trafficChart.addData([data.traffic_read/1024, data.traffic_write/1024], axis);
				            this_data.stateChart["2xx"].addData([data.request_2xx], axis);
				            this_data.stateChart["3xx"].addData([data.request_3xx], axis);
				            this_data.stateChart["4xx"].addData([data.request_4xx], axis);
				            this_data.stateChart["5xx"].addData([data.request_5xx], axis);

				            while(this_data.requestChart.datasets[0].points.length >= this_data.max_axis_count ){
				                this_data.requestChart.removeData();
				            }
				            
				            while( this_data.qpsChart.datasets[0].points.length >= this_data.max_axis_count/3 ){
				                this_data.qpsChart.removeData();
				            }
				            
				            while( this_data.responseChart.datasets[0].points.length >= this_data.max_axis_count/3 ){
				                this_data.responseChart.removeData();
				            }
				            
				            while( this_data.trafficChart.datasets[0].points.length >= this_data.max_axis_count/3 ){
				                this_data.trafficChart.removeData();
				            }

				            while( this_data.stateChart["2xx"].datasets[0].points.length >= this_data.max_axis_count/4  ){
				                this_data.stateChart["2xx"].removeData();
				            }

				            while( this_data.stateChart["3xx"].datasets[0].points.length >= this_data.max_axis_count/4 ){
				                this_data.stateChart["3xx"].removeData();
				            }

				            while( this_data.stateChart["4xx"].datasets[0].points.length >= this_data.max_axis_count/4 ){
				                this_data.stateChart["4xx"].removeData();
				            }

				            while( this_data.stateChart["5xx"].datasets[0].points.length >= this_data.max_axis_count/4 ){
				                this_data.stateChart["5xx"].removeData();
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
	        var ctx = $("#request-area").get(0).getContext("2d");
	        var options={
	        	responsive:true,
	        	legendTemplate : "<ul class=\"<%=name.toLowerCase()%>-legend\"><% for (var i=0; i<datasets.length; i++){%><li><span style=\"background-color:<%=datasets[i].strokeColor%>\"></span><%if(datasets[i].label){%><%=datasets[i].label%><%}%></li><%}%></ul>"

	        };
	        var data = {
	            labels: [],
	            datasets: [
	                {
	                    label: "全部请求",
	                    scaleLabel : "全部",
	                    fillColor: "rgba(220,220,220,0.2)",
	                    strokeColor: "rgba(220,220,220,1)",
	                    pointColor: "rgba(220,220,220,1)",
	                    pointStrokeColor: "#fff",
	                    pointHighlightFill: "#fff",
	                    pointHighlightStroke: "rgba(220,220,220,1)",
	                    data: []
	                },
	                {
	                    label: "错误请求",
	                    fillColor: "rgba(151,187,205,0.2)",
	                    strokeColor: "rgba(151,187,205,1)",
	                    pointColor: "rgba(151,187,205,1)",
	                    pointStrokeColor: "#fff",
	                    pointHighlightFill: "#fff",
	                    pointHighlightStroke: "rgba(151,187,205,1)",
	                    data: []
	                }
	            ]
	        };
	        var chart = new Chart(ctx).Line(data, options);
	        _this.data.requestChart = chart;
        },

        initQPSStatus: function(){
        	var ctx = $("#qps-area").get(0).getContext("2d");
	        var options={responsive: true};
	        var data = {
	            labels: [],
	            datasets: [
	                {
	                    label: "QPS",
	                    fillColor: "rgba(220,220,220,0.2)",
	                    strokeColor: "rgba(220,220,220,1)",
	                    pointColor: "rgba(220,220,220,1)",
	                    pointStrokeColor: "#fff",
	                    pointHighlightFill: "#fff",
	                    pointHighlightStroke: "rgba(220,220,220,1)",
	                    data: []
	                }
	            ]
	        };
	        var chart = new Chart(ctx).Line(data, options);
	        _this.data.qpsChart = chart;
        },

        initReponseStatus: function(){
        	var ctx = $("#response-area").get(0).getContext("2d");
	        var options={responsive:true};
	        var data = {
	            labels: [],
	            datasets: [
	                {
	                    label: "请求时间",
	                    fillColor: "rgba(220,220,220,0.2)",
	                    strokeColor: "rgba(220,220,220,1)",
	                    pointColor: "rgba(220,220,220,1)",
	                    pointStrokeColor: "#fff",
	                    pointHighlightFill: "#fff",
	                    pointHighlightStroke: "rgba(220,220,220,1)",
	                    data: []
	                }
	            ]
	        };
	        var chart = new Chart(ctx).Line(data, options);
	        _this.data.responseChart = chart;
        },

		initTrafficStatus: function(){
        	var ctx = $("#traffic-area").get(0).getContext("2d");
	        var options={responsive:true};
	        var data = {
	            labels: [],
	            datasets: [
	                {
	                    label: "in",
	                    fillColor: "rgba(220,220,220,0.2)",
	                    strokeColor: "rgba(220,220,220,1)",
	                    pointColor: "rgba(220,220,220,1)",
	                    pointStrokeColor: "#fff",
	                    pointHighlightFill: "#fff",
	                    pointHighlightStroke: "rgba(220,220,220,1)",
	                    data: []
	                },
	                {
	                    label: "out",
	                    fillColor: "rgba(151,187,205,0.2)",
	                    strokeColor: "rgba(151,187,205,1)",
	                    pointColor: "rgba(151,187,205,1)",
	                    pointStrokeColor: "#fff",
	                    pointHighlightFill: "#fff",
	                    pointHighlightStroke: "rgba(151,187,205,1)",
	                    data: []
	                }
	            ]
	        };
	        var chart = new Chart(ctx).Line(data, options);
	        _this.data.trafficChart = chart;
        },

        initStateStatus: function(code){
        	var ctx = $("#"+ code + "-area").get(0).getContext("2d");
	        var options={responsive:true};
	        var data = {
	            labels: [],
	            datasets: [
	                {
	                    label: code + "请求",
	                    fillColor: "rgba(220,220,220,0.2)",
	                    strokeColor: "rgba(220,220,220,1)",
	                    pointColor: "rgba(220,220,220,1)",
	                    pointStrokeColor: "#fff",
	                    pointHighlightFill: "#fff",
	                    pointHighlightStroke: "rgba(220,220,220,1)",
	                    data: []
	                }
	            ]
	        };
	        var chart = new Chart(ctx).Line(data, options);
	        _this.data.stateChart[code] = chart;
        },

    };
}(APP));