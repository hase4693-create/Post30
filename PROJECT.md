# Post30 Project

Last updated: 2026-08-07

## Purpose

Post30 is an iOS application for planning and managing social-media posts over
a 30-day period. It helps users prepare content, track posting status, review
plans through Home, list, and calendar views, and copy text for use on social
platforms.

This document defines what Post30 is. Development procedure belongs in
`AGENTS.md`; technical boundaries belong in `ARCHITECTURE.md`.

## Product Identity

- Product: Post30
- Platform: iOS
- Developer brand: CraftFlow
- Support: `craftflow.apps@gmail.com`
- Repository: `hase4693-create/Post30`
- Official checkout: `/Users/hasegawa/Desktop/dev/post30/main`
- Bundle ID: `com.hasegawa.post30`
- Deployment target: iOS 17.0+
- App Store primary language: Japanese

Reconfirm release-sensitive values from the current repository and App Store
Connect. Historical documentation alone is not release evidence.

## Product Goals

- Make a 30-day posting plan easy to create and maintain.
- Reduce friction when finding, editing, copying, and tracking planned posts.
- Keep the first iOS release dependable, private, and understandable.
- Support dark mode, Dynamic Type, VoiceOver, and clear empty states.
- Grow through bounded, explicitly approved Phases.

## Current Scope

The agreed iOS feature set includes:

- Home overview
- 30-day or monthly planning
- Post list, creation, and editing
- Post status tracking
- Copying post content
- Calendar view
- Settings
- Empty states
- Dark mode
- Dynamic Type and VoiceOver considerations
- On-device SwiftData persistence
- Privacy policy and support contact

The current source is authoritative for exact behavior and model details.

## Data and Privacy

The current iOS application stores its data on device. Accounts, analytics,
cloud synchronization, third-party AI, and subscription billing are not
implicit extensions of the current product. Each requires separate product,
architecture, security, privacy, migration, and release approval.

## Verified Historical State

- Phases 1–13 were reported complete.
- Phase 14-B device QA was recorded and merged through PR #4.
- Release Build, Archive, AppIcon, signing-team configuration, export
  compliance, and a historical result of 147 passed tests were reported.
- Phase 14-C was defined to include Archive, validation, App Store Connect
  upload, and confirmation of TestFlight processing.
- Apple Developer Program membership was reported as the remaining external
  prerequisite at that time.

These are migration notes, not confirmation of current external state. Check
the repository, Apple account, TestFlight, and App Store Connect before acting.

## Version 1.0 Release Sequence

1. Confirm Apple Developer Program access.
2. Confirm or create the Post30 App Store Connect record.
3. Verify the Bundle ID, platform, and primary language.
4. Confirm the approved Version and Build numbers.
5. Build, test, Archive, and validate the approved source.
6. Upload and confirm TestFlight processing.
7. Perform approved TestFlight QA and complete App Store metadata.
8. Submit and release only through separate approval gates.
9. Record actual results in `RELEASE_CHECKLIST.md` and `PHASE_HISTORY.md`.

## Roadmap Candidates

Version 1.1 candidates, not yet approved implementation scope:

- Post deletion with confirmation
- Search by content, hashtag, or date
- Filters by destination and status
- Sorting
- Review request flow
- JSON export/import backup
- Settings improvements

Later candidates include AI-assisted generation, multi-device synchronization,
and a Free/Pro subscription model. A roadmap item begins only after an approved
Phase defines purpose, scope, files, completion criteria, tests, risks, and
excluded work.

## Web Project Separation

Post30 Web is a separate planned product implementation:

- Repository: `hase4693-create/Post30-Web`
- Local checkout: `/Users/hasegawa/Desktop/dev/post30-web/main`
- Candidate stack: Next.js App Router, TypeScript, React, Tailwind CSS,
  Supabase PostgreSQL/Auth/RLS, and Vercel
- PWA support: candidate for a later Web Phase

The stack remains a proposal until Web Phase 0 approves it. Web source,
dependencies, secrets, migrations, deployment configuration, and Git history
must never be placed in the iOS repository. iOS and Web remain independent
until an approved integration Phase defines shared identity, APIs, data
ownership, migration, privacy, and synchronization.

## Open Decisions

- Current iOS release and App Store Connect status
- Authoritative current feature inventory
- Priority between Version 1.0 release work and Version 1.1 development
- First approved Version 1.1 Phase
- Timing and approved scope of Web Phase 0
- Whether iOS and Web will eventually share a backend
