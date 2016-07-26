### 鉴权basic_auth插件Basic Auth API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/basic_auth/enable     | Post

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
/basic_auth/configs    | Get


**参数**   
无 

**返回结果** 

```
{
    "enable": true,
    "rules": [
        {
            "enable": true,
            "handle": {
                "log": true,
                "credentials": [//账户
                    {
                        "password": "password123",
                        "username": "user123"
                    }
                ],
                "code": 401//鉴权不通过时的状态码
            },
            "id": "09AAE44B-347E-45B0-B83E-8597C6FFE8DE",
            "time": "2016-07-26 17:08:00",
            "name": "管理功能鉴权",
            "judge": {
                "type": 0,
                "conditions": [
                    {
                        "type": "URI",
                        "operator": "match",
                        "value": "^/business_admin/"
                    }
                ]
            }
        },
        {
            "enable": true,
            "id": "6CEC852E-CD2F-45F9-95BA-E66E88C8D5AB",
            "judge": {
                "type": 0,
                "conditions": [
                    {
                        "type": "URI",
                        "operator": "match",
                        "value": "^/basic_auth/"
                    }
                ]
            },
            "time": "2016-07-26 17:07:09",
            "name": "test_basic_auth",
            "handle": {
                "log": true,
                "credentials": [
                    {
                        "password": "admin_token",
                        "username": "admin"
                    },
                    {
                        "password": "123456",
                        "username": "user"
                    }
                ],
                "code": 401
            }
        }
    ]
}
```


#### 3) 新建某条规则


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/basic_auth/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式可参考"获取所有配置"API中返回数据中的data.rules[0]格式:

```
{
    "name": "新规则示例",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "Header",
                "name": "need_auth",
                "operator": "=",
                "value": "true"
            }
        ]
    },
    "handle": {
        "credentials": [
            {
                "username": "u1",
                "password": "p1"
            }
        ],
        "code": 401,
        "log": false
    },
    "enable": true,
    "id": "3439F540-42A9-4E86-9092-D5787454F46B"
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
/basic_auth/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下:

```
{
    "name": "编辑规则示例",
    "judge": {
        "type": 1,
        "conditions": [
            {
                "type": "Header",
                "name": "need_auth",
                "operator": "=",
                "value": "true"
            },
            {
                "type": "IP",
                "operator": "not_match",
                "value": "^192.168"
            }
        ]
    },
    "handle": {
        "credentials": [
            {
                "username": "u1",
                "password": "p1"
            }
        ],
        "code": 401,
        "log": false
    },
    "enable": true,
    "id": "3439F540-42A9-4E86-9092-D5787454F46B"
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
/basic_auth/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


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
/basic_auth/fetch_config       | Get    


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
/basic_auth/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```
