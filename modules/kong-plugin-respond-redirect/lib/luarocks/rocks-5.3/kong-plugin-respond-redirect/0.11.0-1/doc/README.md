## ใครไม่อิน
# คอง ปั๊ก อิน


เกริ่น นำ
=======
พอดีบริษัทเริ่มมาใช้ Gateway ยอดนิยมในเพลานี้  <br/><br/>
"คอง ข่อง คล้องงง"<br/><br/> สามารถหาอ่านรายละเอียดการติดตั้งและใช้งานตาม blog เหล่านี้ได้ ที่เขียนเกี่ยวกับ kong เป็นภาษาไทย ผมก็อ่านจากในนี้หล่ะ
* [narate-ketram] link จาน เรศ
* [sathit]
* [nextzy]

<br/>
อังกิดก็ไป  official เรย

[![Website][website-badge]][website-url]
[![Documentation][documentation-badge]][documentation-url]
[![Kong Nation][kong-nation-badge]][kong-nation-url]

[![][kong-logo]][website-url]

แต่ว่า Kong มันเป็น api gateway  หน้าตาประมาณนี้

![root][kong-root]

จะ CRUD หล่ะก็คงต้อง curl นะ แต่ถ้าเราต้อง config micorservice มากๆ เข้าคงไม่ไหว ไปทำผ่าน UI ดีกร่า โชคดีมีคนทำ UI เชื่อมกะ kong ให้ใช้ชื่อ Konga  (จานเรศมีพูดถึง [narate-ketram])
แต่ถ้าเป็นบริษัทใหญ่ๆ ต้องการ transform monolith เดิมไปเป็น microservice ไปซือ้ license Kong Enterprise ใช้เลยจะดีกว่านะเพราะมี UI official ให้ใช้และ มี plugin ที่ไม่ opensource เช่น oidc ให้ใช้ด้วย </br> หน้าตา konga ประมาณนี้ ![konga] ที่วงไว้คือทำเอง อิอิ

### เกริ่นยาวแระ มาเริ่มกันดีกร่า
![kpi][kong-plug-in]
การ dev plugin จะใช้ ภาษา lua ในการพัฒนา ร่วมกับ SDK ที่ชือ PDK(Plugin Development Kid)
ซึ่งทาง kong มี template ตัวอย่าง([kong-plugin-template]) และการสร้าง environment ([kong-vagrant])สำหรับ devและtest ตัว plugin ที่เราสร้างขึ้นมาด้วย แต่ผมสร้าง dev enviroment ใน vagrant ไม่สำเร็จนะ(ใครทำได้สอนด้วยนะ)  เลยไปยืม kong staging ของน้องที่บริษัทลองหง่ะ ดีนะทำพังแล้วเอากลับมาได้ ไม่ได้หล่ะโดนบ่นอุบแน่นวล ถถถ </br> เนือ้หาแบ่งเป็น 2 ส่วนละกันแบบเร็ว  ๆ
* 1. ไปหา helloworld มาใส่ใน kong ให้ได้
* 2. dev ไงที่ไม่ใช่ Helloworld


# ไปหา helloworld มาใส่ใน kong ให้ได้

