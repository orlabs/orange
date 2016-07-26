### URL重定向插件rewrite API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/rewrite/enable     | Post

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
/rewrite/configs    | Get


**参数**   
无 

**返回结果** 

```
{
    "success": true,
    "data": {
        "enable": true, //该插件是否启用
        "rules": [
            {
                "enable": true,//该条规则是否启用
                "id": "3D5307CD-F1B5-470E-A922-5945F542FD2C",
                "judge": { //"条件判断模块"配置
                    "type": 1,
                    "conditions": [
                        {
                            "type": "URI",
                            "operator": "match",
                            "value": "/rewrite"
                        },
                        {
                            "type": "PostParams",
                            "operator": "=",
                            "name": "uid",
                            "value": "456"
                        }
                    ]
                },
                "time": "2016-06-21 15:35:19",
                "name": "rewrite示例",
                "extractor": { //"变量提取模块"配置
                    "extractions": [
                        {
                            "type": "PostParams",
                            "name": "uid"
                        }
                    ]
                },
                "handle": {
                    "log": true, //是否记录该次匹配的日志
                    "uri_tmpl": "/rewrite_to/${1}" //要rewrite到的URI的模板，${number}指的是“变量提取模块”提取出的值
                }
            }
        ]
    }
}
```

- judge: 条件判断模块配置，一个请求经过此模块过滤后得出是否匹配该条规则的结果，然后才能进行之后的“变量提取”和“后续处理”两个模块，详见[条件判断模块](http://orange.sumory.com/docs/judge.html)
- extractor: 变量提取模块配置，如果不需要提取变量后续使用则可不配置。一个请求经过`judge`判断命中此条规则后，将通过变量提取模块提取需要的值，详见[变量提取器](http://orange.sumory.com/docs/extraction.html)


#### 3) 新建某条规则


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/rewrite/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式可参考"获取所有配置"API中返回数据中的data.rules[0]格式:

```
{
    "name": "rewrite示例",
    "judge": {
        "type": 1,
        "conditions": [
            {
                "type": "URI",
                "operator": "match",
                "value": "/rewrite"
            },
            {
                "type": "PostParams",
                "name": "uid",
                "operator": "=",
                "value": "456"
            }
        ]
    },
    "extractor": {
        "extractions": [
            {
                "type": "PostParams",
                "name": "uid"
            }
        ]
    },
    "handle": {
        "uri_tmpl": "/rewrite_to/${1}",
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
/rewrite/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下:

```
{
    "id":"3D5307CD-F1B5-470E-A922-5945F542FD2C",
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
    "extractor": {
        "extractions": [
            {
                "type": "Query",
                "name": "city"
            }
        ]
    },
    "handle": {
        "url_tmpl": "/new_uri/${1}",
        "trim_qs": false,
        "log": true
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
/rewrite/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


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
/rewrite/fetch_config       | Get    


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
/rewrite/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```