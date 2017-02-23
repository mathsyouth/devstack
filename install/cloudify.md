# Cloudify
## Introduction

[See](http://getcloudify.org/cloud_orchestration_cloud_automation.html) more about Cloudify orchestrator !

## Install

### Cloudify CLI

Cloudify CLI allow to create cloudify-manager-server on OpenStack cloud platform

To install Cloudify CLI you have two choice :
* Follow cloudify [documentation](http://docs.getcloudify.org/3.4.0/intro/installation/) to install Cloudify CLI
  on Windows, Linux or OSX and after read the next part (Cloudify manager deployment);
* Provide cloudify CLI VM on OpenStack platform (My environment is OpenStack Mitaka installed by Compass).

Create cloudify-cli VM :
* Ubuntu **14.04**

Log into this VM and after, install python packages :
```
sudo apt-get update
sudo apt-get install git python-pip python-dev python-virtualenv -y
```

Create virtual environment :
```
virtualenv cloudify
source cloudify/bin/activate
cd cloudify
```
Install cloudify CLI version 3.4.1 with the PIP command : 
```
pip install cloudify==3.4.1
```

Test if the command cfy exists 
```
cfy
```
If this result appears on console, follow the next part (Deploy cloudify management server)
```
usage: cfy [-h] [--version]  ...

Cloudify's Command Line Interface

optional arguments:
  -h, --help        show this help message and exit
  --version         show version information and exit
```


### Deploy cloudify management server

For more explanation, [see](http://docs.getcloudify.org/3.4.0/manager/bootstrapping/) the cloudify bootstrap documentation !

Log into the host where you installed the **Cloudify CLI** and enter in the virtual environment with source command.

Prepare your directory :
```
cd cloudify
mkdir -p cloudify-manager
cd cloudify-manager
```

Download manager blueprint version 3.4.0.2-telco:
```
git clone -b 3.4.0.2-telco https://github.com/cloudify-cosmo/cloudify-manager-blueprints.git
```

Prepare deployment on OpenStack platform :

```
cfy init
cd cloudify-manager-blueprints/
vim openstack-manager-blueprint.yaml
```

Replace the default `cidr: 172.16.0.0/16` of `management_subnet` in `openstack-manager-blueprint.yaml` with

```
cidr: 13.1.1.0/24
```

**Note: the default `cidr` conflicts with my local envorienment**.

Install required packages for deployment :
```
cfy local create-requirements -o requirements.txt -p openstack-manager-blueprint.yaml
sudo pip install -r requirements.txt
```

The configuration for the cloudify manager deployment is contained in a YAML file. 
A template configuration file exist, you can edit it with the desired values.
```
cp openstack-manager-blueprint-inputs.yaml inputs.yaml
vim inputs.yaml
```

Bellow an example of inputs.yaml file configurations for OpenStack Mitaka. Cloudify manager
server can be bootstrapped on either CentOS 7.x or RHEL 7.x. Here I use the image [CentOS-7-x86_64-GenericCloud.qcow2](https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2).

```yaml
keystone_username: 'admin'
keystone_password: 'console'
keystone_tenant_name: 'admin'
# Run the command: openstack endpoint show keystone
# Choose the publicurl
keystone_url: 'http://192.168.114.222:35357/v2.0'
region: 'RegionOne'          # OpenStack region : look openrc file or by keystone endpoint-list
manager_public_key_name: 'manager-kp'
agent_public_key_name: 'agent-kp'
image_id: '1e27caeb-bf6e-4446-a956-eb695598b59b' # CentOS 7 image ID
flavor_id: '3'                          # m1.medium
external_network_name: 'ext-net'        # external network on Openstack

rabbitmq_username: 'admin'
rabbitmq_password: 'console'

management_subnet_dns_nameservers: ['8.8.8.8', '8.8.4.4']
use_existing_manager_keypair: false
use_existing_agent_keypair: false
manager_server_name: 'cloudify-manager-server'
ssh_user: 'centos'              # SSH user used to connect to the manager
agents_user: 'centos'           # SSH user used to connect to agent VM
```

Launch the deployment of cloudify manager server :
```
 cfy bootstrap --install-plugins -p openstack-manager-blueprint.yaml -i inputs.yaml
```

During the deployment many **logs** appears on console :
```
2017-02-21 06:04:11 CFY <manager> 'execute_operation' workflow execution succeeded
Bootstrap complete
Manager is up at 192.XXX.XXX.XXX
```
Check the proper functioning of the server :
```
cfy status
```
If this result appears on console, your cloudify manager is installed  and operating
```
Retrieving manager services status... [ip=192.XXX.XXX.XXX]

Services:
+--------------------------------+---------+
|            service             |  status |
+--------------------------------+---------+
| InfluxDB                       | running |
| Celery Management              | running |
| Logstash                       | running |
| RabbitMQ                       | running |
| AMQP InfluxDB                  | running |
| Manager Rest-Service           | running |
| Cloudify UI                    | running |
| Webserver                      | running |
| Riemann                        | running |
| Elasticsearch                  | running |
+--------------------------------+---------+
```


## Prepare the environment for installing clearwater

In oder to prevent [netifaces and gcc error](https://groups.google.com/forum/#!topic/cloudify-users/xymyZ362zvQ) for
deploying clearwater, install gcc and python-devel on the cloudify-manager-sever by the following steps:

```
ssh -i ~/.ssh/cloudify-manager-kp.pem centos@ip
sudo yum install python-devel
sudo yum install gcc
```

On the controll node, [modify the default quota per tenant](http://www.sebastien-han.fr/blog/2012/09/19/openstack-play-with-quota/),

```
openstack project list
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=instances --value=50
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=floating_ips --value=50
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=cores --value=50
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=security_groups --value=50
```

because clearwater needs more than 10 VMs.

After, you can deploy clearwater ! See this [documentation](clearwater.md)


## Uninstall

Before uninstall cloudify-manager, you must have uninstall and delete **all deployments** !

Log into the host where you installed the **Cloudify CLI** and enter in the virtual environment with source command.

To uninstall properly cloudify-manager, execute this command :
```
cfy teardown -f 
```
