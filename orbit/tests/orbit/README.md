# Orbit Tests

The test suite distinguishes source validation from deployed and live checks.

```sh
./tests/orbit/run-all
./tests/orbit/run-all --live
./tests/orbit/run-soak --minutes 1 --interval 5
```

Contract tests inspect this repository and do not require `$HOME` to be the
repository. Live and soak tests inspect the deployed user session and require
an active non-root Hyprland environment.

Results are written below `${XDG_STATE_HOME:-$HOME/.local/state}/orbit/tests`.
Generated results, caches, and runtime state are never repository source.
