# devstack
Use Devstack Liberty to install stable OpenStack Liberty with Neutron, Heat, Cinder, Swift and Ceilometer (see [devstack developer guide](http://docs.openstack.org/developer/devstack/))

## What devstack does
**Warning: devstack will massively modify your OS. Don't run on a laptop.**
* Installing all prerequirement software via **packages** or **pip**
* Installing all OpenStack software via **git** to a specified master
* Configuring and installing working **database schema**
* Configuring hypervior, storage backends, networks
* Creating **service ids** and **service catalog** entries to connect all components
* Starting all OpenStack services under **screen**
* Creating Apache configuration for web dashboard available at 127.0.0.1
* Creats working **Tempest** config in /opt/stack/tempest

## Install
1. Install Ubuntu 14.04 (Trusty)
2. Add stack user and give the user sudo privileges
  * adduser stack
  * apt-get install sudo -y
  * echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
3. Logout and login as that user
4. Download devstack liberty
  * sudo apt-get install git -y
  * git clone https://git.openstack.org/openstack-dev/devstack -b stable/liberty
  * cd devstack
5. Create local.conf in devstack directory (see the local.conf file)
6. Run devstack <br>
  ./stack.sh
7. Access the dashboard <br>
  http://localhost/dashboard/
8. Run test examples <br>
  ./devstack/exercise.sh

## Example 
[Main reference: HOT guide](http://docs.openstack.org/developer/heat/template_guide/hot_guide.html)<br>

1. The following example is a simple Heat template to deploy a single virtual system that is based on the cirros-0.3.4-x86_64-uec image:<br>

  ```yaml
  heat_template_version: 2015-04-30 

  description: Simple template to deploy a single compute instance

  resources:
    my_instance:
      type: OS::Nova::Server
      properties:
        image: cirros-0.3.4-x86_64-uec
        flavor: m1.small
  ```
2. The following example is a simple Heat template to deploy a stack with two vm instances, by using parameters:<br>
 
	```yaml
	heat_template_version: 2015-04-30 

	description: Simple template to deploy a stack with two vm instances

	parameters:
	  image_name_1: 
	    type: string 
	    label: Image Name 
	    description: Please specify image name for instance1 
	    default: Ubuntu-14.04
	  image_name_2: 
	    type: string 
	    label: Image Name 
	    description: Please specify image name for instance2 
	    default: Ubuntu-14.04
	  network_id:
	    type: string
	    label: Network ID
	    description: The network to be used for compute instance

  resources: 
    my_instance1: 
      type: OS::Nova::Server 
      properties: 
        image: { get_param: image_name_1 } 
        flavor: m1.small 
        networks:
          - network : { get_param : network_id }
    my_instance2: 
      type: OS::Nova::Server 
      properties: 
        image: { get_param: image_name_2 } 
        flavor: m1.small
        networks:
          - network : { get_param : network_id }
  ```
