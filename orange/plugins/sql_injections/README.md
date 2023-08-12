### init sql

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for sql_injections
-- ----------------------------
DROP TABLE IF EXISTS `sql_injections`;
CREATE TABLE `sql_injections`  (
  `id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `key` varchar(255) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `value` varchar(2000) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `type` varchar(11) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT '0',
  `op_time` timestamp(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0) ON UPDATE CURRENT_TIMESTAMP(0),
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `unique_key`(`key`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 16 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of sql_injections
-- ----------------------------
INSERT INTO `sql_injections` (`id`, `key`, `value`, `type`, `op_time`)
VALUES
    (1,'1','{}','meta','2016-11-11 11:11:11');

SET FOREIGN_KEY_CHECKS = 1;
```


### 测试

```bash
curl --location 'http://192.168.56.100?test=test%3B%20DROP%20users%3B' \
--header 'Cookie: Hm_lvt_40028a604fad74cc0dee058f9a116c82=1691457547,1691723036; SOPEIID=2e0b60447159506a7505998964108006864; SOPEIID.sig=ZZqYDek_vK4IgHjMsx1v50HTvd4; Hm_lpvt_40028a604fad74cc0dee058f9a116c82=1691723046' \
--header 'Referer: https://servicewechat.com/wx51f2f66c1f2b50fe/devtools/page-frame.html'
```


```bash
curl --location 'http://192.168.56.100?test=4%20union%20select%201%2C1%2Cversion()%2C1' \
--header 'Cookie: Hm_lvt_40028a604fad74cc0dee058f9a116c82=1691457547,1691723036; SOPEIID=2e0b60447159506a7505998964108006864; SOPEIID.sig=ZZqYDek_vK4IgHjMsx1v50HTvd4; Hm_lpvt_40028a604fad74cc0dee058f9a116c82=1691723046' \
--header 'Referer: https://servicewechat.com/wx51f2f66c1f2b50fe/devtools/page-frame.html'
```
