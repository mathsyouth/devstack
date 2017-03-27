# Cloudify

## Introduction

See more about [Cloudify orchestrator](http://getcloudify.org/cloud_orchestration_cloud_automation.html).


## Cloudify installation steps

### Cloudify CLI setup

Cloudify CLI can be used to create Cloudify Manager Server on OpenStack platform. To install Cloudify CLI you have two choice:

* Follow [cloudify documentation](http://docs.getcloudify.org/3.4.0/intro/installation/) to install Cloudify CLI on Windows, Linux or OSX and after read the next part (Cloudify Manager Server deployment);
* Provide Cloudify CLI VM on OpenStack platform (My environment is OpenStack Mitaka installed by Compass).

The following steps will guide you for installation of Cloudify CLI:

1. Create Cloudify CLI VM (Ubuntu **14.04** image) named `cloudify-cli`. You can run [this script](../../launch_vm.sh) to create a VM. You could also refer to [this doc](../../ubuntu_centos.md) to manually create a VM.
1. Log into `cloudify-cli` and then install python packages

   ```shell
   sudo apt-get update
   sudo apt-get install git python-pip python-dev python-virtualenv -y
   ```
1. Create virtual environment

   ```shell
   virtualenv cloudify && source cloudify/bin/activate && cd cloudify
   ```
1. Install Cloudify CLI version 3.4.1 with the PIP command <br>

   ```shell
   pip install cloudify==3.4.1
   ```
1. Test if the command `cfy` exists <br>

   ```
   cfy
   ```
   If this result appears on console, follow the next part (deploy Cloudify Management Server) <br>

   ```
   usage: cfy [-h] [--version]  ...

   Cloudify's Command Line Interface

   optional arguments:
     -h, --help        show this help message and exit
     --version         show version information and exit
   ```


### Deploy Cloudify Management Server

For more explanation, [see](http://docs.getcloudify.org/3.4.0/manager/bootstrapping/) the cloudify bootstrap documentation!

1. Log into `cloudify-cli` (the host where you installed the Cloudify CLI) and enter in the virtual environment with source command <br>

   ```shell
   source  cloudify/bin/activate
   ```
1. Prepare your directory <br>

   ```shell
   cd cloudify
   mkdir -p cloudify-manager && cd cloudify-manager
   ```
1. Download manager blueprint version 3.4.0.2-telco <br>

   ```shell
   git clone -b 3.4.0.2-telco https://github.com/cloudify-cosmo/cloudify-manager-blueprints.git
   ```
1. Prepare deployment on OpenStack Mitaka platform <br>

   ```shell
   cfy init && cd cloudify-manager-blueprints/
   vim openstack-manager-blueprint.yaml
   ```
   Replace the default `cidr: 172.16.0.0/16` of `management_subnet` in `openstack-manager-blueprint.yaml` with

   ```
   cidr: 13.1.1.0/24
   ```
   **Note: the default `cidr` conflicts with my local envorienment**.
1. Install required packages for deployment <br>

   ``` shell
   cfy local create-requirements -o requirements.txt -p openstack-manager-blueprint.yaml
   sudo pip install -r requirements.txt
   ```
1. The configuration for the Cloudify Manager Server deployment is contained in a YAML file. A template configuration file exists. You need to edit the parameter according to your Openstack Mitaka environment. <br>

   ```
   cp openstack-manager-blueprint-inputs.yaml inputs.yaml
   vim inputs.yaml
   ```
   Bellow is an example of `inputs.yaml` file configurations for OpenStack Mitaka. Cloudify Manager Server can be bootstrapped on either CentOS 7.x or RHEL 7.x. Here I use the image [CentOS-7-x86_64-GenericCloud.qcow2](https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2).

   ```
   keystone_username: 'admin'
   keystone_password: 'console'
   keystone_tenant_name: 'admin'
   # Run the command: openstack endpoint show keystone
   # Choose the publicurl
   keystone_url: 'http://192.168.37.222:5000/v2.0'
   # OpenStack region : look openrc file or by keystone endpoint-list
   region: 'RegionOne'
   manager_public_key_name: 'manager-kp'
   agent_public_key_name: 'agent-kp'
   image_id: '9d5f1751-3f3f-4f92-92db-7559c7ee6d97' # CentOS 7 image ID
   flavor_id: '4'                          # m1.large
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
1. Launch the deployment of Cloudify Manager Server <br>

   ```shell
   cfy bootstrap --install-plugins -p openstack-manager-blueprint.yaml -i inputs.yaml
   ```
   If this result appears on console, the deployment of Cloudify Manager Server is finished <br>

   ```
   2017-02-21 06:04:11 CFY <manager> 'execute_operation' workflow execution succeeded
   Bootstrap complete
   Manager is up at 192.XXX.XXX.XXX
   ```
1. Check the proper functioning of the server <br>

   ```
   cfy status
   ```
   If this result appears on console, your Cloudify Manager Server is installed and operating <br>

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
1. Access the Cloudify Manager Server GUI using the associate IP address (`192.XXX.XXX.XXX`) of the `cloudify-manager-sever` VM on Openstack Mitaka.


## Prepare the environment for installing Clearwater

In oder to prevent [netifaces and gcc error](https://groups.google.com/forum/#!topic/cloudify-users/xymyZ362zvQ) for
deploying Clearwater, install `gcc` and `python-devel` on the `cloudify-manager-sever` by the following steps

```shell
ssh -i ~/.ssh/cloudify-manager-kp.pem centos@ip
sudo yum install python-devel
sudo yum install gcc
```

On the controll node, [modify the default quota per tenant](http://www.sebastien-han.fr/blog/2012/09/19/openstack-play-with-quota/),

```shell
openstack project list
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=instances --value=50
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=floating_ips --value=50
neutron quota-update --tenant-id  1359c571540449268c8b5e789b7ec328 --floatingip 50
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=cores --value=50
sudo nova-manage project quota --project=1359c571540449268c8b5e789b7ec328 --key=security_groups --value=50
```

because Clearwater needs more than 7 VMs.

After, you can deploy Clearwater! See [this documentation](clearwater.md).


## Uninstall Cloudify Manager Server

Before uninstall `cloudify-manager-server`, you must have uninstall and delete **all deployments**!

1. Log into `cloudify-cli` (the host where you installed the Cloudify CLI) and enter in the virtual environment with source command <br>

   ```shell
   source  cloudify/bin/activate
   ```
1. To uninstall properly `cloudify-manager-server`, execute this command <br>

   ```shell
   cfy teardown -f
   ```
