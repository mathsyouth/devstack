#!/bin/bash
# clear the clearwater nfv environment

# nova keypair-delete agent-kp
# nova keypair-delete manager-kp

set -x

nova keypair-delete clearwater-kp

instances=`nova list | grep 'server_clearwater_' | awk '{print $4}'`
for instance in $instances
do
    # Delete vIMS instance
    nova delete $instance
done

clearwatersgs="Bono DNS Homer Homestead Ralf Sprout Ellis"
for service in $clearwatersgs
do
    neutron security-group-delete "${service} VM Security Group"
    neutron security-group-delete "${service} to Others VM Security Group"
done

neutron security-group-delete "All Clearwater Nodes External"
neutron security-group-delete "All Clearwater Nodes Internal"


sleep 5
openstack server list
sleep 10
openstack security group list

set +x
