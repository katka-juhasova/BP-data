# lua-resty-paypal
Simple lua wrapper for Paypal REST API.

# Installation

### Luarocks

```bash
#luarocks install lua-resty-paypal
```

### Github
```bash
$git clone https://github.com/paragasu/lua-resty-paypal
$cd lua-resty-paypal
$resty test/test.lua
```

# Usage
```lua
  local Paypal = require 'resty.paypal'
  local paypal = Paypal.new({
    client_id: 'xx', -- paypal client id
    secret: 'xx', -- paypal secret
    env: 'live'
  })

  -- https://developer.paypal.com/docs/api/payments/#payment_create
  local res, err = paypal:post('payments/payment', {
      intent = "sale",
      payer = {
        payment_method = "paypal",
      },
      transactions = {
        {
          description = "something to pay",
          amount = { total = "30.10", currency = "USD" }  
        }
      },
      redirect_urls = {
        return_url = "https://www.example.com/return",
        cancel_url = "https://www.example.com/cancel"
      } 
  })

  -- https://developer.paypal.com/docs/api/payments/#payment_execute
  local res, err = paypal:post('payments/execute', {
    payment_id: "xxx",
    payer_id: "xxx"
  })
```

# API

### **.new**_(config)_
  Config is a table with *client_id*, *secret* and *env* key
  - client\_id from paypal developer setting
  - secret from paypal developer setting
  - env is `live` or `sandbox`

### **:post**_(api\_path, params)_
  Call paypal POST api
  - api_path api path eg _payments/payment_ excluding version `/v1`
  - params table of params as required in doc 

### **:get**_(api\_path, params)_
  Call paypal GET api
  - api_path api path eg _payments/payment_
  - params table of params as required in doc 

### **:put**_(api\_path, params)_
  Call paypal PUT api
  - api_path api path eg _payments/payment_
  - params table of params as required in doc 

### **:patch**_(api\_path, params)_
  Call paypal PATCH api
  - api_path api path eg _payments/payment_
  - params table of params as required in doc 

### **:delete**_(api\_path, params)_
  Call paypal DELETE api
  - api_path api path eg _payments/payment_
  - params table of params as required in doc 

Some api\_path is not so straight forward and need to be constructed before passing as api path.
For example, payments sale api is `/v1/payments/sale/{sale_id}` 


# Reference
[Paypal REST documentation](https://developer.paypal.com/docs/api/overview)  
[Paypal Express Checkout v4 REST API](https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4)  
[Paypal REST server side integration](https://developer.paypal.com/docs/integration/direct/express-checkout/integration-jsv4/server-side-REST-integration)  
