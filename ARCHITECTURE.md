# Post30 Architecture

Last updated: 2026-08-07

## Principles

- The iOS repository is the native application's sole source of truth.
- Preserve the proven architecture unless an approved Phase justifies change.
- Prefer small, testable changes over speculative abstractions.
- Keep UI, domain behavior, and persistence responsibilities understandable.
- Treat cloud sync, authentication, AI, analytics, and subscriptions as
  architecture changes rather than ordinary feature additions.
- Do not document unverified implementation details as facts.

## Current Platform Baseline

- UI: SwiftUI
- Persistence: SwiftData on device
- Minimum OS: iOS 17.0+
- Bundle ID: `com.hasegawa.post30`
- Signing: Automatic with the configured development team
- Swift language mode: preserve the current project setting
- Swift 6 language-mode migration: not currently planned
- Export compliance: historically `ITSAppUsesNonExemptEncryption = NO`

Reverify all configuration values from the Xcode project before release or a
configuration change.

## Functional Boundaries

The product is organized conceptually around:

- Home: overview and entry points into the posting plan
- Posts: creation, editing, listing, status, destination metadata, and copying
- Planning: 30-day or monthly planning behavior
- Calendar: date-oriented review and navigation
- Settings: support, privacy, app information, and preferences
- Persistence: SwiftData storage and query/update behavior
- Shared presentation: colors, typography, cards, status badges, empty states,
  dark mode, and accessibility behavior

This is a conceptual map, not a claim about current folder or type names. Source
code remains authoritative.

## Domain and Persistence

Known domain concepts include `Post`, `MonthPlan`, `PostStatus`, social
destination or SNS type, planned dates, and creation/update timestamps. Verify
fields, optionality, relationships, uniqueness, and deletion behavior in source
before designing a change.

- Model changes require an explicit migration and data-safety plan.
- Prefer backward-compatible changes.
- Test affected create, read, update, delete, relationship, and empty-store
  behavior.
- Never silently discard user data.
- Export/import or cloud migration must define versioning, conflict behavior,
  failure recovery, rollback, and privacy impact.

SwiftData is the current local source of truth. UI must not maintain competing
durable copies of model state. Mutations should propagate consistently to Home,
list, and calendar surfaces.

## UI and Accessibility

- Follow SwiftUI patterns already established in the repository.
- Reuse verified design tokens and components.
- Avoid styling that conflicts with dark mode or Dynamic Type.
- Provide meaningful accessibility labels, values, hints, traits, and order.
- Confirm appropriate touch targets and destructive-action confirmation.
- Treat empty, loading, failure, and success states as feature completeness.

Accessibility and device-coverage claims require actual verification.

## Dependencies and Security

Dependencies require explicit approval and an assessment of need, maintenance,
privacy, licensing, binary size, security, testing, and removal. Prefer platform
APIs and existing code when they are sufficient.

Never commit API keys, tokens, certificates, provisioning profiles, private
keys, `.env` files, service-role keys, or other secrets. External services need
least-privilege access, privacy review, and defined failure behavior.

## Build, Test, and Xcode Integrity

Use repository schemes, configurations, destinations, and test plans as the
source of truth. Depending on scope, verification may include targeted tests,
the full suite, Debug or Release builds, Archive, and validation. Record exact
observed results. The historical 147-test result is not a permanent invariant.

Treat `project.pbxproj`, entitlements, build settings, schemes, signing,
capabilities, deployment target, Version, and Build as sensitive configuration.
Review their diffs line by line. Personal Xcode state such as `xcuserdata` and
`UserInterfaceState.xcuserstate` is not a product artifact.

## Release Chain

```text
approved source
  -> approved Release configuration
  -> build and tests
  -> Xcode Archive
  -> validation
  -> App Store Connect upload
  -> TestFlight processing and QA
  -> metadata and compliance
  -> review submission
  -> approved release
```

Each transition requires its own evidence and approval. A distributed binary
must correspond to the reviewed commit and approved Version/Build pair.

## Web Architecture Boundary

The Web implementation is a separate system, not another iOS target.

| Concern | Post30 iOS | Planned Post30 Web |
|---|---|---|
| Repository | `hase4693-create/Post30` | `hase4693-create/Post30-Web` |
| UI | SwiftUI | Candidate: React / Next.js |
| Language | Current Swift setting | Candidate: TypeScript |
| Persistence | SwiftData on device | Candidate: Supabase PostgreSQL |
| Identity | No shared account assumed | Candidate: Supabase Auth |
| Authorization | Device-local boundary | Candidate: PostgreSQL RLS |
| Delivery | TestFlight / App Store | Candidate: Vercel |
| Privacy | iOS local-data context | Separate cloud/account policy required |

The Web stack must be approved in Web Phase 0. Browser code must never receive a
Supabase `service_role` key. If Supabase is selected, public-schema tables need
reviewed RLS policies restricting users to their own data.

## Future iOS/Web Integration

No shared backend is currently approved. A future integration Phase must define
the system of record, identity, API contracts, schema versioning, SwiftData
migration or export/import, conflict resolution, offline behavior, deletion and
retention, security, rollout, compatibility, monitoring, and rollback.

Until then, iOS and Web remain operationally and architecturally independent.

## Repository Verification Needed

Maintain this document by verifying the actual source layout, model fields and
relationships, navigation and state ownership, shared components, scheme and
test-target names, current test count, deployment target, Swift language mode,
Version/Build, signing, entitlements, capabilities, and release-document paths.
Do not fill these details from assumptions.
