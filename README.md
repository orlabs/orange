# Orange

API Gateway based on OpenResty.


### Install

Clone the repo to local. Check the sample config file `orange.conf` first:

```javascript
{
    "plugins": [ //available plugins. remove one if you do not need it.
        "stat", 
        "monitor", 
        "redirect", 
        "rewrite", 
        "waf", 
        "divide"
    ],

    "store": "mysql",//only support `mysql` for now
    "store_mysql": { //config if you choose `mysql` store
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

    "dashboard": {//dashboard config. if `store` is `mysql`, this will make sense
        "auth": false, //the dashboard UI should be authorized or not
        "session_secret": "y0ji4pdj61aaf3f11c2e65cd2263d3e7e5", // used to encrypt cookie
        "whitelist": [//url list that needn't be authorized
            "^/auth/login$",
            "^/error/$"
        ]
    }
}
```

Import `install/orange-${version}` to MySQL and modify `store_mysql` as you want before you start `Orange`.

Then just type `sh start.sh` to start Orange. Maybe you should check the start script and customize it for your own need.


### Documents

Find all about **Orange** on [Documents Website](http://orange.sumory.com/docs). There is only a Chinese version for now.


### Docker

[http://hub.docker.com/r/syhily/orange](http://hub.docker.com/r/syhily/orange) maintained by [@syhily](https://github.com/syhily)


### Contributors

- [@雨帆](https://github.com/syhily)


### See also

The architecture is highly inspired by [Kong](https://github.com/Mashape/kong).


### License

[MIT](./LICENSE)
