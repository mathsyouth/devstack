# Clearwater

## Clearwater vIMS deployment on OpenStack Mitaka

To deploy the Clearwater vIMS, you must have previously installed the **Cloudify** orchestrator on OpenStack (see [this doc](opnfv-cloudify-clearwater/cloudify.md)).


### Upload Clearwater blueprint

Log into `cloudify-cli` (the host where you installed the Cloudify CLI) and enter in the virtual environment with source command.

1. Download blueprint using git <br>

   ```shell
   cd ~/cloudify/cloudify-manager/
   mkdir blueprints
   cd blueprints
   git clone https://github.com/cloudify-examples/clearwater-nfv-blueprint.git
   ```
1. Upload blueprint on the Cloudify orchestrator <br>

   ```shell
   cd clearwater-nfv-blueprint
   cfy blueprints upload -b clearwater -p openstack-blueprint.yaml
   ```


### Create and launch deployment

1. To create and launch the deployment you will have to pass the parameters of your Openstack environment. For that, must be specified the deployment **inputs parameters**. Create an `inputs.yaml` in the folder `inputs` to fit with your OpenStack cloud platform <br>

   ```
   vim inputs/inputs.yaml
   ```
   Bellow is an example of `input.yaml` file configurations for my Openstack Mitaka platform <br>

   ```
   cloudify_agent: 'ubuntu'
   server_image: '4806095a-0120-428a-ab7f-98c16ad30678' # Ubuntu 14.04 Server
   server_flavor_name: 'm1.small'  # 1 CPU 2 GB RAM
   subnet_cidr: '0.0.0.0/0'
   openstack_external_network_name: 'ext-net'
   use_existing_example_openstack_key: false
   example_openstack_key: clearwater-kp
   example_openstack_key_file: ~/.ssh/clearwater-kp.pem
   openstack_network_name: 'cloudify-management-network'
   keystone_username: 'admin'
   keystone_password: 'console'
   keystone_tenant_name: 'admin'
   keystone_url: 'http://192.168.37.222:5000/v2.0'
   region: 'RegionOne'
   ```
   You can also pass the parameters from the Cloud Manager Server GUI—Create Deployment using Blueprints.
1. Once the input file is completed, you must create the deployment on orchestrator <br>

   ```
   cfy deployments create -b clearwater -d clearwater --inputs inputs/inputs.yaml
   ```
1. Launch Clearwater deployment <br>

   ```
   cfy executions start -w install -d clearwater --timeout=3600
   ```
   If this result appears on console, installaton of your Clearwater is finished <br>

   ```
   2017-02-24T08:37:37 CFY <clearwater> 'install' workflow execution succeeded
   Finished executing workflow install on deployment clearwater
   * Run 'cfy events list --include-logs --execution-id cf1cde8c-c12d-4605-9280-cdc61404bee5' to retrieve the execution's events/logs
   ```

**Note:** During the deployment, please confirm if the ‘default security’ of the OpenStack is added on VM instances. Pass all UDP, TCP and ICMP traffic during Clearwater installation. The default security group can be deleted from all instances once the application is installed successfully.


## Make a phone call with Jitsi

There are many clients that you can use with SIP, but these instructions are for the Jitsi client.

