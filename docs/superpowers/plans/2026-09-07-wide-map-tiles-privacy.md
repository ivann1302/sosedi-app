# Wide map, Tiles capacity and location privacy plan

**Goal:** Close the map layout gap that does not require an iPhone and record a
reviewable operating baseline for Yandex Tiles and exact location.

**Assumptions:** 840 logical pixels is the first wide breakpoint; phone behavior
stays unchanged; the debug key is not a production authorization; provider
prices and terms are checked against official pages dated 07.09.2026.

**Done when:** a widget test sees list and map together at 1000×800 and keeps the
list visible after marker selection; the capacity/budget and privacy contracts
name their assumptions, gates and retention; checklist and roadmap agree.

- [x] Add the failing wide-layout widget test.
- [x] Render the shared catalog list and map as a 5:7 split from 840 px.
- [x] Preserve the existing phone toggle and shared selected item state.
- [x] Document tile request estimates, 30 RPS free boundary and budget decision.
- [x] Document exact-location purpose, minimization, consent, fallback and
  retention.
- [x] Run focused and full verification, then update checklist, roadmap and
  handoff.
