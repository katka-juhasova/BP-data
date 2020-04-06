# kong-simple-request-validator

### install

```bash
luarocks install lua-resty-validation
luarocks install jsonschema
luarocks install kong-simple-request-validator

```

### example

```bash
curl -X POST http://127.0.0.1:8001/routes/8237b4d5-1cf1-438b-824a-de1f37e59f60/plugins \
    --data "name=kong-simple-request-validator" \
    --data "config.form_schema=[{\"name\":\"url\",\"type\":\"string\",\"required\":true,\"len_max\":5}]" \
    --data "config.query_schema=[{\"name\":\"url\",\"type\":\"string\",\"required\":true,\"len_max\":6}]" \
    --data "config.json_schema={\"\$schema\":\"http://json-schema.org/draft-04/schema#\",\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"}}}"
```

### Parameters

#### 请求参数
参数名| 类型 |必需| 说明
---|---|---|---
form_schema | json | N | form表单校验配置
query_schema | json | N | query校验配置
json_schema | json | N | json schema校验配置，provides a JSON schema draft 4, draft 6, draft 7 validator

### form_schema,query_schema 支持的校验配置

函数 | 类型 |必需| 说明
---|---|---|---
name | string | Y | 规则需要应用的参数（query或者form中的参数）
type | string | Y | 类型(暂时支持string,number类型)
required | bool  | Y | 是否必须
len_eq | number | N | 如果type为string，长度等于
len_min | number | N | 如果type为string，长度大于或等于
len_max | number | N | 如果type为string，长度小于或等于
email | string | N | 如果type为string，必须为email格式
eq | number | N | 如果type为number，等于给定值
un_eq | number | N | 如果type为number，不等于给定值
min | number | N | 如果type为number，小于或等于给定值
max | number | N | 如果type为number，大于或等于给定值













