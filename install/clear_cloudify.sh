#!/bin/bash
# clear the cloudify environment

# nova keypair-delete agent-kp
# nova keypair-delete manager-kp

instances=`nova list | grep 'server_clearwater-test_' | awk '{print $4}'`
for instance in $instances
do  
    echo "Delete vIMS instance ${instance}"
    nova delete $instance
done

clearwatersgs="internal_sip ralf sprout base bono bind homestead ellis homer"
for service in $clearwatersgs
do 
    echo "Delete security group clearwater-sg_${service}"
    neutron security-group-delete clearwater-sg_${service}
done


neutron security-group-list
nova list
