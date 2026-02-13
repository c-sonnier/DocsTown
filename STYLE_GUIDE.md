# Playful Geometric — Style Guide

> Stable Grid, Wild Decoration. The content lives in clean, readable areas. The world around it is alive with movement and shape.

## Philosophy

Friendly. Tactile. Pop. Energetic. Feels like a playground or a well-organized sticker book. Invites clicking. Smiles at you.

Modern Memphis—keep the energy, remove the chaos.

### Visual Signatures

- **Primitive Shapes**: Circles, triangles, squares, pill shapes, squiggles as background elements, masks, or icons
- **Hard Shadows**: Offset drop shadows with zero blur — sticker / cut-out paper feel
- **Pattern Fills**: Polka dots, grid lines, diagonal stripes filling shapes or backgrounds
- **Varied Radii**: Mix fully rounded corners with sharp ones for "leaf" shapes or asymmetric blobs

---

## Color Tokens

### Light Mode

| Token              | Value     | Usage                                     |
| ------------------ | --------- | ----------------------------------------- |
| `background`       | `#FFFDF5` | Warm cream page background (paper feel)   |
| `foreground`       | `#1E293B` | Primary text (Slate 800, softer than black) |
| `muted`            | `#F1F5F9` | Subtle backgrounds (Slate 100)            |
| `muted-foreground` | `#64748B` | Secondary text (Slate 500)                |
| `accent`           | `#8B5CF6` | Primary brand — Vivid Violet              |
| `accent-foreground`| `#FFFFFF` | Text on accent backgrounds                |
| `secondary`        | `#F472B6` | Hot Pink — playful pop                    |
| `tertiary`         | `#FBBF24` | Amber/Yellow — optimism                   |
| `quaternary`       | `#34D399` | Emerald/Mint — freshness                  |
| `border`           | `#E2E8F0` | Default borders (Slate 200)               |
| `input`            | `#FFFFFF` | Input backgrounds                         |
| `card`             | `#FFFFFF` | Card backgrounds                          |
| `ring`             | `#8B5CF6` | Focus ring color                          |

### Color Rules

- `accent` for primary actions and CTAs
- `secondary`, `tertiary`, `quaternary` rotate for decorative shapes, icons, and emphasized words — "confetti" effect
- Never rely only on color; always pair with shapes and text labels

---

## Typography

### Font Stacks

| Role     | Family                                | Weights          |
| -------- | ------------------------------------- | ---------------- |
| Headings | `"Outfit", system-ui, sans-serif`     | Bold (700), ExtraBold (800) |
| Body     | `"Plus Jakarta Sans", system-ui, sans-serif` | Regular (400), Medium (500) |

### Type Scale (1.25 — Major Third)

| Level | Size   | Line Height | Weight | Font    |
| ----- | ------ | ----------- | ------ | ------- |
| h1    | 3.052rem (48.83px) | 1.1 | 800 | Outfit |
| h2    | 2.441rem (39.06px) | 1.15 | 700 | Outfit |
| h3    | 1.953rem (31.25px) | 1.2 | 700 | Outfit |
| h4    | 1.563rem (25.00px) | 1.25 | 700 | Outfit |
| h5    | 1.25rem (20.00px)  | 1.3 | 700 | Outfit |
| body  | 1rem (16px)        | 1.6 | 400 | Plus Jakarta Sans |
| small | 0.8rem (12.80px)   | 1.5 | 500 | Plus Jakarta Sans |

---

## Spacing & Layout

### Radius

| Token         | Value    | Usage                          |
| ------------- | -------- | ------------------------------ |
| `radius-sm`   | `8px`    | Small elements, badges         |
| `radius-md`   | `16px`   | Inputs, small cards            |
| `radius-lg`   | `24px`   | Large cards, sections          |
| `radius-full` | `9999px` | Pills, circles, buttons        |

### Special Blob Radii

- **Speech bubble**: `rounded-tl-2xl rounded-tr-2xl rounded-br-2xl rounded-bl-none`
- **Arch**: `rounded-t-full rounded-b-none`

### Border

- Default width: `2px` (chunky)
- Color: `border` token (`#E2E8F0`) or `foreground` (`#1E293B`) for emphasis

### Layout Grid

- Container: `max-w-6xl`
- Section spacing: `py-24` (96px)
- Grid: 12-column logic grouped into big blocks (6/6 or 4/4/4)
- Fill space with patterns, not emptiness

---

## Shadows & Effects

### Hard Shadow System (The "Pop")

| State    | Shadow                         | Transform                     |
| -------- | ------------------------------ | ----------------------------- |
| Default  | `4px 4px 0px 0px #1E293B`     | none                          |
| Hover    | `6px 6px 0px 0px #1E293B`     | `translate(-2px, -2px)`       |
| Active   | `2px 2px 0px 0px #1E293B`     | `translate(2px, 2px)`         |

Zero blur. Solid offset. Always.

### Card Shadows

- Standard: `8px 8px 0px #E2E8F0` (soft hard shadow)
- Featured: `8px 8px 0px #F472B6` (pink shadow)

---

## Textures & Decoration

### Background Patterns

