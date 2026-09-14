export PATH="$HOME/.local/bin:$PATH"

# Guarded: Rust is not installed on every machine, and an unguarded source
# here prints an error on every single shell start.
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
