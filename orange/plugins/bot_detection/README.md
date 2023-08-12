### init sql

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for bot_detection
-- ----------------------------
DROP TABLE IF EXISTS `bot_detection`;
CREATE TABLE `bot_detection`  (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `key` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `value` varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `type` varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0',
  `op_time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0) ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `unique_key`(`key`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of bot_detection
-- ----------------------------
INSERT INTO `bot_detection` (`id`, `key`, `value`, `type`, `op_time`)
VALUES
    (1,'1','{}','meta','2016-11-11 11:11:11');

SET FOREIGN_KEY_CHECKS = 1;
```


### 测试

```bash
curl --location 'http://192.168.56.100' \
--header 'User-Agent: Pingdom.com_bot_version_1.4'
```


```bash
curl --location 'http://192.168.56.100' \
--header 'User-Agent: aws-cli/1.23.12 Python/3.9.13 Linux/5.4.273-137.508.amzn2.x86_64 exec-env/AWS_CLI boto3/1.24.18'
```


```bash
curl --location 'http://192.168.56.100' \
--header 'User-Agent: Baiduspider+ (http://www.baidu.com/search/spider_jp.html)'
```
