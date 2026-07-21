
#!/bin/bash
set -euxo pipefail

# Tell `pixi global` to not set CONDA_PREFIX during activation
mkdir -p "${PREFIX}/etc/pixi/nu"
touch "${PREFIX}/etc/pixi/nu/global-ignore-conda-prefix"

export OPENSSL_DIR="${PREFIX}"
export CARGO_PROFILE_RELEASE_STRIP="symbols"
export CARGO_PROFILE_RELEASE_LTO="false"

export RUSTFLAGS="${RUSTFLAGS:-} -L${PREFIX}/lib"

mkdir -p "${PREFIX}/etc/conda/activate.d"
mkdir -p "${PREFIX}/etc/conda/deactivate.d"

cat > "${PREFIX}/etc/conda/activate.d/nushell_activate.sh" << 'EOF'
export NU_LIB_DIRS_CONDA_BACKUP="${NU_LIB_DIRS:-}"
export NU_LIB_DIRS="${CONDA_PREFIX}/share/nushell/lib"
EOF

cat > "${PREFIX}/etc/conda/deactivate.d/nushell_deactivate.sh" << 'EOF'
export NU_LIB_DIRS="${NU_LIB_DIRS_CONDA_BACKUP}"
unset NU_LIB_DIRS_CONDA_BACKUP
if [ -z "${NU_LIB_DIRS}" ]; then
    unset NU_LIB_DIRS
fi
EOF

NU_PATH="$(pwd)"
LICENSE_DIR="${NU_PATH}/license-files"
mkdir -p "${LICENSE_DIR}"

build_and_license() {
  local dir="$1"
  local stem
  stem="$(basename "${dir}")"
  pushd "${dir}" > /dev/null
  cargo auditable install --locked --no-track --bins --root "${PREFIX}" --path .
  cargo-bundle-licenses --format yaml --output "${LICENSE_DIR}/${stem}_thirdparty_licenses.yaml"
  popd > /dev/null
}

# Build nushell itself
build_and_license "${NU_PATH}"

# Build any nu_plugin_* crates
if [ -d "${NU_PATH}/crates" ]; then
  for plugin_dir in "${NU_PATH}"/crates/nu_plugin_*/; do
    if [ -f "${plugin_dir}/Cargo.toml" ]; then
      build_and_license "${plugin_dir%/}"
    fi
  done
fi