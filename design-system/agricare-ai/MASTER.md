# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** AgriCare AI
**Generated:** 2026-08-25 11:21:00
**Category:** Agriculture advisory mobile app
**Visual direction:** Material 3 interaction foundation + Organic Biophilic visual language

---

## Global Rules

### Color Palette

The app uses a white light mode and a very dark gray dark mode. Accent colors are semantic signals, not page backgrounds.

| Semantic role | Light mode | Dark mode | CSS variables |
|---------------|------------|-----------|---------------|
| Primary / healthy / CTA | `#3B6D11` | `#97C459` | `--color-primary`, `--color-primary-dark` |
| Brand / harvest accent | `#B8931B` | `#E8B923` | `--color-brand`, `--color-brand-dark` |
| Info / neutral action | `#185FA5` | `#378ADD` | `--color-info`, `--color-info-dark` |
| Warning / attention | `#854F0B` | `#EF9F27` | `--color-warning`, `--color-warning-dark` |
| Danger / disease alert | `#A32D2D` | `#E24B4A` | `--color-danger`, `--color-danger-dark` |
| Neutral text/border | `#888780` | `#B8B7AE` | `--color-neutral`, `--color-neutral-dark` |
| Background | `#FFFFFF` | `#1C1D1A` | `--color-background`, `--color-background-dark` |
| Surface/card | `#FFFFFF` | `#272923` | `--color-surface`, `--color-surface-dark` |
| Main text | `#191D16` | `#F3F5EE` | `--color-foreground`, `--color-foreground-dark` |
| Border | `#D9DED2` | `#484C42` | `--color-border`, `--color-border-dark` |

### Bottom navigation

The bottom navigation is a distinct dark-green control surface, not a white card:

- Bar: `#275300` (`--color-nav`), with white/soft-green labels and icons.
- Active item: white circular icon surface with a `#3B6D11` border and dark-green icon.
- The active circle may use the existing rolling transition, but must settle within 400ms.
- Keep a visible label under every icon; do not rely on the icon or color alone.

### Contextual surfaces

| Context | Light mode | Dark mode | Usage |
|---------|------------|-----------|-------|
| Info surface | `#E6F1FB` | `#1D2A36` | Chatbot/info card background |
| Reminder surface | `#FAEEDA` | `#3A2A16` | Reminder and medium-confidence context |
| Brand surface | `#FBF3D2` | `#3A3014` | Logo/splash/season badge only |

**Color principles:**

- Green is always the primary action color, including the main “Capture diagnosis photo” CTA and selected tabs in both Plant and Animal tabs.
- Both Plant and Animal use the same functional color system; only content and imagery change.
- Yellow is a brand/harvest accent for logo, splash screen, season and harvest badges; it is never an alert color.
- Blue is for links, secondary actions and neutral information.
- Amber is for reminders and medium-confidence results.
- Red is reserved for urgent warnings, suspected outbreaks and destructive actions.
- Tab changes use selected state (underline, subtle surface, weight) rather than a different color theme.
- Color is never the only signal: pair it with text, icon and/or status label. This is mandatory when a harvest badge and warning badge are adjacent.
- `#888780` is suitable for borders and low-priority metadata, not normal body text on white.

**Flutter theme implementation:**

```dart
// Canonical tokens live in apps/mobile_flutter/lib/theme/app_theme.dart.
AppColors.primary;
AppColors.info;
AppColors.warning;
AppColors.danger;
AppSpacing.lg; // 16dp
AppRadii.md;   // 16dp
```

Reusable Flutter components live in `apps/mobile_flutter/lib/widgets` and include
`AppCard`, `FeatureCard`, `StatusChip`, `AsyncStateView`, `AppSearchField`,
`ChatBubble` and `CitationChip`. Features must use these components instead of
redefining equivalent card, loading, error or status styles locally.

### Style rules

- Use Material 3 hierarchy, touch targets and accessibility semantics.
- Use organic warmth through soft tonal surfaces, not decorative gradients or excessive illustrations.
- Cards use `12–16px` radius; buttons and inputs use `8–12px`; only badges/chips are fully pill-shaped.
- One primary CTA per screen. Secondary actions use blue or tonal surfaces.
- Avoid border-heavy layouts. Prefer surface layers, spacing and clear content grouping.
- Keep danger red and warning orange semantic; never use them as brand decoration.

### Typography