- **Dot Grid**: Small dots in strict formation via `background-image` (radial-gradient or SVG)
- **Squiggles**: SVG paths as section dividers or heading underlines
- **Confetti**: Small SVG shapes (triangles, circles) absolutely positioned behind content blocks

### Decorative Shape Placement

Shapes are **background decoration** — they sit behind content, never obstruct readability. Use `absolute` positioning with `z-index: -1` or similar.

---

## Components

### Buttons

#### Primary ("The Candy Button")

```
Background:    accent (#8B5CF6)
Text:          white, weight 700
Radius:        rounded-full (pill)
Border:        2px solid #1E293B
Shadow:        4px 4px 0px #1E293B
Hover:         translate(-2px, -2px), shadow 6px 6px
Active:        translate(2px, 2px), shadow 2px 2px
Icon:          ArrowRight in white circle inside button
```

#### Secondary

```
Background:    transparent
Text:          foreground
Border:        2px solid #1E293B
Radius:        rounded-full
Shadow:        none
Hover:         bg fills with tertiary (#FBBF24)
```

### Cards ("The Sticker Card")

```
Background:    white
Border:        2px solid #1E293B
Radius:        rounded-xl
Shadow:        8px 8px 0px #E2E8F0 (standard) or #F472B6 (featured)
Hover:         rotate(-1deg), scale(1.02) — wiggle
Title:         Outfit, bold
Icon:          Floating circle div, half-in/half-out of top border
```

### Inputs

```
Background:    white
Border:        2px solid #CBD5E1
Radius:        rounded-lg
Shadow:        4px 4px 0px transparent (hidden)
Focus:         border accent, shadow 4px 4px 0px accent
Label:         Bold, uppercase, small, tracking-wide
```

---

## Section Layouts

### Hero

- Text left, image right
- **Decoration**: Massive yellow circle behind text. Dotted pattern behind image. Image uses blob mask (clip-path or border-radius manipulation)

### Features

- 3-column grid
- **Decoration**: Dashed SVG lines connecting cards in background
- Alternating card header colors: Violet, Pink, Yellow

### Pricing

- Middle card scaled to 1.1
- Yellow star badge "MOST POPULAR" rotated 15deg

---

## Animation & Motion

### Timing

- Default easing: `cubic-bezier(0.34, 1.56, 0.64, 1)` (bouncy overshoot)
- Duration: `300ms` for hover transitions

### Effects

| Effect   | Description                                    |
| -------- | ---------------------------------------------- |
| Pop In   | Scale 0 -> 1 with bounce on entrance           |
| Wiggle   | `rotate: 0deg -> 3deg -> -3deg -> 0deg` on hover |
| Marquee  | Infinite scrolling text for logos/keywords      |
| Lift     | Shadow extends + translate on hover             |
| Press    | Shadow shrinks + translate on active            |

### Reduced Motion

Respect `prefers-reduced-motion`: disable bounce, wiggle, and pop effects. Fall back to simple opacity fades.

---

## Iconography (Lucide React)

- Stroke width: `2.5px` (bold/chunky)
- Line caps: round
- Line joins: round
- **Always enclosed in shapes** — never floating alone
- Typical pattern: white icon inside a colored circle (accent/secondary/tertiary/quaternary)

---

## Responsive

### Mobile Adjustments

- Stack all grids to single column
- Reduce hard shadows to `2px` offset
- Convert horizontal squiggles to vertical dividers
- Buttons: minimum `48px` height for tap targets
- Hide complex floating background shapes that might overlap text

---

## Accessibility

- **Contrast**: Slate 800 on white/cream = AAA compliant
- **Color Independence**: Shapes + text labels always accompany color coding
- **Motion**: Honor `prefers-reduced-motion`
- **Focus**: Thick colored border + hard shadow — high visibility
- **Touch Targets**: Minimum 48px on mobile

---

## CSS Custom Properties Reference

```css
:root {
  /* Colors */
  --color-background: #FFFDF5;
  --color-foreground: #1E293B;
  --color-muted: #F1F5F9;
  --color-muted-foreground: #64748B;
  --color-accent: #8B5CF6;
  --color-accent-foreground: #FFFFFF;
  --color-secondary: #F472B6;
  --color-tertiary: #FBBF24;
  --color-quaternary: #34D399;
  --color-border: #E2E8F0;
  --color-input: #FFFFFF;
  --color-card: #FFFFFF;
  --color-ring: #8B5CF6;

  /* Typography */
  --font-heading: "Outfit", system-ui, sans-serif;
  --font-body: "Plus Jakarta Sans", system-ui, sans-serif;

  /* Radius */
  --radius-sm: 8px;
  --radius-md: 16px;
  --radius-lg: 24px;
  --radius-full: 9999px;

  /* Borders */
  --border-width: 2px;

  /* Shadows */
  --shadow-pop: 4px 4px 0px 0px var(--color-foreground);
  --shadow-pop-hover: 6px 6px 0px 0px var(--color-foreground);
  --shadow-pop-active: 2px 2px 0px 0px var(--color-foreground);
  --shadow-card: 8px 8px 0px var(--color-border);
  --shadow-card-featured: 8px 8px 0px var(--color-secondary);

  /* Animation */
  --ease-bounce: cubic-bezier(0.34, 1.56, 0.64, 1);
  --duration-default: 300ms;
}
```
