# Environment assumptions

* Ansible 2.7+ installed
* Vault password is set for the environment being used
* The inventory is complete and correct
* Subject hosts are either Fedora 29+ or Centos 7+.
* Subject hosts are fully partitioned with plenty of free space
* Subject host's hostname and FQDN are configured and correct
* Subject hosts are accessible as an admin user by password via ssh

# Runtime assumptions

* Ansible is executed from the `ansible` directory
* The command used resembles `python3 /usr/bin/ansible-playbook --vault-password-file=$FILEPATH -i inventory/$ENV_NAME main.yml`
