@echo off
setlocal enabledelayedexpansion

mkdir "%PREFIX%\etc\pixi\nu"
type nul > "%PREFIX%\etc\pixi\nu\global-ignore-conda-prefix"

set "OPENSSL_DIR=%PREFIX%"
set "CARGO_BUILD_RUSTFLAGS=%CARGO_BUILD_RUSTFLAGS% -L%PREFIX%\lib"
set "CARGO_PROFILE_RELEASE_STRIP=symbols"

set "NU_LIB_DIR=%PREFIX%\share\nushell\lib"

set "ACTIVATE_D=%PREFIX%\etc\conda\activate.d"
set "DEACTIVATE_D=%PREFIX%\etc\conda\deactivate.d"
mkdir "%ACTIVATE_D%"
mkdir "%DEACTIVATE_D%"

> "%ACTIVATE_D%\nushell_activate.bat" (
    echo @echo off
    echo set "NU_LIB_DIRS_CONDA_BACKUP=%%NU_LIB_DIRS%%"
    echo set "NU_LIB_DIRS=%NU_LIB_DIR%"
)

> "%DEACTIVATE_D%\nushell_deactivate.bat" (
    echo @echo off
    echo set "NU_LIB_DIRS=%%NU_LIB_DIRS_CONDA_BACKUP%%"
    echo set "NU_LIB_DIRS_CONDA_BACKUP="
)

set "NU_PATH=%CD%"
set "LICENSE_DIR=%NU_PATH%\license-files"
mkdir "%LICENSE_DIR%"

for %%F in ("%NU_PATH%") do set "NU_STEM=%%~nxF"

cargo auditable install --locked --no-track --bins --root "%PREFIX%\Library" --path . --verbose
cargo-bundle-licenses --format yaml --output "%LICENSE_DIR%\%NU_STEM%_thirdparty_licenses.yaml" || exit /b 1

for /d %%D in (crates\nu_plugin_*) do (
    if exist "%%D\Cargo.toml" (
        pushd "%%D"
        for %%F in ("%%D") do set "PLUGIN_STEM=%%~nxF"
        cargo auditable install --locked --no-track --bins --root "%PREFIX%\Library" --path . || exit /b 1
        cargo-bundle-licenses --format yaml --output "!LICENSE_DIR!\!PLUGIN_STEM!_thirdparty_licenses.yaml" || exit /b 1
        popd
    )
)
