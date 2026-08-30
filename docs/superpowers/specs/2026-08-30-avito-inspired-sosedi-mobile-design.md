# Sosedi Mobile: Avito Mechanics, Sosedi Identity

**Date:** 2026-08-30

**Status:** approved for implementation

**Roadmap owner:** `MVP_CHECKLIST.md`, section 8.2

## Goal

Bring the existing Flutter MVP to a familiar, restrained Russian marketplace
interface: photo-first discovery, compact information hierarchy and predictable
actions inspired by Avito mechanics, while preserving Sosedi colors, rental
semantics, privacy boundaries and product scope.

This is a visual and interaction-system refresh. It must not change REST
contracts, booking/payment state machines, authorization, legal gates or the
set of supported MVP features.

## Reference boundary

Use these marketplace patterns:

- search is the primary catalog control;
- listing photos, price and title dominate cards;
- filters are compact and open focused controls;
- item details use a linear hierarchy instead of nested decorative cards;
- creation is a short, photo-first sequence;
- profile, notifications and settings use grouped rows;
- the primary action remains visible near the bottom edge.

Do not copy Avito trademarks, icons, illustrations, exact copy, blue palette,
promotions, stories, recommendation feeds, cart, delivery, subscriptions or
other features outside the Sosedi MVP. The visual result must be recognizably
Sosedi, not an Avito clone.

## Design principles

1. **Content before chrome.** Photos, price, dates, status and next action are
   more prominent than containers or decoration.
2. **Orange is scarce.** Brand orange identifies the primary action, current
   destination and a small number of meaningful selections. It is not a card
   background.
3. **Flat hierarchy.** Prefer whitespace and one-pixel dividers over shadows,
   nested borders and stacked cards.
4. **One obvious action.** Each state has one visually dominant CTA. Secondary
   actions are text or quiet outline buttons.
5. **Status is information, not decoration.** Use concise text and an optional
   small icon; do not turn every status into a colored capsule.
6. **Familiar navigation.** Preserve the existing five destinations and route
   behavior. Do not introduce custom gestures or hidden navigation.
7. **Trust without claims.** Keep privacy, moderation and safety copy factual;
   do not imply platform verification, payment protection or legal approval
   that is not active.

## Typography

Use **Onest Variable** as the only bundled interface family.

- source: official `simpals/onest` release or the corresponding pinned Google
  Fonts binary;
- license: SIL Open Font License 1.1, stored beside the binary;
- scripts: Cyrillic and Latin must be present;
- axis: variable `wght`, 100–900 available; the app uses only 400, 500, 600,
  700 and 800;
- fallback: platform sans-serif only if the bundled asset cannot load.

Type scale:

| Role | Size / height | Weight |
|---|---:|---:|
| Screen title | 24 / 30 | 700 |
| Detail title | 22 / 28 | 700 |
| Section title | 18 / 24 | 700 |
| Card title | 15 / 20 | 600 |
| Price large | 24 / 30 | 800 |
| Price card | 17 / 22 | 700 |
| Body | 16 / 23 | 400 |
| Secondary | 14 / 20 | 400 |
| Label | 13 / 18 | 600 |

Do not use all-caps headings, artificial letter spacing or more than three
weights on one screen.

## Visual tokens

### Color

| Token | Value | Use |
|---|---|---|
| `brand` | `#FEA319` | Primary CTA, active progress and quiet non-text brand cue |
| `brandPressed` | `#FF8A00` | Pressed primary action |
| `brandForeground` | `#B65700` | Accessible dark-orange foreground and input focus |
| `ink` | `#17202B` | Primary text and important icons |
| `muted` | `#65727C` | Secondary text |
| `canvas` | `#FFFFFF` | Main screen background |
| `subtleSurface` | `#F7F8F9` | Search, filters and grouped sections |
| `line` | `#E4E8EB` | Dividers and necessary outlines |
| `warmSelection` | `#FFF2D9` | Selected filter or quiet brand emphasis |
| `success` | `#1C7C54` | Confirmed success text/icon only |
| `error` | `#B42318` | Validation, destructive action, error text |

All text/background pairs must meet WCAG AA contrast. Do not use gradients,
glass effects or full-card orange fills.

`brandForeground` is the only orange foreground/focus token: it measures
4.825:1 on `canvas` and 4.538:1 on `subtleSurface`. Keep `brand` for filled
primary actions, active progress and quiet non-text cues, not orange text.

### Geometry and spacing

- spacing scale: 4, 8, 12, 16, 24 and 32 px;
- horizontal screen padding: 16 px;
- compact row gap: 12 px;
- control radius: 10 px;
- image/card radius: 12 px;
- sheet/dialog radius: 16 px;
- capsule radius is allowed only for a real filter, tag or compact status that
  cannot be expressed clearly as text;
- no default card shadow; modal elevation remains the platform default;
- touch targets are at least 48×48 px.

## Component rules

### App bar and navigation

- Screen titles are left-aligned inside the app. Centered headings remain a
  documentation-map choice, not a mobile rule.
- The bottom navigation stays at five destinations: Find, Bookings, Lend,
  Inbox and Profile.
- Remove the Material pill indicator. Selected icon and 600-weight label use
  `brandForeground`; unselected destinations use `muted` at weight 600.
- Use a top divider instead of elevation.

### Search and filters

- Search height is 48 px on `subtleSurface`, without a visible outline at rest.
- Only active filters appear in the first row; secondary filters live in a
  bottom sheet.
- Unselected filters use `subtleSurface`; selected filters use
  `warmSelection` with an `ink` label and optional brand icon.
