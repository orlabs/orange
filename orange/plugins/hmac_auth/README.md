## HTTP HMAC Authorization Plugin

### 1、插件目录
> * Gateway（orange/plugins/hmac_auth）
> * Dashboard（dashboard/views/hmac_auth）

### 2、认证方式
> * 请求Header头中传递Authorization、X-Date、自定义数据等信息
> * Authorization 定义
    + 该Header必须存在
	+ 参数值由（标识+算法+Header+签名）组成，详见下表
> * X-Date 定义
    + 该Header必须存在
    + 参数值必须为格林威治时间 (GMT)
    + 用于计算签名和验证有效期

| 顺序  | 内容  | 作用 |
| :------------ |:---------------| :-----|
| 1      | Hmac | 用于识别认证类型 |
| 2      | algorithm="hmac-sha1"        |  用于识别计算算法 |
| 3 | headers="X-Date,Content-md5"        |    用于识别参与签名计算的Header内容，多个使用英文逗号分隔，多个Header时顺序需要与签名计算时顺序一致 |
| 4 | signature="O4sXgt9jEKohoet2AeBrF/H5Tbg="        |    用于对比计算签名，计算规则详见签名计算 |
| 完整示例 | Authorization:Hmac algorithm="hmac-sha1", headers="X-Date,Content-md5", signature="O4sXgt9jEKohoet2AeBrF/H5Tbg="       |    除顺序1和2位使用空格分隔，其余2、3、4均使用英文逗号分隔参数 |

### 3、签名计算
> * 构建待签名报文 local content = "X-Date:" .. os.date("%a, %d %b %Y %X GMT") .. "\n" .. "Content-md5:" .. ngx.md5(body)
> * 构建签名 local sign = ngx.encode_base64(ngx.hmac_sha1(secret, content))

### 4、请求示例
```header
Authorization:hmac algorithm="hmac-sha1", headers="X-Date,Content-md5", signature="O4sXgt9jEKohoet2AeBrF/H5Tbg="
X-Date:Fri, 29 Mar 2019 18:01:32 GMT
Content-md5:41825a1de737e3061c22391e7eceefd7
```
### 5、算法支持
> 目前仅支持HMAC-SHA1算法，如需使用HMAC-SHA256、HMAC-SHA384、HMAC-SHA512或更多算法，请安装openssl模块`luarocks install openssl`后到`orange/plugins/hmac_auth/handler.lua`中解除相应算法注释即可。
