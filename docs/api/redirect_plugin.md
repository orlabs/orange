### URL重定向插件redirect API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/redirect/enable     | Post

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
/redirect/configs    | Get


**参数**   
无 

**返回结果** 

```
{
    "success": true,
    "data": {
        "enable": true, //该插件是否开启
        "rules": [ //该插件下的规则列表
            {
                "enable": true, //此条规则是否开启
                "id": "3666DE3C-6202-4971-B277-1214AA1B9CA3", //此条规则的id
                "judge": { // "条件判断模块"配置，详见下文描述
                    "type": 3, // 条件判断的类型
                    "expression": "v[1] and v[2]", //type配置成了3，此字段指要对conditions做什么操作得出“条件判断”的结果值
                    "conditions": [ //条件集合
                        {
                            "type": "URI",
                            "operator": "match",
                            "value": "^/redirect_to$"
                        },
                        {
                            "type": "Header",
                            "operator": "=",
                            "name": "uid",
                            "value": "12345"
                        }
                    ]
                },
                "time": "2016-06-21 14:50:27", //该规则创建或更新时间
                "name": "redirect实例", //规则名称
                "extractor": { // "变量提取模块"配置
                    "extractions": [
                        {// 提取Query String中的某个字段，这里为username
                            "type": "Query",
                            "name": "username"
                        },
                        {// 提取Header头中的某个字段，这里为uid
                            "type": "Header",
                            "name": "uid"
                        },
                        {// 提取http请求的host，如baidu.com
                            "type": "Host"
                        },
                        {// 从URI中提取变量，这里提取“/redirect_to/”后的字符串
                            "type": "URI",
                            "name": "/redirect_to/(.*)"
                        }
                    ]
                },
                "handle": { // ”后续处理模块“配置
                    "trim_qs": false, //是否需要清除原始请求的Query String
                    "url_tmpl": "/to/${4}/${1}?uid=${2}&host=${3}", //要redirect到的URL模板，${number}指的是变量提取模块提取出的变量
                    "log": false //是否记录此次规则匹配时的日志
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
/redirect/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式可参考"获取所有配置"API中返回数据中的data.rules[0]格式:

```
{
    "name": "redirect实例",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "URI",
                "operator": "match",
                "value": "^/redirect_to$"
            }
        ]
    },
    "extractor": {
        "extractions": [
            {
                "type": "Query",
                "name": "username"
            },
            {
                "type": "Header",
                "name": "uid"
            },
            {
                "type": "Host"
            },
            {
                "type": "URI",
                "name": "/redirect_to/(.*)"
            }
        ]
    },
    "handle": {
        "url_tmpl": "/to/${4}/${1}?uid=${2}&host=${3}",
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
    "msg": "新建规则成功"
}
```

#### 4) 编辑某条规则信息

**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/redirect/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下:

```
{
    "id": "3666DE3C-6202-4971-B277-1214AA1B9CA3",
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
/redirect/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


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
/redirect/fetch_config       | Get    


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
/redirect/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```