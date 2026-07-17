# Pin the docker CLI to colima's default profile socket. DOCKER_HOST takes
# priority over the active docker context, so this can't be silently
# overridden by `docker context use` or a direct edit to
# ~/.docker/config.json's currentContext.
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
