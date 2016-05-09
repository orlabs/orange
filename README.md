# Orange

API Gateway based on OpenResty.


### Install

Clone the repo to local. Check the sample config file `orange.conf` first:

```
{
    "plugins": [ //available plugins. remove one if you do not need it.
        "stat", 
        "monitor", 
        "redirect", 
        "rewrite", 
        "waf", 
        "divide"
    ],

    "store": "file",//which `store` to use, `file` or `mysql`
    "store_file": { //configuration if you choose `file` store
        "path": "./data.json",
        "desc": "file db configuration"
    },

    "store_mysql": { //configuration if you choose `mysql` store
        "timeout": 5000,
        "connect_config": {
            "host": "127.0.0.1",
            "port": 3306,
            "database": "orange",
            "user": "root",
            "password": "",
            "max_packet_size": 1048576
        },
        "pool_config": {
            "max_idle_timeout": 10000,
            "pool_size": 3
        },
        "desc": "mysql configuration"
    },
    "dashboard": {//dashboard configuration. if `store` is `mysql`, this will make sense
        "auth": false, //if the dashboard UI shoule be authorized
        "session_secret": "y0ji4pdj61aaf3f11c2e65cd2263d3e7e5", // used to encrypt cookie
        "whitelist": [//needn't check authorization
            "^/auth/login$",
            "^/error/$"
        ]
    }
}
```

If you just need a single Orange node, set `store` with `file`, then your configuration will be stored in `store_file.path` with json format.

Otherwise, if you need share the configuration data of Orange plugins among different Orange nodes, set `store` with `mysql` and import `install/orange-${version}-${min_version}` to MySQL 
and modify the `store_mysql` config as you want.

Then just type `sh start.sh` to start Orange. Maybe you should check the start script and customize it for you own need.


### Documents

Find all about **Orange** on [Documents Website](http://orange.sumory.com/docs). There is only a Chinese version for now.


### See also

The architecture is highly inspired by [Kong](https://github.com/Mashape/kong).


### License

[MIT](./LICENSE)