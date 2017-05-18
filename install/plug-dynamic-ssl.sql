
# Dump of table dynamic_ssl
# ------------------------------------------------------------

DROP TABLE IF EXISTS `dynamic_ssl`;
CREATE TABLE `dynamic_ssl` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL DEFAULT '',
  `value` text NOT NULL DEFAULT '',
  `type` varchar(11) DEFAULT '0',
  `op_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
INSERT INTO `dynamic_ssl` (`id`, `key`, `value`, `type`, `op_time`)
VALUES
    (1,'1','{}','meta','2016-11-11 11:11:11');

/*!40000 ALTER TABLE `dynamic_ssl` ENABLE KEYS */;
UNLOCK TABLES;
