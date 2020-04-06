# Kong - Spherical Defence

A Kong plugin that validates inbound requests against a running Spherical instance before proxying the original.

## Setting up Kong

The Docker Compose template in this repository provisions a Kong container with a Postgres database, plus a nginx load-balancer. After running the template, the nginx-lb load-balancer will be the entrypoint to Kong.

To run this template execute:

<pre>
$ docker-compose up
</pre>

The subsequent instructions must be executed within the main Kong container.

### Development

Navigate to kong/plugins folder and clone this repo

<pre>
$ git clone https://gitlab.com/spherical-defence/integrations integrations && mv integrations/Kong kong-sphericaldefence-plugin && rm -rf integrations && cd kong-sphericaldefence-plugin
$ luarocks make *.rockspec
</pre>

When you have pushed up your source changes, you need to tar the repo, and upload it to this S3 bucket.

<pre>
https://kong-sphericaldefence.s3-us-west-2.amazonaws.com/kong-sphericaldefence-plugin.tar.gz
</pre>

Once you have done this, run the following command to build the sphericaldefence luarock.

<pre>
$ luarocks upload *.rockspec
</pre>


## Installation

<pre>
$ luarocks install sphericaldefence
$ echo 'export KONG_PLUGINS=sphericaldefence' >> ~/.bashrc 
$ kong prepare
$ kong reload
</pre>


## Configuration

You can add the plugin on top of a service by executing the following request on your Kong server:

<pre>
$ curl -X POST http://kong:8001/service/{service}/plugins \
    --data "name=sphericaldefence" \
    --data "config.url=http://18.234.220.67"
    --data "config.blocking=true"
    --data "config.timeout=10000"
    --data "config.keepalive=60000"
</pre>

<table><thead>
<tr>
<th>form parameter</th>
<th>default</th>
<th>description</th>
</tr>
</thead><tbody>
<tr>
<td><code>name</code></td>
<td></td>
<td>The name of the plugin to use, in this case: <code>sphericaldefence</code></td>
</tr>
<tr>
<td><code>config.url</code><br><em>required</em></td>
<td></td>
<td>The address of a Spherical Defence instance to which the plugin will validate before proxying the original request.</td>
</tr>
<tr>
<td><code>config.timeout</code></td>
<td></td>
<td>Timeout (miliseconds) for the request to the URL specified above. Default value is 10000.</td>
</tr>
<tr>
<td><code>config.keepalive</code></td>
<td></td>
<td>Keepalive time (miliseconds) for the request to the URL specified above. Default value is 60000.</td>
</tr>
</tbody></table>

The plugin will execute a JSON <code>POST</code> request to the Spherical instance with the following body:

<table>
    <tr>
        <th>Attribute</th>
        <th>Description</th>
    </tr>
    <tr>
    <td><code>body_data</code></td>
    <td><small>The body of the original request</small></td>
    </tr>
    <tr>
        <td><code>url_args</code></td>
        <td><small>The url arguments of the original request</small></td>
    </tr>
    <tr>
        <td><code>headers</code></td>
        <td><small>The headers of the original request</small></td>
    </tr>
      <tr>
        <td><code>uri</code></td>
        <td><small>The uri of the original request</small></td>
    </tr>
      <tr>
        <td><code>method</code></td>
        <td><small>The method of the original request</small></td>
    </tr>
</table>


## Original Author
Panagis Tselentis

## License
<pre>
The MIT License (MIT)
=====================

Copyright (c) 2015 Panagis Tselentis

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
</pre>
