### KAFKA插件

- 需加入如下配置到conf/orange.conf里，与配置中的plugins平级即可：


    "plugin_config":{
        "kafka":{
            "broker_list":[
                {
                    "host":"127.0.0.1",
                    "port":9092
                }
            ],
            "producer_config":{
                "producer_type":"async"
            },

            "topic":"test"
        }
    },


