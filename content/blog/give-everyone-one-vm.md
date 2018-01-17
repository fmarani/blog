+++
date = "2014-02-11 22:45:08+00:00"
title = "Give everyone one (public) VM"
tags = ["ansible", "devops"]
+++

At TrialReach we want to be always able to deploy clean versions of our code online. This allows us to show our work more quickly internally (and externally) and get feedback from people as early as possible, without having to wait release dates. This also give us the opportunity to test more frequently our server provisioning procedures, and having the ability to push something live anytime is a really empowering feeling.

We started using Ansible as our main DevOps tool, which recently we extended to also take care of DigitalOcean VM creation. DigitalOcean has very easy APIs and is well integrated with Ansible. While we use EC2 for production/staging environments, for these throw-away environments DigitalOcean offer a good price/performance trade-off.

Enough said, this is a vm creation snippet:

```yaml+jinja
---
- name: digitalocean creation
  hosts: all
  connection: local
  vars:
    - api_key: XXXXX
    - client_id: XXXX
  tasks: 
    - name: gather user info
      command: whoami
      register: user
    - name: gather ssh pub key 
      command: cat {{ ansible_env.HOME }}/.ssh/id_rsa.pub 
      register: ssh_pub_key
    - name: generate id for this machine
      shell: hostname | cksum | awk '{print $1;}'
      register: machineid
    - name: copy your ssh pub key on digital ocean
      digital_ocean: >
          state=present
          command=ssh
          name={{ machineid.stdout }}-{{ user.stdout }}
          client_id={{ client_id }}
          api_key={{ api_key }}
          ssh_pub_key='{{ ssh_pub_key.stdout }}'
      register: my_ssh
    - name: creating new digital ocean vm
      digital_ocean: >
          state=present
          command=droplet
          name={{ machineid.stdout }}-{{ user.stdout }}
          ssh_key_ids={{ my_ssh.ssh_key.id }}
          unique_name=yes
          client_id={{ client_id }}
          api_key={{ api_key }}
          size_id=66
          region_id=1
          image_id=1505447
          wait_timeout=500
      register: my_droplet
    - name: writing local2cloud inventory with new vm ip
      shell: cat local2cloud | sed 's/CHANGE/{{ my_droplet.droplet.ip_address }}/' > local2cloud.templated
```

This script does a bunch of things, create ssh key and vm, but also makes sure people create only one VM. That is what we need for now. This snippet takes a inventory template (local2cloud) and fills it with the new droplet's IP address, so it can used to provision the new server.

To launch this script, make sure right variables are set, and make sure you have dopy installed in your virtualenv, then run:

```
ansible-playbook -i 'localhost,' -e ansible_python_interpreter=`which python` create_vm.yml
```

-e makes sure uses python from your virtualenv, -i forces not to load an inventory file but use localhost directly. This last option is a bit [hacky] [1], hope in the future there are better ways to do this.

  [1]: https://groups.google.com/forum/#!topic/Ansible-project/RuntoPUvqHM  "Ansible mailing-list"
