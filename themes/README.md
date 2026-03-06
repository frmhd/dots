set theme:

`themes/set-theme <theme-name>`

generated theme files are materialized into `~/.config/omarchy/current/theme`.

template files live in `themes/themed/*.tpl` and are rendered from `colors.toml` when a theme does not provide an explicit override file.

OpenCode follows the active system theme via `opencode/.config/opencode/tui.jsonc`, and `themes/set-theme` sends it `SIGUSR2` to reload after theme changes.
