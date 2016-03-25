# Orange

Orange是一个基于OpenResty的API Gateway，提供API监控和管理，实现了防火墙、访问统计、流量切分、API重定向等功能。


### 安装说明


- 安装OpenResty
- 安装[lor](https://github.com/sumory/lor)
- orange依赖的uuid生成器，需要libuuid.so这个库， centos可通过以下命令安装，其他linux发行版请自行google
	
	```
	yum install  libuuid-devel
	```
- 安装Orange

	```
	git clone https://github.com/sumory/orange
	cd orange
	sh start.sh
	```
- 访问http://localhost:9999/orange/dashboard/

### Screenshots


<table>
    <tr>
        <td width="470px"><img src="https://sfault-image.b0.upaiyun.com/770/350/770350736-56f3c261c9df8_articlex"/></td>
 </tr>
 <tr>
        <td width="470px"><img src="https://sfault-image.b0.upaiyun.com/395/307/3953075362-56f3c2d492a51_articlex"/></td>
    </tr>
</table>