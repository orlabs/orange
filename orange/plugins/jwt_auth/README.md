### HTTP JSON Web Token Plugin

### file
* 插件目录
	* orange/plugins/jwt_auth/ 

* 控制面板
	
	* dashboard/static/js/jwt_auth.js
	* dashboard/views/jwt_auth/
	* dashboard/routes/dashboard.lua  `注册`
	* dashboard/views/common/left_nav.html `控制面板菜单栏`
	
### 说明
	
 * 项目依赖 [SkyLothar/lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt)
 
 	* `opm get  SkyLothar/lua-resty-jwt` 或者 `luarocks install lua-resty-jwt`
 * 添加插件配置 
    * 需要在 orange.conf 中 plugins 添加 `jwt_auth` 

 * 认证方式：
 	
 	* 1、 Header `Authorization`:`Bearer Token`
 	* 2、 Query `token=Token` 	
