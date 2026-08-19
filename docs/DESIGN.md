---
name: Fargonam — Ink Blue
colors:
  surface: '#F6F7F8'
  surface-dim: '#E4E8E9'
  surface-bright: '#F6F7F8'
  surface-container-lowest: '#FFFFFF'
  surface-container-low: '#EEF2F3'
  surface-container: '#E8EDEE'
  surface-container-high: '#E1E7E8'
  surface-container-highest: '#DAE3E3'
  on-surface: '#161C24'
  on-surface-variant: '#5B656B'
  inverse-surface: '#222A32'
  inverse-on-surface: '#F0F4F5'
  outline: '#8B959B'
  outline-variant: '#D8DDDE'
  primary: '#16305C'
  on-primary: '#FFFFFF'
  primary-container: '#E3EDF3'
  on-primary-container: '#16305C'
  background: '#F6F7F8'
  on-background: '#161C24'
  ink-blue: '#16305C'
  ink: '#161C24'
  mist-white: '#F6F7F8'
  paper-white: '#FFFFFF'
  success: '#1FAE6B'
  success-container: '#E3F7EC'
  on-success-container: '#0F6B41'
  warning: '#C77B1E'
  warning-container: '#FBEEDD'
  on-warning-container: '#8A5514'
  error: '#B3413A'
  error-container: '#FBE9E7'
  on-error-container: '#7A2A23'
  dark-background: '#182133'
  dark-surface: '#2A3954'
  dark-surface-alt: '#334460'
  dark-outline: '#3A4B68'
  dark-on-surface: '#EBE9F5'
  dark-on-surface-variant: '#9796A8'
  dark-primary: '#B0C5E8'
  dark-error: '#D9716B'
typography:
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  price-display:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base-unit: 4px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 24px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The brand personality is **Reliable, Grounded, and Local-first**. Fargonam is a regional Super App
for the Fergana Valley, starting with a single-family stationery shop. The design system must feel
like a trustworthy neighborhood institution — not a generic fintech app, not a decorative craft
store.

The chosen style is **Ink Blue**: a deep navy primary (`#16305C`) on a near-white, cool-neutral
background, paired with a confident geometric display face. This replaces the prior "Ishonch"
deep-teal draft (`#0B6E4F`, 2026-08-17) — the product owner confirmed the brand primary on
2026-08-18. Nothing about this system references Midnight Indigo, Kutuku Violet, Vanilla Cream,
Kutuku's Poppins/pill-button shape language, or glassmorphism — those directions remain explicitly
rejected. Everything below except the primary hue itself is carried over unchanged from Ishonch:
the shape rules, spacing, typography, and the three governance rules were never in question, only
the brand color was.

Mockup-driven design work (Stitch) is discontinued as of 2026-08-18. This file is the **only**
design source going forward; UI is built directly in Flutter against these tokens, not prototyped
elsewhere first. Nothing under `stitch_markdown_project_documentation/` or any other `DESIGN.md`
in the repo is authoritative.

## Colors

The palette is anchored by **ink-blue** (`#16305C`), used for primary actions, the active nav tab,
and headers. Every neutral/surface/outline token below is the exact same lightness and saturation
as the prior Ishonch draft — only the hue was rotated from teal to ink-blue — so contrast ratios
and visual weight are unchanged, just the brand hue is.

Backgrounds use **mist-white** (`#F6F7F8`), a cool off-white — not cream, not pure white — to
reduce eye strain. Cards sit on **paper-white** (`#FFFFFF`).

### Dark mode

The app defaults to dark mode (`ThemeMode.dark`), so a dark palette is part of this spec, not an
afterthought. `dark-background`/`dark-surface`/`dark-surface-alt`/`dark-outline` are the same
ink-blue hue at low lightness (derived by hue-rotating the app's prior Midnight-Indigo-based dark
scale, so the "how dark, how saturated" relationships that were already tuned stay put). On a dark
background, `dark-primary` (`#B0C5E8`, a light ink-blue tint) stands in for `primary` — a saturated
`#16305C` would have almost no contrast against a near-black navy background. `success` stays the
same hex in both modes (it already has enough contrast against the dark background); `error`
becomes `dark-error` (`#D9716B`) for the same reason `dark-primary` exists.

### System (semantic) colors — MANDATORY rules

These rules are unchanged from Ishonch — they were never about the brand hue, and stay
non-negotiable across every screen in this design system:

1. **Success and error states never rely on color alone.** Every success or error state (toast,
   banner, inline message, badge) MUST pair its color with both an icon (checkmark for success,
   an alert/warning glyph for error) AND a text label. A colored dot or colored text by itself is
   never sufficient — screen readers and colorblind users both make color-only signaling
   unreliable.
