#!/bin/bash
# clear the cloudify environment

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

neutron security-group-list
nova list

set +x