* [0. ไปหา helloworld มาใส่](#kong-api-helloworld)
* [1. Plugin Structure](#plugin-structure)
* [2. Init Information for rockspec](#Init-Information-for-rockspec)
* [3. Create rockspec file with luarocks write_rockspec](#Create-rockspec-file-with-luarocks-write_rockspec)
* [4. Compile Plugin](#Compile-Plugin)
* [5. Pack source to library](#Pack-source-to-library)
* [6. Install](#Installation)
* [7. check plugin is installed](#check-plugin-is-installed)
* [8. add plugin to kong system](#add-plugin-to-kong-system)
* [9. kong restart](#kong-restart)


#### Kong Api HelloWorld

https://github.com/brndmg/kong-plugin-hello-world

#### Plugin Structure
อันนี้เป็นโครงสร้าง Project เราเลยหน้าตาประมาณนี้
```
- your_plugin_dir
|-kong
    |-plugins
        |-your_plugin_name
            |-handler.lua
            |-schema.lua
            |-your_some_feature.lua
|-spec
    |-your_plugin_name
        |-test_spec.lua
|-kong-plugin-your_plugin_name-0.1.0-1.rockspec //not create yet, we will use command to do
```

#### Development
กั๊กไว้ก่อนเอาไว้อธิบายตอน 2 </br>
    - develop your feature in your_some_feature.lua
    - system will call handler.lua  for start your plugin
    - and then system will use schema.lua for express to UI (Kong Enterprise,Konga)

#### Init Information for rockspec
ขั้นตอนนี้เป็นการสร้าง information ให้กับตัว Project file อะไรทำน้องนั้น ทำ โครงสร้าง project ตามตัวอย่าง add git repo ให้เรียบร้อยแล้วเด๊วใช้ tools เค้าสร้าง file project ขึ้นมาก


#### Create rockspec file with luarocks write_rockspec
ขั้นนี้หล่ะเราจะสร้าง file rockspec ที่เปรียบเสมือน file project ด้วย luarocks
```shell
$ luarocks write_rockspec --output=kong-plugin-xxx-0.1.0-1.rockspec
```
* xxx เป็นชื่อ plugin ที่เราสร้าง
* 0.1.0 เป็น versionของ plugin เรา
* -1 เป็น version ของrockspec file ว่าเราใช้ที่ versionอะไร


#### Compile Plugin
สร้าง plugin ด้วย make
```shell
$ luarocks make kong-plugin-xxx-0.1.0-1.rockspec
```

#### Pack source to library
แล้ว pack plugin ด้วย pack วรรค ชื่อ plugin วรรค  version
```shell
# luarocks pack kong-plugin-your_plugin_name version
$ luarocks pack kong-plugin-xxx 0.1.0-1
```
เสร็จแล้วเราจะได้ file .rock ขึ้นมา
    kong-plugin-xxx-0.1.0-1.all.rock
จบขั้นนี้เราจะได้ plugin เสร็จเรียบร้อย พร้อมเอาไป install ที่ kong ละ

#### Installation
เนื่องจาก vagrant ในเครื่องตัวเองไม่ได้ไงเลยไปยืม staging น้อง ถถถ
move file แล้ว install เรยด้วย รัวร๊อก
```shell
$ scp -r kong-plugin-xxx-0.1.0-1.all.rock xxx@ip:/destination
$ ssh xxx@ip
$ luarocks install kong-plugin-xxx-0.1.0-1.all.rock
```

#### check plugin is installed
หลังจาก install แล้วก็ตรวจสอบซะหน่อย ว่ามัน install ถูกที่นะ
```shell
$ cd /usr/local/share/lua/5.1/kong/plugins
$ ls -l
drwxr-xr-x 3 root root 4096 May 31 12:23 acl
drwxr-xr-x 2 root root 4096 May 31 12:23 aws-lambda
drwxr-xr-x 2 root root 4096 May 31 12:23 azure-functions
-rw-r--r-- 1 root root 1185 Apr 25 01:29 base_plugin.lua
drwxr-xr-x 3 root root 4096 May 31 12:23 basic-auth
drwxr-xr-x 2 root root 4096 May 31 12:23 bot-detection
drwxr-xr-x 2 root root 4096 May 31 12:23 correlation-id
drwxr-xr-x 2 root root 4096 May 31 12:23 cors
drwxr-xr-x 2 root root 4096 May 31 12:23 datadog
drwxr-xr-x 2 root root 4096 May 31 12:23 file-log
drwxr-xr-x 3 root root 4096 May 31 12:23 hmac-auth
drwxr-xr-x 2 root root 4096 May 31 12:23 http-log
drwxr-xr-x 2 root root 4096 May 31 12:23 ip-restriction
drwxr-xr-x 3 root root 4096 May 31 12:23 jwt
drwxr-xr-x 3 root root 4096 May 31 12:23 key-auth
drwxr-xr-x 2 root root 4096 Oct  3 10:39 xxx  <<--
drwxr-xr-x 2 root root 4096 May 31 12:23 kubernetes-sidecar-injector
drwxr-xr-x 2 root root 4096 May 31 12:23 ldap-auth
drwxr-xr-x 2 root root 4096 May 31 12:23 loggly
drwxr-xr-x 2 root root 4096 May 31 12:23 log-serializers
drwxr-xr-x 2 root root 4096 Oct  3 01:01 myplugin
drwxr-xr-x 3 root root 4096 May 31 12:23 oauth2
drwxr-xr-x 2 root root 4096 May 31 12:23 post-function
drwxr-xr-x 2 root root 4096 May 31 12:23 pre-function
drwxr-xr-x 2 root root 4096 May 31 12:23 prometheus
drwxr-xr-x 4 root root 4096 May 31 12:23 rate-limiting
drwxr-xr-x 2 root root 4096 Oct  3 01:40 rate-limiting-with-redirect
drwxr-xr-x 2 root root 4096 May 31 12:23 request-size-limiting
drwxr-xr-x 2 root root 4096 May 31 12:23 request-termination
drwxr-xr-x 2 root root 4096 May 31 12:23 request-transformer
drwxr-xr-x 4 root root 4096 May 31 12:23 response-ratelimiting
drwxr-xr-x 2 root root 4096 May 31 12:23 response-transformer
drwxr-xr-x 2 root root 4096 May 31 12:23 statsd
drwxr-xr-x 2 root root 4096 May 31 12:23 syslog
drwxr-xr-x 2 root root 4096 May 31 12:23 tcp-log
drwxr-xr-x 2 root root 4096 May 31 12:23 udp-log
drwxr-xr-x 2 root root 4096 May 31 12:23 zipkin
```

#### add plugin to kong system
แต่ถึง จะ install แล้วแต่ kong มันก็ยังไม่รู้จัก plugin เรานะ  ต้องไปบอกมันก่อน
ไปแก้ที่ kong.conf เลยจ้า
```shell
$ vi /etc/kong/kong.conf
```
* - uncomment plugins
* - add your plugin and save
* - ex. plugins = bundled,xxx
* - bundled คือ plugin default ทั้งหมดอะนะ

#### kong restart
ทำทุกอย่างเส็ดหมดแล้วรอไรหล่ะ restart แม่งเรย
``` shell
$ kong restart
```
ถ้าทำทุกอย่างถูกต้องนะมันจะเป็นงี้
``` shell
Kong stopped
Kong started
```
แต่ถ้ามีอะไรผิดเช่นเขียน code ผิด มันจะ validate ให้ก่อนและบอกว่าเราผิดตรงไหน
เช่นแบบนี้
``` shell
Error: /usr/local/share/lua/5.1/kong/cmd/start.lua:50: nginx: [error] init_by_lua error: /usr/local/share/lua/5.1/kong/init.lua:402: error loading plugin schemas: on plugin 'xxx': xxx plugin is enabled but not installed;
module 'kong.plugins.respond-redirect.handler' not found:No LuaRocks module found for kong.plugins.respond-redirect.handler
        no field package.preload['kong.plugins.xxx.handler']
        no file './kong/plugins/xxx/handler.lua'
        no file './kong/plugins/xxx/handler/init.lua'
        no file '/usr/local/openresty/site/lualib/kong/plugins/xxx/handler.ljbc'
        no file '/usr/local/openresty/site/lualib/kong/plugins/xxx/handler/init.ljbc'
        no file '/usr/local/openresty/lualib/kong/plugins/xxx/handler.ljbc'
```
ผิดไม่ร้ายแรงก็แค่กลับไปแก้ code
แต่บางที่เราก็อาจะทำอะไรลงไปแบบที่ไม่รู้ตัวนะ
กลับไปเรียก url kong ตะกี้อีกทีซิ  ถ้าไม่ขึ้นก็ล่มเรียบร้อยจ้า
จากประสบการตอนตี 2 ที่คิดว่า install ไม่สำเร็จก็ช่างมันกลายเป็น
ตี 2 ต้องมานั่งแก้ kong ให้มันกลับไปรันได้เหมือนเดิม รีบเลยชาวบ้านตื่นมาละเค้าใช้กัน

เอ๊ะตะกี้ทำไรไปฟร่ะ  ทำย้อนกลับละกัน
เริ่มจาก ทำให้มันไม่รู้จักกันก่อน กลับไป comment ตรง plugin เหมือนเดิมที่ kong.conf
ต่อด้วยการ uninstall plugin เรานี่แหล่ะ ด้วยคำสั่ง remove
``` shell
$ luarocks remove kong-plugin-xxx-0.1.0-1.all.rock
```
แล้ว restart
.
.
.
.
โอ้ว kong กลับมาแย้ววววว k ได้นอนซะที
ส่วนภาค 2
# dev ไงที่ไม่ใช่ Helloworld
ขึ้เกียจเขียนแระไว้ว่างก่อนนะ หวังว่าคนอ่านพอจะรู้เรื่องเน๊อะ




[kong-logo]: https://cl.ly/030V1u02090Q/unnamed.png
[website-url]: https://getkong.org/
[website-badge]: https://img.shields.io/badge/GETKong.org-Learn%20More-43bf58.svg
[documentation-url]: https://getkong.org/docs/
[documentation-badge]: https://img.shields.io/badge/Documentation-Read%20Online-green.svg
[kong-nation-url]: https://discuss.konghq.com/
[kong-nation-badge]: https://img.shields.io/badge/Community-Join%20Kong%20Nation-blue.svg
[kong-root]: https://www.mx7.com/i/2ee/SIiYkl.png
[konga]: https://www.mx7.com/i/0d5/jJhxVw.png
[kong-plug-in]: https://www.mx7.com/i/169/dmHrDq.png
[narate-ketram]: https://i.dont.works/kong-api-gateway-in-10-minute/
[sathit]: https://blog.sathit.me/%E0%B8%A5%E0%B8%AD%E0%B8%87%E0%B9%80%E0%B8%A5%E0%B9%88%E0%B8%99-kong-api-gateway-%E0%B9%81%E0%B8%9A%E0%B8%9A%E0%B8%82%E0%B8%B3%E0%B9%86-260d331bf803
[nextzy]: https://blog.nextzy.me/%E0%B8%8A%E0%B8%B5%E0%B8%A7%E0%B8%B4%E0%B8%95%E0%B8%94%E0%B8%B5%E0%B9%80%E0%B8%9E%E0%B8%A3%E0%B8%B2%E0%B8%B0%E0%B8%A1%E0%B8%B5-kong-%E0%B8%8A%E0%B9%88%E0%B8%A7%E0%B8%A2%E0%B8%97%E0%B8%B3-api-gateway-64816a103bb4
[konga]: https://srv-file7.gofile.io/download/vOBlgX/Screen%20Shot%202562-10-20%20at%2012.51.53.png
[kong-plugin-template]: https://github.com/Kong/kong-plugin
[kong-vagrant]: https://github.com/Kong/kong-vagrant
[kong-plugin-dev]: https://docs.konghq.com/0.14.x/plugin-development/
