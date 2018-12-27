### Separate Inventory directories per environment

Ref: https://www.digitalocean.com/community/tutorials/how-to-manage-multistage-environments-with-ansible#ansible-recommended-strategy-using-groups-and-multiple-inventories

## Variables

* Each environment has specific variables under `$ENV_NAME/group_vars/all/vars.yml`
* Shared variables (`common_vars.yml`) are maintained as symlinks from each environment's `group_vars`
* It is assumed the variable `env_name` is set externally on the ansible command-line
