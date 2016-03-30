此示例为Orange和OpenResty-China集成示例，也可作为其他站点集成参考。

集成步骤如下：

1. 下载openresty-china
2. 将openresty-china的app目录拷贝到此目录下	，此时的目录结构如下

	```
	.
	├── README.md
	├── app
	│   └── ...
	├── data.json
	├── logs
	├── nginx.conf
	├── orange.conf
	└── start.sh
	```
	查看nginx.conf的相关配置，可根据具体需要作调整。
3. sh start.sh
4. 访问[http://localhost](http://localhost) 即OpenResty China站点，访问[http://localhost:9999](http://localhost:9999)，即orange dashboard管理界面