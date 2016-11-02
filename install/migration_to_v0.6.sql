ALTER TABLE redirect ADD sort INT DEFAULT 0 AFTER `value`;
update redirect set sort=id;

ALTER TABLE rewrite ADD sort INT DEFAULT 0 AFTER `value`;
update rewrite set sort=id;

ALTER TABLE key_auth ADD sort INT DEFAULT 0 AFTER `value`;
update key_auth set sort=id;

ALTER TABLE basic_auth ADD sort INT DEFAULT 0 AFTER `value`;
update basic_auth set sort=id;

ALTER TABLE divide ADD sort INT DEFAULT 0 AFTER `value`;
update divide set sort=id;

ALTER TABLE monitor ADD sort INT DEFAULT 0 AFTER `value`;
update monitor set sort=id;

ALTER TABLE monitor ADD sort INT DEFAULT 0 AFTER `value`;
update monitor set sort=id;

ALTER TABLE rate_limiting ADD sort INT DEFAULT 0 AFTER `value`;
update rate_limiting set sort=id;

ALTER TABLE waf ADD sort INT DEFAULT 0 AFTER `value`;
update waf set sort=id;
