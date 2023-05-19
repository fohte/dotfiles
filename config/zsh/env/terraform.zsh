# a cache directory for Terraform plugins
export TF_PLUGIN_CACHE_DIR=~/.cache/terraform/plugins
if ! [ -d "$TF_PLUGIN_CACHE_DIR" ]; then
  mkdir -p "$TF_PLUGIN_CACHE_DIR"
fi

# increase parallelism form 10 from 20
export TF_CLI_ARGS_plan="-parallelism=20"
export TF_CLI_ARGS_apply="-parallelism=20"
export TF_CLI_ARGS_destroy="-parallelism=20"
