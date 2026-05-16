# Applied memories

## Relevant hits from MEMORY.md

- **user_professional_background** — Robert: designer (10yr) → developer (4yr), ships polished full systems.
  - *What it changes*: Polish phase must hit Ghostty/Apple-grade fit and finish; sane defaults out of the box, no 90-min config; visual evidence required (screenshots) in UI phases.

- **project_snapnote** — Snapnote (other macOS app at /Users/robert/Code/snapnote) prepared for direct notarized distribution; Sparkle SPM + Developer ID cert *pending user action*.
  - *What it changes*: Plan for Developer ID cert as a known prerequisite. Phase the signing/notarization work so build artifacts can be produced unsigned first; signed/notarized release waits on cert confirmation. Reuse the Sparkle + DMG patterns the user has already vetted on Snapnote.

- **project_hangar** — this run's project memory; locked decisions and v0.1 scope mirror it.
  - *What it changes*: Nothing new — but on final phase, update this memory with the actual repo path, the live ROADMAP link, and v0.1 release status.

- **feedback_dont_run_generators** — hand the user the shell command for long-running API generators; don't execute them silently.
  - *What it changes*: For long-running build / notarization steps that need user-side cert input or interactive Xcode auth grants, surface the exact command to run and stop — don't loop attempting.

- **reference_macos_uitest_automation** — `xcodebuild test` UI runner "failed to initialize automation mode" is a one-time Xcode automation-permission grant.
  - *What it changes*: If a UI-test phase fails with that error, treat it as an expected one-time grant, not a code bug. Document in the test phase spec.

- **reference_base_ui_package**, **reference_dotenv_local**, **reference_ai_sdk_v6_convert**, **reference_openai_function_name_pattern** — JS/TS-specific. Not applicable.

- **feedback_next_build_while_dev** — Next.js-specific. Not applicable.

## Memory writeback plan

- After each phase that surfaces a non-obvious Swift/SwiftUI/SwiftTerm/Sparkle/notarization quirk, write a `reference_*.md` or `feedback_*.md` under MEM_DIR.
- Final phase: update `project_hangar.md` with shipped state.
