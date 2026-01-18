add_path "$HOME"/.cargo/bin(N-/)

# sccache: shared compilation cache for Rust
# Caches compilation results across worktrees with the same source code
export RUSTC_WRAPPER=sccache
