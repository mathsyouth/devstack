#!/bin/bash

# Run this script in a controller node.
set -x
SOURCE_IMA=trusty-server-cloudimg-amd64-disk1.img
IMA_NAME=Ubuntu-14.04
NET_NAME=cloudify-net
SUBNET_NAME=cloudify-subnet
CIDR=10.10.10.0/24
GATEWAY=10.10.10.1
ROUTER_NAME=cloudify-router
PUB_NET=ext-net
KEY_NAME=cloudify-key
VM_NAME=cloudify-cli
FLAVOR_NAME=m1.small


# Source the admin credentials to gain access to admin-only CLI commands.
source /opt/admin-openrc.sh

# Download the source image.
if [[ ! -e $SOURCE_IMA ]]; then
    wget https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
fi

# Upload the image to the Image service using the QCOW2 disk format,
# bare container format.
if [[ ! $(glance image-list | grep $IMA_NAME) ]]; then
    glance image-create --name $IMA_NAME --visibility public \
        --disk-format=qcow2  --container-format=bare \
        --file=$SOURCE_IMA
fi

# Create the net and a subnet on the network.
if [[ ! $(neutron net-list | grep $NET_NAME) ]]; then
    neutron net-create $NET_NAME
fi

if [[ ! $(neutron subnet-list | grep $SUBNET_NAME) ]]; then
    neutron subnet-create $NET_NAME $CIDR \
    --name $SUBNET_NAME --gateway $GATEWAY \
        --dns_nameservers list=true 8.8.8.8
fi

# List the net and subnet.
neutron net-list
neutron subnet-list

# Create the router, add the  network and subnet and set a gateway
# on the public network on the router.
if [[ ! $(neutron router-list | grep $ROUTER_NAME) ]]; then
    neutron router-create $ROUTER_NAME
    neutron router-interface-add $ROUTER_NAME $SUBNET_NAME
    neutron router-gateway-set $ROUTER_NAME $PUB_NET
fi

# List the router.
neutron router-list

DEFAULT_SECGROUP_ID=$(nova secgroup-list | grep "Default security group" | awk '{print $2}')

# Add rules to the default security group.
if [[ ! $(neutron security-group-rule-list | grep default | grep "icmp") ]]; then
    neutron security-group-rule-create --direction ingress --protocol icmp \
                            --remote-ip-prefix 0.0.0.0/0 $DEFAULT_SECGROUP_ID
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "icmp") ]]; then
    neutron security-group-rule-create --direction egress --protocol icmp \
                            --remote-ip-prefix 0.0.0.0/0 $DEFAULT_SECGROUP_ID
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "tcp") ]]; then
    neutron security-group-rule-create --direction ingress --protocol tcp \
                            --remote-ip-prefix 0.0.0.0/0 $DEFAULT_SECGROUP_ID
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "tcp") ]]; then
    neutron security-group-rule-create --direction egress --protocol tcp \
                            --remote-ip-prefix 0.0.0.0/0 $DEFAULT_SECGROUP_ID
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "udp") ]]; then
    neutron security-group-rule-create --direction ingress --protocol udp \
                            --remote-ip-prefix 0.0.0.0/0 $DEFAULT_SECGROUP_ID
fi

if [[ ! $(neutron security-group-rule-list | grep default | grep "udp") ]]; then
    neutron security-group-rule-create --direction egress --protocol udp \
                        --remote-ip-prefix 0.0.0.0/0 $DEFAULT_SECGROUP_ID
fi

# List the rules.
nova secgroup-list-rules default

echo -e 'n\n'|ssh-keygen -q -t rsa -N "" -f /root/.ssh/id_rsa 1>/dev/null

openstack keypair delete $KEY_NAME | true
openstack keypair create --public-key /root/.ssh/id_rsa.pub $KEY_NAME

NET_ID=$(neutron net-list | grep $NET_NAME | awk '{print $2}')

# Launch the instance.
if [[ ! $(nova list | grep $VM_NAME) ]]; then
    nova boot --image $IMA_NAME --flavor $FLAVOR_NAME --nic net-id=$NET_ID \
              --key-name=$KEY_NAME --security-group default $VM_NAME
    if [ $? -ne 0 ]; then
        log_error "boot $VM_NAME fail"
        exit 1
    fi
fi

COUNT=300
set +x
while
    STATE=$(nova list | grep $VM_NAME | awk '{print $6}')
    if [[ $STATE == "ERROR" || $COUNT == 0 ]]; then
        log_error "launch $VM_NAME error"
        exit 1
    fi
    let COUNT-=1
    sleep 2
    [[ $STATE != "ACTIVE" ]]
do :;done
set -x

# Create a floating IP address and associate it with the instance.
if [ ! $(nova list | grep $VM_NAME | awk '{print $14}') ]; then
    VM_IP=$(neutron floatingip-create $PUB_NET | grep floating_ip_address | awk '{print $4}')
    nova floating-ip-associate $VM_NAME $VM_IP
else
    VM_IP=$(nova list | grep $VM_NAME | awk '{print $13}')
fi

set +x

# List the instances
nova list
