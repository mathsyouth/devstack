#!/bin/bash
# clear the cloudify environment

# nova keypair-delete agent-kp
# nova keypair-delete manager-kp

clearwatersgs="internal_sip ralf sprout base bono bind homestead ellis homer"

for service in $clearwatersgs
do
    neutron security-group-delete clearwater-sg_${service}
done

instances=`nova list | grep 'server_clearwater-test_' | awk '{print $4}'`
for instance in $instances
do
    nova delete $instance
done

neutron security-group-list
nova list
