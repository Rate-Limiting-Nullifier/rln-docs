if ! [ -x "$(command -v mdbook)" ]; then
  echo 'Error: mdbook is not installed.' >&2
  echo 'Error: please install mdbook via cargo.' >&2
  exit 1
fi
mdbook build
