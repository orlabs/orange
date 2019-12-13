## 0.8.1
> Released on 2019.12.12

#### Feature

- Integrated Automation Construction Platform (Travis CI).
- Added basic test framework (Test :: Nginx).
- Add test cases for `headers` plugin.
- Add test cases for the `redirect` plugin.
- Add test cases for `rewrite` plugin.
- Add test cases for `basic_auth` plugin.
- Add test cases for `key_auth` plugin.
- Add test cases for `jwt_auth` plugin.
- Add test cases for `signature_auth` plugin.
- Add test cases for `rate_limiting` plugin.
- Add test cases for `waf` plugin.
- Add test cases for `divide` plugin.

#### FIX

- Fixed `luarocks` installation` api` directory not exists.

#### Document

- Added usage documentation for `headers` plugin.
- Added usage documentation for `redirect` plugin.
- Added usage documentation for `rewrite` plugin.
- Added usage documentation for `basic_auth` plugin
- Added usage documentation for `key_auth` plugin.
- Added usage documentation for `jwt_auth` plugin.
- Added usage documentation for `signature_auth` plugin.
- Added usage documentation for `rate_limiting` plugin.
- Added usage documentation for `waf` plugin.
- Added usage documentation for `divide` plugin.
- Added usage documentation for `global_statistics` plugin.

#### Change

- `lua-resty-consul` dependency library changed from storing in the project to installing using` luarocks`.
- `nginx.conf` The default log level, adjusted from` info` to `error`.
- The `balancer` plugin migrated to` v0.9.0-dev` due to conflicts with existing features.
- The `dynamic_upstream` plugin migrated to` v0.9.0-dev` due to conflicts with existing features.
- The `consul_balancer` plugin migrated to` v0.9.0-dev` due to conflict with existing functions.
- The `persist` plugin migrated to` v0.9.0-dev` due to conflicts with existing features.

## 0.8.0 
> Released on 2019.10.18

#### Feature

- Dependency installation changed from `opm` to` luarocks` for dependency installation and environment deployment.


## 0.7.1 
> Released on 2019.07.09

#### Feature

- Use `opm` to install` Orange` dependencies.

#### FIX

- Fixed `Makefile` installation project dependency issue.
- Fixed the problem of obtaining template variables.
- Fixed the issue that `balancer` cannot be read after adding` divide` shunt plugin.


## 0.7.0 
> Released on 2019.04.01

#### Feature

- Supports request interception filtering through `cookie`,` random number`, and `HTTP Method`.
- Added the method of taking margin for rule matching.
- Added `kafka` plugin.
- Added `balancer` plugin.
- Added `consul_balancer` plugin.
- Added `persist log` plugin.
- Added `node` plugin.

#### FIX

- Fixed dashboard page display problem.
- Fixed `invalid URL prefix in" "error when` balancer` switch is not turned on.
- Fixed `continue = false` error when selector type is` 1`.
- Fixed invalid proxy read timeout configuration.
- Fixed the problem of ignoring case for matching authentication value.

#### Change

- Refactored the management code and documentation of `balancer` module.
- Update `Makefile` to specify version for dependencies.

## 0.6.4 
> Released on 2017.05.16

#### Feature

- Added default template for `github issue`.
- Added `log` configuration to the default configuration file.

#### FIX

- Fixed the problem of missing rules caused by the local `JavaScript Cache` not being updated after adding and removing rules.
- Fixed spelling issue in `PR`.

#### Change

- Modify `Makefile` to support custom installation path.
- Remove the documentation in `docs/api`. For more documents, please visit [Official Website](http://orange.sumory.com).

## 0.6.3
> Released on 2017.03.10

#### Feature

- Added `signature auth` plugin.
- Added default configuration file templates `ngingx.conf.example` and` orange.conf.example`.

## 0.6.2 
> Released on 2017.02.18

#### Feature

- Compatible with `Orange` and the latest version of` Lor Framework`, ie `lor v0.3.0`.

#### Note

- If the `Orange` version is below` 0.6.2`, then `lor v0.2.x` Version should be installed, `lor v0.2.6` is recommended.
- If `Orange` version is` 0.6.2` or above, you can upgrade `lor v0.3.0 +` version.

## 0.6.1 
> Released on 2017.02.09

#### Feature

- Added `property based rate limiting` plugin.

## 0.6.0 
> Released on 2016.11.13

#### Feature

- Refactored `Dashboard`.
- Added `kvstore` plugin for accessing` shared dict` data via API.
- Refactored rule design, changed to hierarchical structure when filtering traffic, grouped rules by `selector`.
- Extract plug-in API public code so that it can be maintained uniformly.

#### Note

- `Orange 0.6.x` Is not compatible with previous versions.

## 0.5.1
> Released on 2016.11.10

#### FIX

- Fixed SQL import issue.

## 0.5.0 
> Released on 2016.10.04

#### Feature

- Added `Makefile` installation method.
- Initialize database via command line `orange store`.
- Added `resty-cli` support, command` orange [start | stop | restart | reload | store] `.

#### Change

- Move `*.conf` configuration to `conf` directory.


## 0.4.0 
> Released on 2016.09.24

#### Feature

- Added `rate limiting`, current limiting plugin.
- Added prevention repeat submit mechanism (delay).
- Added `key auth` plugin.

#### Change

- Remove `examples`。


### v0.3.0 
> Released on 2016.07.21

#### Feature

- Added `Basic Auth` plugin.

## 0.2.0
> Released on 2016.07.15

#### Feature

- `API Server` supports` HTTP Basic Authorization`.
- Variable extraction module adds new types, `URL` extractor supports extracting multiple values at once. The template method uses variables in the format `{{extractor.key}}`.
- Provide `Restful API` and detailed description document.
- Separate built-in `Dashboard` to reduce coupling with API.

#### Change

- Removed `file store` support.

## 0.1.1 
> Released on 2016.05.09

#### Feature

- When using `MySQL` as storage, add user system for` Dashboard`.

## 0.1.0 
> Released on 2016.05.04

#### Feature

- Configuration items support `file` and `MySQL` storage.
- Simple support for cluster deployment via `MySQL` storage.
- Support extended functions through custom plugins.
- Added `Global statistics`, global status statistics plugin.
- Added `Custom monitoring`, custom monitoring plugin.
- Added `URL Rewiter`, URL rewrite plugin.
- Added `URL Redirect`, URI redirection plugin.
- Added `WAF`, firewall plugin.
- Added `ABTesting`, shunt plugin.
- Provide management interface for managing built-in plugins.
