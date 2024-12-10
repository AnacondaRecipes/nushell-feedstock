@echo on

:: Taken from https://github.com/conda-forge/py-spy-feedstock/blob/main/recipe/bld.bat

set CARGO_PROFILE_RELEASE_STRIP=symbols
set CARGO_PROFILE_RELEASE_LTO=fat

:: build
cargo install --no-track --features unwind --locked --root "%PREFIX%" --path . || exit 1