- **Heading Font:** Be Vietnam Pro
- **Body Font:** Noto Sans
- **Mood:** vietnamese, international, readable, clean, multilingual, accessible
- **Google Fonts:** [Be Vietnam Pro + Noto Sans](https://fonts.google.com/share?selection.family=Be+Vietnam+Pro:wght@300;400;500;600;700|Noto+Sans:wght@300;400;500;600;700)

The mobile app intentionally uses the platform font stack to keep the bundle
small, work offline and preserve native text rendering. Typography is controlled
through Flutter `TextTheme` roles rather than remote font loading.

### Spacing Variables

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` / `0.25rem` | Tight gaps |
| `--space-sm` | `8px` / `0.5rem` | Icon gaps, inline spacing |
| `--space-md` | `16px` / `1rem` | Standard padding |
| `--space-lg` | `24px` / `1.5rem` | Section padding |
| `--space-xl` | `32px` / `2rem` | Large gaps |
| `--space-2xl` | `48px` / `3rem` | Section margins |
| `--space-3xl` | `64px` / `4rem` | Hero padding |

### Shadow Depths

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Subtle lift |
| `--shadow-md` | `0 4px 6px rgba(0,0,0,0.1)` | Cards, buttons |
| `--shadow-lg` | `0 10px 15px rgba(0,0,0,0.1)` | Modals, dropdowns |
| `--shadow-xl` | `0 20px 25px rgba(0,0,0,0.15)` | Hero images, featured cards |

---

## Component Specs

### Buttons

```css
/* Primary Button */
.btn-primary {
  background: #3B6D11;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}

.btn-primary:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

/* Secondary Button */
.btn-secondary {
  background: transparent;
  color: #185FA5;
  border: 2px solid #185FA5;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}
```

### Cards

```css
.card {
  background: #F7F8F4;
  border-radius: 12px;
  padding: 24px;
  box-shadow: var(--shadow-md);
  transition: all 200ms ease;
  cursor: pointer;
}

.card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}
```

### Inputs

```css
.input {
  padding: 12px 16px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 200ms ease;
}

.input:focus {
  border-color: #3B6D11;
  outline: none;
  box-shadow: 0 0 0 3px #3B6D1120;
}
```

### Modals

```css
.modal-overlay {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

.modal {
  background: white;
  border-radius: 16px;
  padding: 32px;
  box-shadow: var(--shadow-xl);
  max-width: 500px;
  width: 90%;
}
```

### Screen mapping

| Screen | Element | Color |
|--------|---------|-------|
| Login / OTP | Logo circle background | Brand yellow `#B8931B` |
| Login / OTP | Continue / Confirm button | Primary green `#3B6D11` |
| Home — both tabs | Selected tab | Primary green `#3B6D11` with underline/subtle surface |
| Home — both tabs | Capture diagnosis photo CTA | Primary green `#3B6D11` |
| Home — both tabs | Chatbot advice card | Info blue `#185FA5`, surface `#E6F1FB` |
| Home — both tabs | Reminder card | Earth amber `#854F0B`, surface `#FAEEDA` |
| Diagnosis result | Serious disease alert banner | Danger red `#A32D2D` |
| Diagnosis result | Medium confidence percentage | Earth amber `#854F0B` |
| Season/harvest | Season or harvest badge | Brand yellow only, with text/icon |

Do not recolor the full app by tab. Plant and Animal screens share the same primary green, info blue, warning amber, danger red and brand yellow tokens.

---

## Style Guidelines

**Style:** AI-Native UI

**Keywords:** Chatbot, conversational, voice, assistant, agentic, ambient, minimal chrome, streaming text, AI interactions

**Best For:** AI products, chatbots, voice assistants, copilots, AI-powered tools, conversational interfaces

**Key Effects:** Typing indicators (3-dot pulse), streaming text animations, pulse animations, context cards, smooth reveals

### Page Pattern

**Pattern Name:** App Store Style Landing

- **Conversion Strategy:** Show real screenshots. Include ratings (4.5+ stars). QR code for mobile. Platform-specific CTAs.
- **CTA Placement:** Download buttons prominent (App Store + Play Store) throughout
- **Section Order:** 1. Hero with device mockup, 2. Screenshots carousel, 3. Features with icons, 4. Reviews/ratings, 5. Download CTAs

---

## Anti-Patterns (Do NOT Use)

- ❌ Complex shadows
- ❌ 3D effects

### Additional Forbidden Patterns

- ❌ **Emojis as icons** — Use SVG icons (Heroicons, Lucide, Simple Icons)
- ❌ **Missing cursor:pointer** — All clickable elements must have cursor:pointer
- ❌ **Layout-shifting hovers** — Avoid scale transforms that shift layout
- ❌ **Low contrast text** — Maintain 4.5:1 minimum contrast ratio
- ❌ **Instant state changes** — Always use transitions (150-300ms)
- ❌ **Invisible focus states** — Focus states must be visible for a11y

---

## Pre-Delivery Checklist

Before delivering any UI code, verify:

- [ ] No emojis used as icons (use SVG instead)
- [ ] All icons from consistent icon set (Heroicons/Lucide)
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px
- [ ] No content hidden behind fixed navbars
- [ ] No horizontal scroll on mobile
