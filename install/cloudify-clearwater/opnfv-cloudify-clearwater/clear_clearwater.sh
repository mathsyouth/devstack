#!/bin/bash
# clear the opnfv clearwater environment

# nova keypair-delete agent-kp
# nova keypair-delete manager-kp

set -x

instances=`nova list | grep 'server_clearwater-test_' | awk '{print $4}'`
for instance in $instances
do
    # Delete vIMS instance
    nova delete $instance
done

clearwatersgs="internal_sip ralf sprout base bono bind homestead ellis homer"
for service in $clearwatersgs
do
    neutron security-group-delete clearwater-sg_${service}
done

sleep 5
openstack server list
sleep 10
openstack security group list

set +x
