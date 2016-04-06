(function($) {
    $.extend($.fn, {        
        jpagebar: function(setting) {
            var pb = $.extend({
                //pagebar 对象div
                renderTo: $(document.body),               
                //总页码
				totalpage: 0,
				//总数量
				totalcount: 0,
				//当前页码
				currentPage: 0,
				//分页条样式
				pagebarCssName: 'pagination',	
				//页码样式
				pageNumberCssName:'',	
				//首页、Pre、Next、尾页样式
				pageNameCssName:'',
				//选中首页、Pre或Next、尾页样式
				currentPageNameCssName:'disabled',
				//当前选中页码样式
				currentPageNumberCssName:'active',
				//显示总页码样式
				totalpageNumberCssName:'totalpage_number',	
				//点击页码action
				onClickPage : function(pageIndex){}
            }, setting);
			
				
			pb.resetPagebar = function(){	
				var _this = this;
				_this.renderTo = (typeof _this.renderTo == 'string' ? $(_this.renderTo) : _this.renderTo);

				var render_to = _this.renderTo;
				render_to.attr('class',_this.pagebarCssName);

				//清空分页导航条   
				render_to.empty();
				
				if(totalpage = 0){				
					return ;
				}
//				_this.totalpage = 12;
				render_to.append('<div style="float:right;"></div>');
				render_to = render_to.find('div');
				
				$('<div>总&nbsp;'+_this.totalpage+'页&nbsp;,&nbsp;'+_this.totalcount+'&nbsp;条记录</div>').appendTo(render_to);
				var pagebar = $('<ul></ul>');
				pagebar.appendTo(render_to);

                if (_this.totalcount == 0) {
                    render_to.hide();
                }
				
				// 分页   
				var front_block = parseInt(_this.currentPage) - 2;// 当前页码前面一截,原来是5
				var back_block = parseInt(_this.currentPage) + 2;// 当前页码后面一截,原来是5
				if(front_block < 1){
					back_block = back_block - front_block + 1;
				}
				
				if(back_block > _this.totalpage){
					front_block = front_block - (back_block-_this.totalpage);
				}
				

				//处理数字页码
				if(_this.totalpage == 1){//共1页
					$('<li><a href="javascript:void(0);">1</a></li>').attr('class',_this.currentPageNumberCssName).bind("click", function(){_this.onClickPage(1);}).appendTo(_this.renderTo.find("ul"));
				}
				else{//有多页
					if (_this.totalpage < 7){
						for (var i = 1; i <= _this.totalpage; i++) {  					
							if (_this.currentPage == i) { 	
								//当前页
								$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName + ' ' + _this.currentPageNumberCssName).appendTo(pagebar);
							} else {   
								 $('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName)
									 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
							}   
						} 	
					}else{
						if (_this.currentPage < 5){
							for (var i = 1; i <= 5; i++) {  					
								if (_this.currentPage == i) { 	
									//当前页
									$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName + ' ' + _this.currentPageNumberCssName).appendTo(pagebar);
								} else {   
									$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName)
										 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
								}
							}
//							style="border: medium none;cursor: default;line-height: 24px;padding: 0 0 4px;"
							$('<li><a class="page-ellipsis" href="javascript:void(0);">...</a></li>').attr('class',_this.pageNumberCssName).appendTo(pagebar);
							$('<li><a href="javascript:void(0);">'+_this.totalpage+'</a></li>').attr('class',_this.pageNumberCssName)
							 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
						}else if((_this.totalpage - _this.currentPage) < 5 ){
							$('<li><a href="javascript:void(0);">1</a></li>').attr('class',_this.pageNumberCssName)
							 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
							$('<li><a class="page-ellipsis" href="javascript:void(0);">...</a></li>').attr('class',_this.pageNumberCssName).appendTo(pagebar);
							for (var i = _this.totalpage - 4; i <= _this.totalpage; i++) {  					
								if (_this.currentPage == i) { 	
									//当前页
									$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName + ' ' + _this.currentPageNumberCssName).appendTo(pagebar);
								} else {   
									$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName)
										 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
								}
							}
						}else{
							var front_block = parseInt(_this.currentPage) - 2;// 当前页码前面一截,原来是5
							var back_block = parseInt(_this.currentPage) + 2;// 当前页码后面一截,原来是5
							if(front_block < 1){
								back_block = back_block - front_block + 1;
							}
							
							if(back_block > _this.totalpage){
								front_block = front_block - (back_block-_this.totalpage);
							}
							$('<li><a href="javascript:void(0);">1</a></li>').attr('class',_this.pageNumberCssName)
							 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
							$('<li><a class="page-ellipsis" href="javascript:void(0);">...</a></li>').attr('class',_this.pageNumberCssName).appendTo(pagebar);
							for (var i = front_block; i <= back_block; i++) {  					
								if (_this.currentPage == i) { 	
									//当前页
									$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName + ' ' + _this.currentPageNumberCssName).appendTo(pagebar);
								} else {   
									$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName)
										 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
								}
							}
							$('<li><a class="page-ellipsis" href="javascript:void(0);">...</a></li>').attr('class',_this.pageNumberCssName).appendTo(pagebar);
							$('<li><a href="javascript:void(0);">'+_this.totalpage+'</a></li>').attr('class',_this.pageNumberCssName)
							 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
						}
					}
						
//					var tempBack_block = _this.totalpage;   
//					var tempFront_block = 1;   
//					if (back_block < _this.totalpage)   
//						tempBack_block = back_block;   
//					if (front_block > 1)   
//						tempFront_block = front_block;  
//					
//					for (var i = tempFront_block; i <= tempBack_block; i++) {  					
//						if (_this.currentPage == i) { 	
//							//当前页
//							$('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName + ' ' + _this.currentPageNumberCssName).appendTo(pagebar);
//						} else {   
//							 $('<li><a href="javascript:void(0);">'+i+'</a></li>').attr('class',_this.pageNumberCssName)
//								 .bind("click", function(){_this.onClickPage($(this).find('a').text());}).appendTo(pagebar);
//						}   
//					} 			
				}

				//处理Pre
				if(_this.currentPage == 1 ){//当前页为第一页
					$('<li><a href="javascript:void(0);">← </a></li>').attr('class',_this.pageNameCssName + ' ' + _this.currentPageNameCssName).prependTo(pagebar);
				}
				else{
					//当前页大于第一页
					$('<li><a href="javascript:void(0);">← </a></li>').attr('class',_this.pageNameCssName)
						 .bind("click", function(){_this.onClickPage(_this.currentPage-1);}).prependTo(pagebar);
				}
				 //处理Next
				if (_this.currentPage == _this.totalpage) {//当前页为最后一页 
					$('<li><a href="javascript:void(0);"> →</a></li>').attr('class',_this.pageNameCssName + ' ' + _this.currentPageNameCssName).appendTo(pagebar);
				} else {   
					$('<li><a href="javascript:void(0);"> →</a></li>').attr('class',_this.pageNameCssName)
								.bind("click", function(){_this.onClickPage(parseInt(_this.currentPage)+1);}).appendTo(pagebar); 
				}


				//$('<div>到第<input id="go_pg_num" value="'+_this.currentPage+'" ></input>页</div><span class="page-btn">确定</span>').appendTo(render_to);
				
				$('#go_pg_num').unbind('input').unbind('propertychange');
				$('#go_pg_num').bind('input propertychange',function(){
					var currentPage = $(this).val();
					if(currentPage == ''){
						return;
					}
					currentPage = parseInt(currentPage);
					if(isNaN(currentPage) || currentPage<1 ||( _this.totalpage && _this.totalpage < currentPage)){
						 $(this).val(1);//不符合要求则置1
					}
				});
				
				$('#go_pg_num').bind('keydown',function(e){
					var event = window.event || e;
					if(event.keyCode == 13){
						var goPgNum = parseInt($('#go_pg_num').val());
						if(isNaN(goPgNum) || goPgNum<1 ||( _this.totalpage && _this.totalpage < goPgNum)){
							goPgNum = 1;//不符合要求则置1
						}
						_this.onClickPage(goPgNum);
					}
				});
				
				$('.page-btn').click(function(){
					var goPgNum = parseInt($('#go_pg_num').val());
					if(isNaN(goPgNum) || goPgNum<1 ||( _this.totalpage && _this.totalpage < goPgNum)){
						goPgNum = 1;//不符合要求则置1
					}
					_this.onClickPage(goPgNum);
				});
				
			};
			pb.resetPagebar();
        },
		setCurrentPage:function(_this,currentPage){
			if(isNaN(currentPage) || currentPage<0 ||( _this.totalpage && _this.totalpage < currentPage))
				currentPage = _this.totalpage;
			_this.currentPage = currentPage;
			_this.resetPagebar(_this);
			$('#go_pg_num').text(currentPage);
		},
		setTotalPage:function(_this,totalpage){			
			_this.totalpage = totalpage;
			_this.resetPagebar(_this);
		}
    });
})(jQuery);