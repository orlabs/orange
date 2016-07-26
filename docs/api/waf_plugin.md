### WEB防火墙插件waf API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/waf/enable     | Post

**参数** 

名称 | 类型 | 说明
---- | ---- | -------
enable | int | 0关闭1开启


**返回结果** 

```
{
	"msg":"关闭成功",
	"success":true
}
```

#### 2) 获取所有配置信息

**请求**

URI                 | Method 
------------------- | ---- 
/waf/configs    | Get


**参数**   
无 

**返回结果** 

```
{
    "data": {
        "enable": true,
        "rules": [
            {
                "enable": true,
                "handle": {
                    "log": true, //是否记录此条规则的匹配日志
                    "code": 403, // 返回的http状态码
                    "stat": true, //是否将此次记录加入到统计中
                    "perform": "deny" // deny or allow, deny则拒绝后续访问，以code为http状态码返回，allow则放过这条请求
                },
                "id": "C4DDC90B-F05C-4F69-94E1-6FCBC4F88392",
                "time": "2016-06-21 16:04:58",
                "name": "禁用管理功能",
                "judge": { // “条件判断模块”配置
                    "type": 0,
                    "conditions": [
                        {
                            "type": "URI",
                            "operator": "match",
                            "value": "^/admin/"
                        }
                    ]
                }
            }
        ]
    },
    "success": true
}
```


#### 3) 新建某条规则


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/waf/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式可参考"获取所有配置"API中返回数据中的data.rules[0]格式:

```
{
    "name": "waf规则修改示例",
    "judge": {
        "type": 1,
        "conditions": [
            {
                "type": "URI",
                "operator": "match",
                "value": "/waf"
            },
            {
                "type": "PostParams",
                "name": "uid",
                "operator": "=",
                "value": "456"
            }
        ]
    },
    "handle": {
        "log": true, //是否记录此条规则的匹配日志
        "code": 403, // 返回的http状态码
        "stat": true, //是否将此次记录加入到统计中
        "perform": "deny" // deny or allow, deny则拒绝后续访问，以code为http状态码返回，allow则放过这条请求
    },
    "enable": true
}
```

**返回结果** 

```
{
    "success": true,
    "msg": "新建规则成功"
}
```

#### 4) 编辑某条规则信息

**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/waf/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下:

```
{
    "id":"C4DDC90B-F05C-4F69-94E1-6FCBC4F88392",
    "name": "跳转",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "match",
                "value": "/abc"
            }
        ]
    },
    "handle": {
        "log": true, //是否记录此条规则的匹配日志
        "code": 405, // 返回的http状态码
        "stat": true, //是否将此次记录加入到统计中
        "perform": "deny" // deny or allow, deny则拒绝后续访问，以code为http状态码返回，allow则放过这条请求
    },
    "enable": true
}
```

**返回结果** 

```
{
    "success": true,
    "msg": "修改成功"
}
```

#### 5) 删除某条规则

**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/waf/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule_id | string | 指一条"规则"的id

**返回结果** 

```
{
    "success": true,
    "msg": "删除成功"
}
```



##### 6) 获取数据库中此插件的最新配置

**请求**

URI                 | Method 
------------------- | ------ 
/waf/fetch_config       | Get    


**参数**   
无

**返回结果** 

```
{
    "success": true,
    "data": {
     	"enable": true, //是否开启了此插件
     	"rules": [] // 该插件包含的规则列表
    }
}
```

具体规则格式见以上API描述


##### 7) 将数据库中最新配置更新到此orange节点


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/waf/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```

#### 8) 获取防火墙统计信息

**请求**

URI                 | Method 
------------------- | ------ 
/waf/stat           | Get    


**参数** 

无

**返回结果** 

```
{
    "data": {
        "statistics": [{
            "count": 7, //命中规则的请求个数
            "rule_id": "C4DDC90B-F05C-4F69-94E1-6FCBC4F88392",// 规则id
        }]
    },
    "success": true
}
```