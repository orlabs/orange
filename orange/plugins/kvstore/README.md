### KV store

暴露shared dict的数据到API， 主要适用于以下场景：

- 拉取存储到shared dict的某些数据
- 更改使用shared dict存储的一些配置信息
- 下发一些配置信息（如版本号），直接在网关定义API，不需要后端开发