1. Download the [Jitsi client](https://jitsi.org/Main/Download).
2. Get the IP of Ellis, the IP of Bono, and the signup_code from `cfy deployments outputs -d clearwater`.
3. Open the IP of Ellis in a browser and signup for an account using the signup_code.
4. When you sign up you should see the Clearwater dashboard with your SIP ID and password. Save them.
5. Open the preferences of the Jitsu Client.
6. Fill out the Account section with your SIP ID (including the '@example.com') and password from step 4.
7. Open the Connection tab. Put the IP of Bono from step 2 in the proxy field. Use port 5060. Preferred Transport TCP.
8. Repeat these steps on another computer.

If everthing worked, you should be able to make phone calls between the two computers.


## Test

### [Clearwater Live Tests](https://clearwater.readthedocs.io/en/latest/Running_the_live_tests.html)

The following live tests can be run over a Clearwater deployment to confirm that the high level function is working for the vIMS.

1. On the developer node (e.g. the `cloudify-cli` host where you installed the Cloudify CLI), install Ruby version 1.9.3 and its dependencies <br>

   ```shell
   sudo apt-get install build-essential git --yes
   curl -L https://get.rvm.io | bash -s stable
   source ~/.rvm/scripts/rvm
   rvm autolibs enable
   rvm install 1.9.3
   rvm use 1.9.3
   ```
1. Run the following to download and install the Clearwater test suite <br>

   ```shell
   git clone -b stable --recursive git@github.com:Metaswitch/clearwater-live-test.git
   cd clearwater-live-test
   bundle install
   ```
   Make sure that you have an SSH key - if not, see the [GitHub instructions](https://help.github.com/articles/generating-ssh-keys) for how to create one.
1. To run the subset of the tests that don’t require PSTN interconnect to be configured, simply run <br>

   ```shell
   rake test[<domain>] SIGNUP_CODE=<code> PROXY=<Bono domain> ELLIS=<Ellis domain>
   rake test[default] SIGNUP_CODE=secret PROXY=192.168.37.141 ELLIS=192.168.37.140
   ```
   where domain: default, code: secret, PROXY: 192.168.37.141, ELLIS: 192.168.37.140
1. The results will be printed on-screen <br>

   ```
   Basic Call - Mainline (TCP) - (6505550190, 6505550546) Passed
   Basic Call - SDP (TCP) - (6505550294, 6505550068) Passed
   Basic Call - Tel URIs (TCP) - (6505550335, 6505550756) Passed
   Basic Call - Unknown number (TCP) - (6505550596, 6505550179) Passed
   Basic Call - Rejected by remote endpoint (TCP) - (6505550258, 6505550210) Passed
   Basic Call - Messages - Pager model (TCP) - (6505550023, 6505550894) Passed
   Basic Call - Pracks (TCP) - (6505550248, 6505550993) Passed
   Basic Registration (TCP) - (6505550269) Passed
   Multiple Identities (TCP) - (6505550261, 6505550347) Passed
   Call Barring - Outbound Rejection (TCP) - (6505550007, 6505550410) Passed
   Call Barring - Allow non-international call (TCP) - Skipped (No PSTN support)
      - Call with PSTN=true to run test
   ...
   ...
   ...
   SUBSCRIBE - reg-event (TCP) - (6505550685) Passed
   SUBSCRIBE - reg-event with a GRUU (TCP) - (6505550845) Passed
   SUBSCRIBE - Subscription timeout (TCP) - (6505550257) Passed
   SUBSCRIBE - Registration timeout (TCP) - (6505550912, 6505550033) Passed
   0 failures out of 88 tests run
   39 tests skipped
   ```


### Use OPNFV/Functest container

It's the same test but the installation of all dependencies was already done in this container. In addition, this test provide a `json` file of all test result.

You can run Functest container in your Cloudify CLI VM. To do that, you must install docker into this VM

```
curl -sSL https://get.docker.com/ | sh
```

After that, you can download OPNFV/Functest container image

```
docker pull opnfv/functest
```

Then you can run the container

```
docker run --dns=<BIND_PUBLIC_IP> -it opnfv/functest /bin/bash
```

Next you can launch the signaling testing of your deployment

```
cd ~/repos/vims-test
source /etc/profile.d/rvm.sh
rake test[<YOUR_PUBLIC_DOMAIN_NAME>] SIGNUP_CODE=secret
```


## Scaling

### Manually

With [built-in workflow](http://getcloudify.org/guide/3.2/workflows-built-in.html) on Cloudify you can manually **scale** your Clearwater deployment.

Before **scale** your deployment, create the input file

```
vim scale.yaml
```

with the following parameters

```
node_id: sprout
delta: 1
scale_compute: true
```

These parameters will create one Sprout VM and add it on Sprout cluster.

Then launch **scale** with this command

```
cfy executions start -w scale -d clearwater -p scale.yaml
```

**Warning !** : For the moment, the Bono scale doesn't work correctly because Cloudify don't support "one_to_one" relationships. See the [post](https://groups.google.com/d/msg/cloudify-users/TPqoGZYHEYs/tSrfptDUyKwJ) on Cloudify forum!


### Auto-Scale

```
 groups:
  clearwater_hosts:
    members: [sprout_host]
    policies:
      mem_scale_policy:
        type: cloudify.policies.types.threshold
        properties:
          service: cpu.total.user
          threshold: 85
        triggers:
          scale_trigger:
            type: cloudify.policies.triggers.execute_workflow
            parameters:
              workflow: scale
              workflow_parameters:
                node_id: sprout
                delta: 1
```


## Uninstall Clearwater vIMS

1. Log into `cloudify-cli` (the host where you installed the Cloudify CLI) and enter in the virtual environment with source command <br>

   ```shell
   source  cloudify/bin/activate
   ```
1. To uninstall properly Clearwater deployment, execute this command <br>

   ```shell
   cfy executions start -w uninstall -d clearwater
   ```


## Reference

1. [Installation Runbook for vIMS (Project Clearwater)](https://950b04d5967e797d455c-4b2d2a5b1eb18dc3d5e79a7b856f687e.ssl.cf5.rackcdn.com/application%20validation/vIMS_Clearwater_runbook_v1.0.pdf)
1. [opnfv cloudify clearwater](https://github.com/Orange-OpenSource/opnfv-cloudify-clearwater/blob/master/docs/clearwater.md)
1. [Clearwater IMS All-in-one环境搭建指导书](http://xunknown.lofter.com/post/2734f8_568f48b)
1. [clearwater nfv blueprint](https://github.com/cloudify-examples/clearwater-nfv-blueprint)