- Avoid horizontal rows where important controls are clipped without a clear
  scroll affordance.

### Buttons and fields

- Primary button: 52 px high, `brand` background, `ink` text, 10 px radius.
- Secondary button: text button by default; outline only when a bounded
  alternative must be visible.
- Destructive action: red text, confirmation dialog, no red filled button on
  ordinary screens.
- Text fields use `subtleSurface` at rest, a one-pixel `line` boundary where
  needed and a two-pixel `brandForeground` focus boundary.
- Sticky bottom actions respect safe area and never cover scrollable content.

### Cards, rows and states

- Catalog cards are image plus text, without an outer bordered container.
- Operational entities such as bookings use compact rows with one thumbnail,
  status text and the next relevant fact.
- Settings and inbox use grouped rows with dividers, not individual outlined
  buttons/cards.
- Empty state: one simple Material icon, short title, one explanatory sentence
  and at most one action. No generated illustration.
- Loading: existing progress indicators or a minimal local placeholder; do not
  add a skeleton-animation dependency.
- Error: short user-facing message and one retry action. Technical details stay
  out of the screen.

Create a shared widget only after the same visual/behavioral pattern is needed
by at least three screens. Do not introduce a separate design-system package.

## Screen behavior

### Catalog and favorites

- Search is the first control below the safe area.
- Use a two-column grid at phone width and a responsive wider grid on tablets.
- Listing image is square with 12 px radius.
- Text order: price per day, title, area/distance; condition is shown only when
  it helps the decision and does not displace location.
- Favorite is a 48 px overlay action on the photo.
- Map/list switch is compact and retains all existing query state.

### Item details and owner profile

- Lead with the photo gallery, then price and title.
- Present condition, completeness, category and area as flat fact rows.
- Owner is one tappable row with name, verified-rental rating and chevron.
- Safety information is a quiet section with a divider, not a warning-colored
  card unless the content is actually a warning.
- The `Choose dates` CTA remains sticky at the bottom.
- Exact address and contact visibility remain server-controlled and unchanged.

### Booking creation, list and details

- Booking creation keeps the date-first flow and full price disclosure.
- Price lines are flat rows; document acceptance stays explicit and cannot be
  visually hidden.
- Booking list uses thumbnail rows: title, human-readable status, dates and
  `Borrowing`/`Lending`. Filters remain compact and scroll-safe.
- Booking details lead with status and server-derived next action. Timeline,
  price, handover, acts and support are separate flat sections.
- Demo payment remains visibly labeled as demonstration and cannot resemble a
  production payment guarantee.

### Chat, inbox and support

- Chat keeps text-only scope, simple neutral bubbles and a fixed composer.
- Inbox is a divided list; unread state is a small brand marker and stronger
  title weight, not a colored card.
- Support forms use the same fields and bottom action as other forms.
- Support thread distinguishes user/support by alignment and label without
  bright role-colored containers.

### Create/edit listing and owned listings

- Keep exactly three creation steps and show `Step N of 3` as plain text with
  a two-pixel progress line.
- Photos remain step one. The cover marker and remove action sit on the image.
- Group fields by decision: identity, condition/terms, price/location.
- Owned listings use image rows with moderation status as text.
- Existing manual coordinate fields remain only until the approved MapKit
  location control replaces them; the redesign must not normalize them as the
  final UX.

### Profile, privacy and system screens

- Profile header contains avatar, name, city and concise trust status.
- Favorites, sessions, documents, support, export and blocked users become
  grouped list rows with section headings and dividers.
- Account closure stays a separate destructive text action.
- Auth/onboarding use one message, one field/action and no decorative feature
  cards.
- Update-required screen stays focused on one explanation and one CTA.

## Rollout strategy

The refresh is implemented as independently reviewable batches:

1. Onest asset, theme tokens and shared primitive behavior.
2. App shell, catalog grid and favorites.
3. Item details, owner profile and booking creation.
4. Booking list/details, chat and inbox.
5. Create/edit listing and owned listings.
6. Profile, support, privacy, auth and system states.
7. Screenshot regeneration, cross-screen consistency audit and documentation.

Each batch must keep business logic and routes unchanged, pass relevant widget
tests and analyzer, regenerate affected route screenshots, and end in a small
reviewable commit. Do not begin a second batch with unresolved Critical or
Important review findings in the first.

## Verification and acceptance

The refresh is complete when:

- all 38 documented Flutter route/state screenshots are regenerated from real
  widgets and remain linked in `docs/app-user-paths.html`;
- all primary paths are visually inspected at 430×932;
- catalog, primary CTA and next-action areas are checked at 320×720 and 200%
  text scale without overflow or inaccessible actions;
- Android and iOS use the bundled Onest binary rather than depending on a
  network font;
- Russian text, `₽`, dates and numeric weights render correctly;
- `make mobile-analyze`, `make mobile-test`, `make mobile-screenshots` and
  `make app-user-paths-check` pass;
- existing auth, privacy, booking and legal fail-closed behavior remains
  unchanged;
- `MVP_CHECKLIST.md`, `sosedi-roadmap.html` and screenshot documentation refer
  to this design contract consistently.

## Sources

- Current project UI: `mobile/lib/core/theme/app_theme.dart` and
  `docs/app-user-paths.html`.
- Marketplace flow reference: <https://scrn.gallery/app/avito?tab=flows>,
  captured February 2026.
- Onest upstream and license: <https://github.com/simpals/onest>.
- Google Fonts metadata and pinned binary source:
  <https://github.com/google/fonts/blob/main/ofl/onest/METADATA.pb>.
