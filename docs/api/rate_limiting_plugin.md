### 访问限速插件Rate Limiting API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/rate_limiting/enable     | Post

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
/rate_limiting/configs    | Get


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
                "id": "9E3F0736-2FBA-48A2-A6EE-8DEF8617229B",
                "judge": {
                    "type": 0,
                    "conditions": [
                        {
                            "type": "URI",
                            "operator": "=",
                            "value": "/rate"
                        }
                    ]
                },
                "time": "2016-09-24 20:53:45",
                "name": "/rate",
                "handle": {
                    "log": true,
                    "count": 3,
                    "period": 60
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
/rate_limiting/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式可参考"获取所有配置"API中返回数据中的data.rules[0]格式:

```
{
    "data": {
        "enable": true,
        "rules": [
            {
                "enable": true,
                "id": "9E3F0736-2FBA-48A2-A6EE-8DEF8617229B",
                "judge": {
                    "type": 0,
                    "conditions": [
                        {
                            "type": "URI",
                            "operator": "=",
                            "value": "/rate"
                        }
                    ]
                },
                "time": "2016-09-24 20:53:45",
                "name": "/rate",
                "handle": {
                    "log": true, //是否在超过最大访问数时记录日志
                    "count": 3, //单位时间内的最多访问次数
                    "period": 60 //计数的时间间隔（秒）,只能是1、60、3600、86400，即1秒、1分钟、1小时、1天
                }
            }
        ]
    },
    "success": true
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
/rate_limiting/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下:

```
{
    "data": {
        "enable": true,
        "rules": [
            {
                "enable": true,
                "handle": {
                    "log": true,
                    "count": 3,
                    "period": 60
                },
                "time": "2016-09-24 21:39:36",
                "judge": {
                    "type": 0,
                    "conditions": [
                        {
                            "type": "URI",
                            "operator": "=",
                            "value": "/rate"
                        }
                    ]
                },
                "name": "/rate",
                "id": "9E3F0736-2FBA-48A2-A6EE-8DEF8617229B"
            }
        ]
    },
    "success": true
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
/rate_limiting/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


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


##### 6) 将数据库中最新配置更新到此orange节点


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/rate_limiting/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```
