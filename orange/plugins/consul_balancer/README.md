支持consul的upstream服务发现插件。

部署要点：
1.mysql中增加sql：
    # Dump of table consul_balancer
    # ------------------------------------------------------------

    DROP TABLE IF EXISTS `consul_balancer`;

    CREATE TABLE `consul_balancer` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `key` varchar(255) NOT NULL DEFAULT '',
    `value` varchar(2000) NOT NULL DEFAULT '',
    `type` varchar(11) DEFAULT '0',
    `op_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_key` (`key`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    LOCK TABLES `consul_balancer` WRITE;
    /*!40000 ALTER TABLE `balancer` DISABLE KEYS */;

    INSERT INTO `consul_balancer` (`id`, `key`, `value`, `type`, `op_time`)
    VALUES
        (1,'1','{}','meta','2017-11-11 11:11:11');

    /*!40000 ALTER TABLE `balancer` ENABLE KEYS */;
    UNLOCK TABLES;

2.nginx.conf中增加共享内存：
    lua_shared_dict consul_upstream 5m; # used for consul upstream cache, see plugin : consul_balancer
    lua_shared_dict consul_upstream_watch 1m; # used for consul upstream cache, see plugin : consul_balancer
    lua_shared_dict consul_upstream_stat 1m; # used for consul upstream statistic, see plugin : consul_balancer

3.orange.conf中增加:
    "plugins"中增加consul_balancer;
    在"api"之后增加consul服务的配置信息，例如
    "consul": {
        "host" : "10.0.201.156",
        "port" : 8500,
        "interval" : 10,
        "token" : 'token'
    }
    interval计量单位为s
    token为ACL中指定的token,(注，未测试)

4.需要关注的地方：
 ①consul_balancer插件在一些逻辑上未考虑与balancer插件的兼容性，所以在评估时记得禁用balancer插件；
 ②插件发现的upstream列表尚未支持对权重等信息的编辑删除操作，可自定制；
 ③插件是resty工作进程0上启动定时器获取consul数据，如果您的resty设计工作进程0启动后有销毁等动作，需要自行调整下逻辑。

5.示例：
 假设我们网站有个api服务mytest挂在域名test.foo下，api在consul集群中注册的服务名为s_test，有10.0.201.119、10.0.201.161、10.0.201.182三个节点。orange部署监听127.0.0.1的80端口。
 ①开启divide代理&分流插件，添加选择器sel_test,选择规则Host match "test.foo"。在该选择器的规则列表中点击“增加新规则”按钮增加规则，在处理的“upstream host”栏中填入host，例如test.foo。在“upstream url”栏中填入您的consul服务中真实存在的服务名，这里填入s_test。保存规则的时候记得勾上启用按钮；
 ②开启Consul Balancer插件，增加选择器mytest，服务名填入①中指定的服务名，这里填入s_test。勾选启用、保存。右侧的“Upstream【mytest】hosts 列表”会刷新consul集群中采集到的s_test服务的upstream节点列表。节点列表会实时同步consul的信息，但页面不会自动刷新，需要手动点击选择器来观察最新列表情况；
 ③支持简单的访问统计，通过访问 curl -v -H 'host:test.foo' http://127.0.0.1:80/test若干次后，点击Consul Balancer插件对应的选择器，我们会看到一个简单的节点分发计数饼图；