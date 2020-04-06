# Kong-plugin-replace-url
This kong plugin allow you to replace upstream url.

## Install
The best way to install the plugin is luarocks:
```
luarocks install kong-plugin-replace-url
```

## Configuration

form parameter|required|description
---|---|---
`name`|*required*|The name of the plugin to use, in this case: `replace-url`
`replace_template`|*required*|The regex template which used to replace upstream path.
`replace_value`|*optional*|The value is used to replace old text. Default: `""`

## How it work
The plugin will replace your upstram path with regex.

Such as a request like that:
```
http://localhost:8000/x-user-srv/users
```

And configuration as below:

- `replace_template`: /[xX]%-[a-zA-Z-]
- `replace_value`: ""

Kong will send upstream path for that:
``
/users
``

As you see, the plugin replace matched string to empty.
