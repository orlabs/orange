### 分流/AB测试插件divide API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/divide/enable     | Post

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
/divide/configs    | Get


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
                "id": "96E449BE-ECEE-4AEB-A726-A1AEA7F9DAD9",
                "name": "baidu",
                "judge": {
                    "type": 0,
                    "conditions": [
                        {
                            "type": "URI",
                            "operator": "match",
                            "value": "/baidu"
                        }
                    ]
                },
                "extractor": {
                    "extractions": [
                        {
                            "type": "Query",
                            "name": "wd"
                        }
                    ]
                },
                "log": false,
                "upstream_host": "baidu.com", //proxy_set_header Host时使用，传空字符串代表使用原始访问时的“Host”
                "upstream_url": "http://baidu.com/s?wd=${1}", //分流地址，即用于proxy_pass指令
            }
        ]
    },
    "success": true
}
```

- judge: 条件判断模块配置，一个请求经过此模块过滤后得出是否匹配该条规则的结果，然后才能进行之后的“变量提取”和“后续处理”两个模块，详见[条件判断模块](http://orange.sumory.com/docs/judge.html)
- extractor: 变量提取模块配置，如果不需要提取变量后续使用则可不配置。一个请求经过`judge`判断命中此条规则后，将通过变量提取模块提取需要的值，详见[变量提取器](http://orange.sumory.com/docs/extraction.html)

#### 3) 新建某条规则


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/divide/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式可参考"获取所有配置"API中返回数据中的data.rules[0]格式:

```
{
    "name": "代理到google",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "Header",
                "name": "flag",
                "operator": "=",
                "value": "to_google"
            }
        ]
    },
    "extractor": {
        "extractions": []
    },
    "upstream_host": "google.com",
    "upstream_url": "http://google.com.hk",
    "log": true,
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
/divide/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下:

```
{
    "name": "代理到google",
    "judge": {
        "type": 0,
        "conditions": [
            {
                "type": "Header",
                "name": "flag",
                "operator": "=",
                "value": "to_google"
            }
        ]
    },
    "extractor": {
        "extractions": [
            {
                "type": "Query",
                "name": "wd"
            }
        ]
    },
    "upstream_host": "google.com",
    "upstream_url": "http://google.com.hk?wd=${1}",
    "log": false,
    "enable": true,
    "id": "C6D3E324-070C-4C44-94C1-E45EE5B37481"
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
/divide/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


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
/divide/fetch_config       | Get    


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
/divide/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```