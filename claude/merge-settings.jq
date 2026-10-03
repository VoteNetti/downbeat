# Merge claude/settings.base.json (.[1]) into an existing ~/.claude/settings.json (.[0]).
# - Keys Claude Code writes itself (model, effortLevel, plugins, ...) are left alone.
# - permissions.allow: base entries are appended if missing; existing order is kept.
# - hooks: base hook commands are removed from wherever they currently sit, then the
#   base entries are appended, so re-running never duplicates them and the user's
#   own hooks are untouched.
.[0] as $cur
| .[1] as $base
| [($base.hooks // {})[][].hooks[].command] as $owned
| $cur
| .permissions.allow = ((.permissions.allow // []) as $have | $have + (($base.permissions.allow // []) - $have))
| .hooks = reduce (($base.hooks // {}) | to_entries[]) as $event (.hooks // {};
    .[$event.key] = (
      [ (.[$event.key] // [])[]
        | .hooks |= map(select(.command as $c | any($owned[]; . == $c) | not))
        | select(.hooks | length > 0) ]
      + $event.value))
