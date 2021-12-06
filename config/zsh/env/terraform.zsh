# a cache directory for Terraform plugins
export TF_PLUGIN_CACHE_DIR=~/.cache/terraform/plugins

# increase parallelism form 10 from 20
export TF_CLI_ARGS_plan="-parallelism=20"
export TF_CLI_ARGS_apply="-parallelism=20"
export TF_CLI_ARGS_destroy="-parallelism=20"
