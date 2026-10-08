# activeFriends — Design Tokens (Lagoon Teal)

**Version:** 1.0 — Sept 2026
**Decision:** D13 — Lagoon Teal theme, locked
**Usage:** Single source of truth for the Flutter `ThemeData`. The interactive
preview lives at `mockups/theme-explorer.html` (deployed theme explorer).

## Palette — Light Mode

| Token | Hex | Usage |
|-------|-----|-------|
| background | `#F4F3EF` | App background |
| surface | `#FFFFFF` | Cards, nav bar |
| surfaceAlt | `#F7F6F2` | Feed cards, secondary surfaces |
| border | `#E2DFD8` | Dividers, card borders |
| textPrimary | `#26241F` | Body text |
| textMuted | `#6E6C66` | Secondary text, timestamps |
| textFaint | `#A9A7A1` | Placeholders |
| primary | `#14827B` | CTAs, FAB, active tab, highlighted "You" row, club chip |
| primarySoft | `#E3F1EE` | Chips, podium blocks 2–3, soft fills |
| accent (Coral) | `#E07A62` | Reactions, "NEW" badge, unread dot |
| accentSoft | `#FBEBE4` | Accent tint fills |
| gold | `#C79A17` | **Rank-1 only** (podium ring, gold styling) |
| danger | `#B3392E` | Destructive actions |

## Palette — Dark Mode

| Token | Hex | Usage |
|-------|-----|-------|
| background | `#1B1916` | App background (warm charcoal, not near-black) |
| surface | `#232119` | Cards, nav bar |
| surfaceAlt | `#2A2820` | Feed cards |
| border | `#3D3A31` | Dividers |
| textPrimary | `#DEDCD7` | Body text |
| textMuted | `#918F87` | Secondary text |
| textFaint | `#615F57` | Placeholders |
| primary | `#5BC9BC` | CTAs, FAB, active tab |
| primarySoft | `#1F332F` | Soft fills |
| accent (Coral) | `#EC927C` | Reactions, badges |
| accentSoft | `#3E2B23` | Accent tint fills |
| gold | `#E2B93B` | Rank-1 |
| danger | — | Same hue, lighten ~15% for dark bg |

## Signature Gradients

| Element | Value |
|---------|-------|
| WhatsApp share card | `linear-gradient(160deg, #35A493 0%, #2A8278 100%)` |
| Rank-1 podium column | `linear-gradient(180deg, #E3F1EE, #2E948B)` |
| Card overlay rows (share card) | `rgba(255,255,255,.10)`; rank-1 row `rgba(255,255,255,.20)` |

## Semantic Rules (enforced, not optional)

1. **One accent philosophy:** primary teal = interactive/structural; coral =
   social moments (reactions, unread); gold = rank-1 ritual. Nothing else colored.
2. **Gold never appears** except on the week's #1 (podium ring, share-card row).
3. **Coral is never a CTA color** — buttons and tabs are primary teal only.
4. Avatars: assigned from a fixed 8-color avatar palette (see mockup:
   `#C2554F, #7A6AA8, #4E7FA6, #8A7340, #6B8F71, #A15E7E, #5F7E9E, #14827B`),
   deterministic by user id hash.
5. Contrast: both modes clear WCAG AA (white on `#14827B` ≈ 4.8:1; body text
   on backgrounds ≥ 10:1). Keep it that way when adding tokens.

## Typography

| Role | Font | Weights | Sizes |
|------|------|---------|-------|
| Display / headings | Satoshi (Fontshare, free) | 700, 900 | 26–38px |
| Body | Satoshi | 400, 500 | 13–16px |
| Numbers (points, ranks) | Satoshi, `tabular-nums` | 900 | 14–26px |

Flutter: bundle Satoshi via `google_fonts`/`fontshare` download or asset TTFs;
fallback stack `Inter → system`. Never letterspace lowercase; display never
below 24px; 12px absolute floor.

## Flutter Mapping Notes

- Build light and dark `ThemeData` explicitly from this table (do not rely on
  `ColorScheme.fromSeed` — the palette is hand-tuned).
- `ColorScheme` roles: primary→primary, primarySoft→primaryContainer,
  coral→tertiary, gold/success/danger→extensions on a custom `AppColors` class.
- Highlighted "You" leaderboard row = primarySoft background (not primary).
- The Sunday share card is rendered with `RepaintBoundary` → PNG (1080×1350)
  using these tokens; the gradient is part of the brand, keep it on both modes.
