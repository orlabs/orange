URL ?= 'http://127.0.0.1?usr=111&pwd=111&sig=1111'

systemtap:
	wrk -c 10 -d30s -t2  $(URL)&
	sudo ngx-sample-lua-bt -p `cat logs/nginx.pid ` --luajit20 -t 5  > tmp.bt
	fix-lua-bt tmp.bt > a.bt
	stackcollapse-stap.pl a.bt > a.cbt
	flamegraph.pl a.cbt > a.svg

