### 鉴权key_auth插件Key Auth API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/key_auth/enable     | Post

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
/key_auth/configs    | Get


**参数**   
无 

**返回结果** 

```
{
    "enable": false,
    "rules": [
        {
            "enable": true,
            "handle": {
                "log": true,
                "credentials": [//key auth数组
                    {
                        "type": 1, //1指通过Header获取，2指通过Query String获取，3指通过表单获取
                        "target_value": "123", //按照`key`提取出的值应该与此值匹配，则证明鉴权通过
                        "key": "uid" //要提取的key
                    },
                    {
                        "type": 2,
                        "target_value": "abc",
                        "key": "name"
                    },
                    {
                        "type": 3,
                        "target_value": "456",
                        "key": "p"
                    }
                ],
                "code": 403
            },
            "judge": {
                "type": 1,
                "conditions": [
                    {
                        "type": "URI",
                        "operator": "match",
                        "value": "^/key_auth/"
                    }
                ]
            },
            "name": "2342",
            "id": "71455D4A-A257-44FC-9262-DFEEF63BB7F7"
        }
    ]
}
```


#### 3) 新建某条规则


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/key_auth/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式可参考"获取所有配置"API中返回数据中的data.rules[0]格式:

```
{
    "name": "新建key_auth规则",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "match",
                "value": "^/key_auth/"
            }
        ]
    },
    "handle": {
        "credentials": [
            {
                "type": 1,
                "key": "h_token",
                "target_value": "123"
            },
            {
                "type": 2,
                "key": "q_token",
                "target_value": "123456"
            },
            {
                "type": 3,
                "key": "body_token",
                "target_value": "654321"
            }
        ],
        "code": 401,
        "log": true
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
/key_auth/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下:

```
{
    "name": "编辑key_auth规则",
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
                "type": 1,
                "key": "h_token",
                "target_value": "123456"
            }
        ],
        "code": 401,
        "log": true
    },
    "enable": true,
    "id": "F80CE8B1-D6DC-4E47-A9A9-E4746E33BE79"
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
/key_auth/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


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
/key_auth/fetch_config       | Get    


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
/key_auth/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```
