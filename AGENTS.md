# AGENTS.md

Lean, modular Quickshell bar for Hyprland on Wayland (CachyOS).
Quickshell version: <0.3.2, or the version installed>. Single monitor,
NVIDIA GPU.

Goals, in priority order:
1. Lean at runtime: low idle CPU and memory, few child processes, fast startup, nothing running for widgets that are hidden or closed.
2. Easy to change: small files, one job each, clear boundaries.
3. Correct and safe: lint-clean, no command injection, atomic writes, graceful when a program or hardware is missing.
4. Parity with the features I choose to keep, one widget at a time.

## Reference repo (read-only)
The old bar is at <~/Projects/qs-old-bar> 
- Never edit it, never copy its files wholesale.
- Use it only to understand what a widget does. Re-derive each widget from that understanding. Old scripts are not reused.
- Phase 0 only: you may start the old bar once with `qs -p <path>` to measure it, then stop it. Don't use any of its features that write outside its own folder.

## Code standards
- qmllint must be clean (0 warnings) for every new file. No unqualified   access, required properties instead of reaching into parent ids, and   pragma ComponentBehavior: Bound where delegates need it.
- One component per file. Name files for what they do. Suffixes: Pill (bar item), Panel (floating window), Tab (settings page), Service (runtime singleton), Settings (saved-settings singleton in `config/`).
- Settings live in `config/`. `Config.qml` is only the saved store (the
  fields in `state/bar-layout.json`), the save timer, and shared validators.
  Each feature has its own `<Feature>Settings.qml` singleton with its value
  helpers. A settings page with Apply/Undo/Reset uses that singleton's
  `editor`, a `Draft` (`config/Draft.qml`): read `editor.value`, edit with
  `editor.set(key, value)`, and wire the footer to `editor.dirty`,
  `editor.canUndo`, `apply()`, `undo()`, and `reset()`. Never write to the
  store from inside a binding. New saved fields go in `Config.qml`; save
  several at once with `Config.saveFields()`.
- Every folder has a hand-written qmldir. When you add, rename, or delete a QML file, update that folder's qmldir in the same change (`Name 1.0 Name.qml`, or `singleton Name 1.0 Name.qml` for a file with `pragma Singleton`). An unlisted file fails at runtime with "X is not a type" or "X is not defined", even though qmllint may pass.
- No component references an id from another file. Data flows down as required properties. Events flow up as signals.
- Colors, sizes, fonts, and intervals come from the Theme and Config singletons. No hardcoded values in widgets.
- Shell scripts are a last resort. Prefer Quickshell's native modules and D-Bus services. Any script must quote variables, validate input, write files atomically, and never build commands from untrusted text.

## Goals
Goals, in priority order:
1. Lean at runtime: low idle CPU and memory, few child processes, fast
   startup, nothing running for widgets that are hidden or closed.
2. Easy to change: small modular files, each doing one thing, with
   clear boundaries.
3. Correct and safe: qmllint-clean, no command injection, atomic
   writes, graceful behavior when a program or hardware is missing.
4. Feature parity with the features I keep (list below), with my saved
   settings importable.

