# Run on startup (optional)

If your VM “space” runs a shell init script, you can choose to auto-run the dashboard on Mondays.

**Recommendation:** keep it manual at first (run it when you want).

If you do want auto-run, add something like this to your shell init:

```bash
# TL-Ops (run dashboard on Monday, once per day)
DOW="$(date +%u)" # 1=Mon
TODAY="$(date +%F)"
STATE="$HOME/tl-ops/state/last_dashboard_run"

if [[ "$DOW" == "1" ]]; then
  if [[ ! -f "$STATE" ]] || [[ "$(cat "$STATE")" != "$TODAY" ]]; then
    (cd "$HOME/tl-ops" && ./ops/run_dashboard.sh >/dev/null 2>&1 || true)
    echo "$TODAY" > "$STATE"
  fi
fi
```

This avoids repeated runs if you open multiple shells.
