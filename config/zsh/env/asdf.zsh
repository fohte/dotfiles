asdf_dir="$(brew --prefix asdf)"

if [ -d "$asdf_dir" ]; then
  . "$asdf_dir"/libexec/asdf.sh
fi
