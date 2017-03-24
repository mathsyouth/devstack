#!/bin/bash

# Run this script in a controller node.
set -x

# source the admin credentials to gain access to admin-only CLI commands:
source /opt/admin-openrc.sh

# Download the source image:
if [[ ! -e trusty-server-cloudimg-amd64-disk1.img ]]; then
    wget https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
fi

# Upload the image to the Image service using the QCOW2 disk format, bare container format:
if [[ ! $(glance image-list | grep Ubuntu) ]]; then
    glance image-create --name 'Ubuntu-14.04' --visibility public \
        --disk-format=qcow2  --container-format=bare \
        --file=trusty-server-cloudimg-amd64-disk1.img
fi

# Create the net and a subnet on the network:
if [[ ! $(neutron net-list | grep cloudify-net) ]]; then
    neutron net-create cloudify-net
fi

if [[ ! $(neutron subnet-list | grep cloudify-subnet) ]]; then
    neutron subnet-create cloudify-net 10.10.10.0/24 \
    --name cloudify-subnet --gateway 10.10.10.1 \
        --dns_nameservers list=true 8.8.8.8
fi

# List the net and subnet
neutron net-list
neutron subnet-list

# Create the router, add the cloudify-net network subnet and set a gateway
# on the ext-net network on the router:
if [[ ! $(neutron router-list | grep cloudify-router) ]]; then
    neutron router-create cloudify-router
    neutron router-interface-add cloudify-router cloudify-subnet
    neutron router-gateway-set cloudify-router ext-net
fi

# List the router
neutron router-list

local default_secgroup_id=$(nova secgroup-list | grep "Default security group" | awk '{print $2}')

# Add rules to the default security group:
if [[ ! $(neutron security-group-rule-list | grep default | grep "icmp") ]]; then
    neutron security-group-rule-create --direction ingress --protocol icmp \
                            --remote-ip-prefix 0.0.0.0/0 $default_secgroup_id
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "icmp") ]]; then
    neutron security-group-rule-create --direction egress --protocol icmp \
                            --remote-ip-prefix 0.0.0.0/0 $default_secgroup_id
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "tcp") ]]; then
    neutron security-group-rule-create --direction ingress --protocol tcp \
                            --remote-ip-prefix 0.0.0.0/0 $default_secgroup_id
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "tcp") ]]; then
    neutron security-group-rule-create --direction egress --protocol tcp \
                            --remote-ip-prefix 0.0.0.0/0 $default_secgroup_id
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "udp") ]]; then
    neutron security-group-rule-create --direction ingress --protocol udp \
                            --remote-ip-prefix 0.0.0.0/0 $default_secgroup_id
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "udp") ]]; then
    neutron security-group-rule-create --direction egress --protocol udp \
                        --remote-ip-prefix 0.0.0.0/0 $default_secgroup_id
fi

# List the rulse
nova secgroup-list-rules default

echo -e 'n\n'|ssh-keygen -q -t rsa -N "" -f /root/.ssh/id_rsa 1>/dev/null

openstack keypair delete cloudify-key | true
openstack keypair create --public-key /root/.ssh/id_rsa.pub cloudify-key

local NET_ID=$(neutron net-list | grep cloudify-net | awk '{print $2}')

# Launch the instance:

if [[ ! $(nova list | grep cloudify-cli) ]]; then
    nova boot --image 'Ubuntu-14.04' --flavor m1.small --nic net-id=$NET_ID \
              --key-name=cloudify-key --security-group default 'cloudify-cli'
    if [ $? -ne 0 ]; then
        log_error "boot cloudify-cli fail"
        exit 1
    fi
fi

local count=300
set +x
while
    local state=$(nova list | grep cloudify-cli | awk '{print $6}')
    if [[ $state == "ERROR" || $count == 0 ]]; then
        log_error "launch cloudify-cli error"
        exit 1
    fi
    let count-=1
    sleep 2
    [[ $state != "ACTIVE" ]]
do :;done
set -x

# Create a floating IP address and associate it with the instance:
if [ ! $(nova list | grep cloudify-cli | awk '{print $14}') ]; then
    cloudify_cli_ip=$(neutron floatingip-create ext-net | grep floating_ip_address | awk '{print $4}')
    nova floating-ip-associate cloudify-cli $cloudify_cli_ip
else
    cloudify_cli_ip=$(nova list | grep cloudify-cli | awk '{print $13}')
fi

set +x

# List the instances
nova list
