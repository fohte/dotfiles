aws_account_info() {
  [ -n "$AWS_ACCOUNT_NAME" ] && [ -n "$AWS_ACCOUNT_ROLE" ] && echo "%F{magenta}$AWS_ACCOUNT_NAME:$AWS_ACCOUNT_ROLE%f%{$reset_color%} "
}

PROMPT='$(aws_account_info)'"$PROMPT"
