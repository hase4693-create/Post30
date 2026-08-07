# AGENTS.md — Post30 Development Rules

## Project

Post30 is an iOS application for planning and managing SNS posts.

Official repository:

- GitHub: `hase4693-create/Post30`
- Local: `/Users/hasegawa/Desktop/dev/post30/main`
- Default branch: `main`

This repository is the single source of truth for the iOS version.

Do not use old Phase directories, extracted ZIP copies, temporary Claude
workspaces, or other Post30 copies as development sources. In particular,
`/Users/hasegawa/Desktop/dev/post30/Post30Project_Phase6` is an obsolete
repository and must not be used for development.

## Roles

ChatGPT is responsible for:

- Project management and technical leadership
- Requirements and Phase planning
- Architecture and quality review
- Release planning and progress management

Codex is responsible for:

- Implementation and refactoring
- Build and test execution
- Technical investigation
- Approved Git operations
- Documentation updates

Do not expand the requested scope without approval. Do not infer unclear
requirements; stop and ask for clarification.

## Working Directory and Preflight

Before every task, run and report:

```bash
pwd
git branch --show-current
git status
```

The working directory must be:

```text
/Users/hasegawa/Desktop/dev/post30/main
```

If the directory is different, or the working tree contains unexpected
changes, stop before performing any work and report the issue.

Before starting approved implementation work:

```bash
git checkout main
git pull origin main
git checkout -b feature/phaseXX-short-feature-name
```

Confirm that `main` and `origin/main` are synchronized and that the working
tree is clean before creating the feature branch. Never implement or commit
directly on `main`.

## Phase Workflow

Development is managed one Phase at a time. Before a new Phase begins, present:

1. Phase number
2. Phase name
3. Purpose
4. Target features and scope
5. Files expected to change
6. Implementation approach
7. Completion criteria
8. Test cases
9. Risks
10. Work explicitly excluded from the Phase

Do not create a branch, create files, or change code until the user explicitly
says `実装してください` or otherwise gives equivalent implementation approval.

After implementation, report in this order:

1. Changed files
2. Implementation summary
3. Build result
4. Test result
5. `git diff --stat`
6. `git status`
7. Completion-criteria status
8. Remaining issues and known limitations
9. Recommended commit message

Wait for approval after this report.

## Approval Gates

The following actions require separate, explicit user instructions:

- Commit: only after `コミットしてください`
- Push: only after `pushしてください`
- Pull Request creation: only after `PRを作成してください`
- Merge to `main`: only after `Mergeしてください` or an equivalent explicit instruction
- Branch deletion: only after explicit approval

Approval for one action does not authorize any later action. Never force-push,
rewrite Git history, or create tags unless expressly requested.

Never use:

```bash
git add .
```

Stage only the specifically approved files and verify the staged file list
before committing.

## Quality Rules

- Prioritize maintainability, readability, and future extensibility.
- Run an appropriate Build and the full existing test suite after code or
  project-setting changes.
- Do not commit while Build or Test is failing.
- Report the exact number of detected, passed, failed, and skipped tests when
  test-result data supports it.
- Do not claim simulator, device, accessibility, Archive, TestFlight, or App
  Store Connect verification unless it was actually performed.
- Separate results into command/test verified, simulator verified, device
  verified, and user verification required when relevant.
- If a problem or unexplained test-count change is found, stop and report it
  before advancing to the next stage.

## Xcode Repository Hygiene

Do not include personal or automatically generated Xcode UI state in project
changes. In particular, exclude files such as:

```text
xcuserdata/
UserInterfaceState.xcuserstate
```

Before final diff, staging, commit, push, and PR operations, re-run
`git status` and verify that no unintended Xcode upgrade, build-setting,
workspace-state, ordering-only, signing, or project-file changes are included.

Do not delete files without explicit permission. Preserve unrelated user
changes and never restore or overwrite them without approval.

## Current iOS Technical Baseline

- Product: Post30
- Developer/brand: CraftFlow
- Support email: `craftflow.apps@gmail.com`
- App Bundle ID: `com.hasegawa.post30`
- Tests Bundle ID: `com.hasegawa.post30.tests`
- Deployment Target: iOS 17.0+
- Swift language mode: maintain the current project setting
- Swift 6 language-mode migration: not planned at this time
- Persistence: SwiftData
- Xcode: latest stable version
- Signing style: Automatic
- Development Team: configured for the Post30 app target
- AppIcon: configured
- Export compliance: `ITSAppUsesNonExemptEncryption = NO`

Privacy Policy:

- URL: `https://hase4693-create.github.io/Post30/privacy-policy/`
- Source: `privacy-policy/index.html`

## Current Release Status

Completed:

- Phases 1–13
- Phase 14-B device QA
- AppIcon configuration
- Development Team configuration
- Export-compliance configuration
- Release Build verification
- 147-test verification
- Release Archive verification
- Device QA
- `PHASE_HISTORY.md` and `RELEASE_CHECKLIST.md`

The iOS release process is paused pending paid Apple Developer Program
membership. Do not resume iOS implementation, TestFlight upload, or App Store
Connect work without explicit authorization. Treat `RELEASE_CHECKLIST.md` as
the source of truth for remaining release work.

## Documentation

- `AGENTS.md`: development workflow, approval gates, and agent rules
- `PROJECT.md`: product definition, current status, and roadmap
- `ARCHITECTURE.md`: technical structure, data boundaries, and future integration policy
- `PHASE_HISTORY.md`: completed Phase history and verified outcomes
- `RELEASE_CHECKLIST.md`: release readiness, completed checks, and remaining work
- `CLAUDE.md`: legacy Claude Code guidance; when it conflicts with this file or
  explicit user instructions, follow the explicit instruction first and this
  `AGENTS.md` second

Do not invent historical Phase details or mark unperformed checks as complete.

When these documents disagree, stop and ask which source is authoritative. Do
not silently reconcile conflicting facts.

## Release Approval Gates

Release work is sequential and separately approved:

1. Confirm the approved Version and Build values.
2. Confirm Bundle ID, signing team, capabilities, AppIcon, export compliance,
   and Release configuration.
3. Run the approved Release build and tests.
4. Create and validate an Archive.
5. Upload to App Store Connect.
6. Confirm TestFlight processing and perform approved QA.
7. Complete metadata, privacy, screenshots, age rating, and review information.
8. Obtain separate approval for App Store submission.
9. Obtain separate approval for release.
10. Record only the observed results in the release documentation.

Version or Build changes, Archive distribution, upload, TestFlight
distribution, submission, and release each require explicit approval. A
successful local build does not prove release readiness.

## Separate Web Project

The planned Post30 Web version is a separate project:

- Planned GitHub repository: `hase4693-create/Post30-Web`
- Planned local path: `/Users/hasegawa/Desktop/dev/post30-web/main`

Do not create or implement the Web project without explicit approval. Never
place Web source, Supabase configuration, Vercel configuration, or Web Git
history in this iOS repository. The Web project must have its own repository,
`AGENTS.md`, environment-variable policy, Phase history, tests, and release
workflow.

## Instruction Priority

When instructions conflict, use this priority:

1. The user's latest explicit instruction
2. The approved Phase plan and approval boundaries
3. This `AGENTS.md`
4. Other repository documentation, including `CLAUDE.md`

When uncertain, stop and ask before changing files or Git state.
