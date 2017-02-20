# Cloud images in Glance

Cloud images have no password. It's reccomended to login to the instance through SSH (--key-name). Otherwise, it's possible to inject a cloud-config metadata file through the nova switch `--user-data ./my_file`, in order to set a password. `my_file` would look like (note that the first line is not a comment, but it's required!).

```
#cloud-config 
password: centos 
chpasswd: { expire: False }
```

Here some cloud-config examples: 
http://cloudinit.readthedocs.org/en/latest/topics/examples.html


## Ubuntu 14.04

1. Download the image <br>

   ```shell
   wget https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img
   ```
1. Put the Image in Glance <br>

   ```shell
   glance image-create --name 'Ubuntu-14.04' --visibility public --disk-format=qcow2 \
                        --container-format=bare --file=trusty-server-cloudimg-amd64-disk1.img
   ```
1. Create a key pair for the agents <br>

   ```shell
   nova keypair-add Ubuntu > Ubuntu.pem
   ```
   Or, if you have access to the Ubuntu repository you may import the Ubuntu key <br>
   
   ```shell
   nova keypair-add --pub_key ubuntu_rsa.pub Ubuntu
   ```
1. Create the Ubuntu VM <br>

   ```shell
   NET_ID=`neutron net-list | grep 'demo-net ' | awk '{print $2}'`
   ```
   **Note: If we replace 'demo-net' with 'ext-net', the newly created VM is not easily accessed.** <br>
   
   ```shell
   nova boot --image 'Ubuntu-14.04' --flavor m1.small --nic net-id=$NET_ID \
              --key-name=Ubuntu 'Ubuntu'
   ```
   **Note: There is a Error if we replace the name 'Ubuntu' with 'Ubuntu-14.04' or 'cirros-0.3.4'.
   Maybe there is a bug or constraint for the name of a server in Nova Mitaka release.**
1. Create a floating IP address and associate it with the instance <br>

   ```shell
   floating_ip=$(neutron floatingip-create ext-net \
                | grep floating_ip_address | awk '{print $4}')
   nova floating-ip-associate "Ubuntu" $floating_ip
   ```
1. Start a SSH connection with a command like the one below (default username depends on the image, 
   on Ubuntu the username is simply 'ubuntu'): <br>
   
   ```shell
   ssh -i Ubuntu.pem ubuntu@192.168.114.196
   ```
1. Make VM access to the Internet <br>

   ```shell
   sudo vim /etc/resolv.conf
   ```
   and modify the nameserver line as `nameserver 8.8.8.8`. Then <br>
 
   ```shell
   ping google.com
   ping baidu.com
   ```


## CentOS-7

1. Download the image <br>

   ```shell
   wget https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1503.qcow2
   ```
1. Put the Image in Glance <br>

   ```shell
   glance image-create --name 'CentOS-7-1503' --visibility public --disk-format=qcow2 \
                        --container-format=bare --file=CentOS-7-x86_64-GenericCloud-1503.qcow2
   ```