2. **Error and warning states are never rendered as a solid filled button.** A `success`/`warning`/
   `error` color must never fill a large solid surface the way the `primary` button does — that
   would make an error banner visually indistinguishable from a normal branded CTA. Instead, use
   the **container pattern**: a light background tint (`success-container` / `warning-container` /
   `error-container`) with the corresponding darker `on-*-container` color for text and icon.
   Solid `success`/`warning`/`error` fills are reserved for small elements only (a status-badge dot,
   a thin left border, a stepper's disabled state) — never a full-width button or banner background.
3. **`warning` is a single token used everywhere "attention" is needed** — the low-stock badge, any
   caution banner, any input validation warning. Do not introduce a second "accent" amber color for
   decorative use. There is one warning role, one warning color.

`success` (`#1FAE6B`) is a saturated green, `error` (`#B3413A`) a warm brick-red, `warning`
(`#C77B1E`) a burnt orange — all three deliberately hue-distant from the ink-blue primary so they
never get confused with a branded CTA.

## Typography

**Manrope** (700) is used for all headlines — a confident, geometric sans that reads as
"locked-in" and professional without being cold. **Inter** is used for all body copy, labels, and
prices, for maximum legibility in dense product data.

- `price-display` gets the system's **signature treatment**: a solid 3px `ink-blue` underline
  directly beneath the price text (not a background, not a box) — like a certified stamp. This
  makes price the unmistakable focal point of every product card without needing decoration.
- Large headlines automatically downscale for mobile viewports (`headline-lg` → `headline-lg-mobile`)
  to prevent awkward line breaks in Uzbek, which frequently has long compound words.

## Layout & Spacing

4px base-unit, 16px gutter/margin-mobile, unchanged from the prior structural spec — these were
never part of any rejected direction and stay as-is. Product grids are 2-column on mobile.

## Shapes

- **Cards & major containers:** 12px (`rounded-md`) corner radius — "grounded rounded", tactile
  but not childish.
- **Buttons & inputs:** 8px (`rounded-DEFAULT`).
- **Status badges & pills:** fully rounded (`rounded-full`).

No component in this system uses a 30px+ "squircle", a full pill-shaped button, or fully-circular
corners on rectangular containers — pill buttons belonged to the rejected Kutuku direction,
squircles to the rejected Midnight Indigo direction.

## Elevation & Depth

Low-contrast 1px `outline-variant` borders define most boundaries. A soft, diffused shadow
(Blur: 12px, Y: 4px, Opacity: 6% black) is reserved for the variant-selection bottom sheet and any
floating action bar — signifying interactivity without heavy skeuomorphism.

**No glassmorphism anywhere, including the bottom navigation bar.** The bottom nav is always a
fully opaque `paper-white` (light) / `dark-surface` (dark) surface with a 1px top border.

## Components

### Marketplace: Stationery Shop
- **Product Cards:** 1:1 image, category label, product name (2-line clamp), then a footer row
  with the signature underlined price on the left and a single round "+" add-to-cart button
  (minimum 44×44, target 48×48) on the right. No quantity chips on grid cards.
- **Stock badges:** `warning-container` pill ("Oz qoldi", shown when `stock ≤ 5`) or
  `error-container` pill ("Sotuvda yo'q", shown when `stock = 0`) in the card's top-right corner.
  Out-of-stock cards additionally get `grayscale` + reduced opacity on the image and a disabled
  add button.
- **Variant Selector:** a true modal bottom sheet (scrim + sheet above the bottom nav, nav is
  covered), `rounded-xl` top corners. Variants shown as selectable chips; unavailable variants are
  visually disabled (not just unstyled). Price and stock update live as soon as a variant is
  selected. Quantity uses a single stepper with tap-to-edit — no `+1/+5/+10` chips anywhere.
- **Add-to-cart feedback:** button label changes from "Savatga qo'shish" to "Savatga qo'shildi"
  AND shows a small checkmark icon — per the mandatory icon+text rule above, the label change
  alone (or color alone) is not sufficient feedback.
- **Catalog scale (~60 categories, ~1000 variants):** search, category/attribute filters, sorting,
  and pagination are MVP-1 scope, not a later add-on — list/grid screens must be designed for this
  volume from the start (e.g. no client-side "load everything" patterns).

### Navigation & Shell
- **Bottom Navigation:** 5 fixed tabs — Do'kon | Taxi | Home | AI | Profil — opaque, never glass.
  Active tab uses `primary` (light) / `dark-primary` (dark) background on its icon chip.
- **Category chips:** horizontal scroll row, right edge fades via a mask gradient so scrollability
  is visually obvious even when the row is not mid-scroll.

### Skeleton Modules (Taxi & AI, Phase 1 "coming soon")
Simple `surface-container` pulse placeholders, honest "Tez orada" copy — no fake interactive
elements (no fake map, no working-looking address field).

### Feedback & Alerts
- **Toast/banner success:** `success-container` background, `on-success-container` text,
  checkmark icon, e.g. "✓ Savatga qo'shildi".
- **Toast/banner error:** `error-container` background, `on-error-container` text, alert icon,
  always states what happened and what to do next — never a bare color change.
- **Empty states:** an icon, a short explanation, and an action button — never a plain "no data"
  message.
