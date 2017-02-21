#!/bin/bash
##############################################################################
# File Name: "launch_instance.sh"
# Author:    "LiYuenan"
# mail:      "liyuenan@huawei.com"
##############################################################################

# Run this script in a controller node.
set -x
set -e
demo_number=1

# source the admin credentials to gain access to admin-only CLI commands:
source /opt/admin-openrc.sh

# Download the source image:
if [[ ! -e cirros-0.3.4-x86_64-disk.img ]]; then
    wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
fi

# Upload the image to the Image service using the QCOW2 disk format, bare container format:
if [[ ! $(glance image-list | grep cirros) ]]; then
    glance image-create --name "cirros-0.3.4" \
        --file cirros-0.3.4-x86_64-disk.img  \
        --disk-format qcow2 --container-format bare
fi

# List the image
glance image-list

# Add rules to the default security group:
if [[ ! $(nova secgroup-list-rules default | grep icmp) ]]; then
    nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
fi
if [[ ! $(nova secgroup-list-rules default | grep tcp) ]]; then
    nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
fi

# List the rulse
nova secgroup-list-rules default

# Create the net and a subnet on the network:
if [[ ! $(neutron net-list | grep demo-net) ]]; then
    neutron net-create demo-net
fi
if [[ ! $(neutron subnet-list | grep demo-subnet) ]]; then
    neutron subnet-create demo-net 10.10.10.0/24 --name demo-subnet --gateway 10.10.10.1
fi

# List the net and subnet
neutron net-list
neutron subnet-list

# Create the router, add the demo-net network subnet and set a gateway on the ext-net network on the router:
if [[ ! $(neutron router-list | grep demo-router) ]]; then
    neutron router-create demo-router
    neutron router-interface-add demo-router demo-subnet
    neutron router-gateway-set demo-router ext-net
fi

# List the router
neutron router-list

# Create m1.nano flavor
if [[ ! $(openstack flavor list | grep m1.nano) ]]; then
    openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
fi

# Launch the instance:
for i in $(seq 1 $demo_number)
do
    if [[ ! $(nova list | grep "demo$i") ]]; then
        nova boot \
            --flavor m1.nano \
            --image cirros-0.3.4 \
            --nic net-id=$(neutron net-list | grep demo-net | awk '{print $2}') \
            --security-group default \
            "demo$i"
        sleep 10

        # Create a floating IP address and associate it with the instance:
        floating_ip=$(neutron floatingip-create ext-net \
                    | grep floating_ip_address | awk '{print $4}')
        nova floating-ip-associate "demo$i" $floating_ip
    fi
done

set +x
set +e

# List the instance
nova list

# Login the instance
echo "+--------------------------------------+"
echo "| Login the instance                   |"
echo "+--------------------------------------+"
for i in $(seq 1 $demo_number)
do
    floating_ip=$(nova list | grep "demo$i" | awk '{print $13}')
    echo "| demo$i: ssh cirros@$floating_ip    |"
done
echo "| NOTE: DEFAULT PASSWORD is cubswin:)  |"
echo "+--------------------------------------+"
