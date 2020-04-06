# Kong Cluster Drain
## Overview
Drain and divert your traffic without briging down the LTM and iterrupting existing traffic by a switch that allows failing your healthcheck to a datacenter.

## Explanation:

This plugin we have used in tandem with our other plugin here:
https://github.com/Optum/kong-splunk-log

Because you need to have a specific NGINX ENV variable set - 

If not already set, it can be done so as follows:
```
$ export SPLUNK_HOST="gateway-datacenter.company.com"
```

**One last step** is to make the environment variable accessible by an nginx worker. To do this, simply add this line to your _nginx.conf_
```
env SPLUNK_HOST;
```

Once done the plugin takes in a 'host' argument that needs to match that of your SPLUNK_HOST environment variable when you intend for this plugin to be active and enabled on top of your healthcheck proxy endpoint in pushing traffic away from your datacenter/cluster.

The real benefit here is you end up with no traffic downtime because if you cut off your LTM prior to draining your traffic and diverting it you will lose all the active connections/transactions at that moment in time.

Feel free to fork this and use a seperate environment variable of your own if desired! Think of SPLUNK_HOST environment variable as a marker tag for certain Kong Nodes/Clusters in your respective datacenters.

## Supported Kong Releases
Kong >= 1.x

## Installation
Recommended:
```
$ luarocks install kong-cluster-drain
```

Optional
```
$ git clone https://github.com/Optum/kong-cluster-drain
$ cd /path/to/kong/plugins/kong-cluster-drain
$ luarocks make *.rockspec
```

## Maintainers
[jeremyjpj0916](https://github.com/jeremyjpj0916)  
[rsbrisci](https://github.com/rsbrisci)  

Feel free to open issues, or refer to our Contribution Guidelines if you have any questions.
