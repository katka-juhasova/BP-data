# kong-redirect
根据返回的Http Code, 设置Location
## Kong 插件开发
https://docs.konghq.com/1.0.x/pdk/
#### 文件结构:
handler.lua: 必须，定义回调函数
scheme.lua: 必须，定义配置的样式
api.lua: 定义接口
daos.lua: Database Access Objects
migrations/*.lua: 跟daos配合使用
#### 安装
开发的plugin如果需要新建数据库，必须再次运行:
`kong migration up`
#### 参考文档
- kong 插件开发: https://docs.konghq.com/1.1.x/plugin-development/distribution/
- kong demo: https://github.com/Kong/kong-plugin
- rock: https://github.com/luarocks/luarocks/wiki/Creating-a-rock
## 其他
docker cp ./kong/plugins/myredirect kong:/usr/local/share/lua/5.1/kong/plugins/myplugin