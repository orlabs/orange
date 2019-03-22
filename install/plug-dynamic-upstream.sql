DROP TABLE IF EXISTS `dynamic_upstream`;
CREATE TABLE `dynamic_upstream` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL DEFAULT '',
  `value` varchar(2000) NOT NULL DEFAULT '',
  `type` varchar(11) DEFAULT '0',
  `op_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
INSERT INTO `dynamic_upstream` (`id`, `key`, `value`, `type`, `op_time`)
VALUES
    (1,'1','{}','meta','2016-11-11 11:11:11');
