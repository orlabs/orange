### 自定义监控插件monitor API

#### 1) 开启或关闭此插件

**请求**

URI                 | Method 
------------------- | ---- 
/monitor/enable     | Post

**参数** 

名称 | 类型 | 说明
---- | ---- | -------
enable | int | 0关闭1开启


**返回结果** 

```
{
	"msg":"关闭自定义监控成功",
	"success":true
}
```

#### 2) 获取所有配置信息

**请求**

URI                 | Method 
------------------- | ---- 
/monitor/configs    | Get


**参数**   
无 

**返回结果** 

```
{
    "data": {
        "enable": true,//插件是否启用
        "rules": [ //插件下的"规则"列表
            {
                "enable": true, //本条规则是否启用
                "id": "D26E0C12-C687-4004-82C7-9AF258FE6470", //规则id
                "judge": { // "条件判断模块"配置
                    "type": 3, // 见下文描述
                    "expression": "(v[1] or v[2]) and v[3]", // 见下文描述
                    "conditions": [// 见下文描述
                        {
                            "type": "URI",
                            "operator": "match",
                            "value": "/abc"
                        },{
                            "type": "Header",
						    "operator": "=",
						    "name": "uid",
						    "value": "123"
                        },{
                            "type": "Host",
						    "operator": "=",
						    "value": "127.0.0.1"
                        }
                    ]
                },
                "time": "2016-05-04 18:57:23",//规则新建或更改时间
                "name": "/abc",// 规则名称
                "handle": { // "处理模块"配置
                    "log": false, // 是否记录日志
                    "continue": true // 匹配完该条规则后是否继续后续匹配
                }
            }
        ]
    },
    "success": true
}
```

- type: 0/1/2/3，0表示只有一个匹配条件，1表示对所有条件与操作，2表示对所有条件或操作，3表示按照另一个字段expression对所有条件求值
- expression: 当type为3时，存在此字段且不为空，它的格式是一个lua的逻辑判断表达式。表达式中每个值的格式为v[index], 比如v[1]对应的就是第一个条件的值。示例：(v[1] or v[2]) and v[3]，即前两个条件至少一个为真并且第三个条件为真时，规则为真。
conditions: 匹配条件集合
- conditions: [匹配条件](http://orange.sumory.com/docs/condition.html)集合

#### 3) 新建某条规则


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/monitor/configs    | Put    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指一条"规则"json格式的字符串


"规则"格式示例如下，具体格式描述见[这里](http://orange.sumory.com/docs/rule.html):

```
{
    "name": "/abc",
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
        "continue": true,
        "log": false
    },
    "enable": true,
    "id": "D26E0C12-C687-4004-82C7-9AF258FE6470"
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
/monitor/configs    | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


**参数** 

名称 | 类型 | 说明
---- | ---- | -------
rule | string | 指修改后的"规则"


"规则"格式示例如下，具体格式描述见[这里](http://orange.sumory.com/docs/rule.html):

```
{
    "name": "/abc",
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
        "continue": true,
        "log": false
    },
    "enable": true,
    "id": "D26E0C12-C687-4004-82C7-9AF258FE6470"
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
/monitor/configs    | Delete    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8


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


#### 6) 获取满足某条规则的请求的统计信息

**请求**

URI                 | Method 
------------------- | ------ 
/monitor/stat       | Get    


**参数** 

名称     | 类型   | 说明
----    | ----   | -------
rule_id | string | 指一条"规则"的id

**返回结果** 

```
{
    "success": true,
    "data": {
     	"average_traffic_read": 0, //请求平均读流量，bytes
        "request_2xx": 0,
        "average_traffix_write": 0, //请求平均写流量，bytes
        "request_4xx": 0,
        "request_5xx": 0,
        "traffic_read": 0,//读总流量，kb
        "request_3xx": 0,
        "traffic_write": 0,//写总流量，kb
        "total_request_time": 0, //总请求时间，s
        "average_request_time": 0, //平均响应时间，ms
        "total_count": 0 //总请求数
    }
}
```


##### 7) 获取数据库中此插件的最新配置

**请求**

URI                 | Method 
------------------- | ------ 
/monitor/fetch_config       | Get    


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

具体规则格式描述见[这里](http://orange.sumory.com/docs/rule.html)


##### 8) 将数据库中最新配置更新到此orange节点


**请求**

URI                 | Method | 说明
------------------- | ------ | -----
/monitor/sync       | Post    | Content-Type:application/x-www-form-urlencoded; charset=UTF-8

**参数**   
无

**返回结果** 

```
{
    "success": true, //成功或失败
    "msg": "" //描述信息
}
```