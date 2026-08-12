---
name: Modern Sovereign Finance
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#454652'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#767683'
  outline-variant: '#c6c5d4'
  surface-tint: '#4c56af'
  primary: '#000666'
  on-primary: '#ffffff'
  primary-container: '#1a237e'
  on-primary-container: '#8690ee'
  inverse-primary: '#bdc2ff'
  secondary: '#1b6d24'
  on-secondary: '#ffffff'
  secondary-container: '#a0f399'
  on-secondary-container: '#217128'
  tertiary: '#400003'
  on-tertiary: '#ffffff'
  tertiary-container: '#670007'
  on-tertiary-container: '#ff635a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e0e0ff'
  primary-fixed-dim: '#bdc2ff'
  on-primary-fixed: '#000767'
  on-primary-fixed-variant: '#343d96'
  secondary-fixed: '#a3f69c'
  secondary-fixed-dim: '#88d982'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005312'
  tertiary-fixed: '#ffdad6'
  tertiary-fixed-dim: '#ffb4ac'
  on-tertiary-fixed: '#410003'
  on-tertiary-fixed-variant: '#93000e'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-currency:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
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
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-mobile: 1.25rem
  gutter: 1rem
  stack-sm: 0.5rem
  stack-md: 1rem
  stack-lg: 1.5rem
---

## Brand & Style

This design system is built on the principles of **Privacy-First Minimalism**. It targets a professional audience that demands clarity, security, and precision in financial tracking. The aesthetic is a refined evolution of Material 3, stripping away decorative excess to focus on data legibility and trust.

The visual style is **Corporate Modern** with a lean toward high-end fintech. It utilizes a restrained palette, generous whitespace, and precise alignment to evoke a sense of calm and control over one's finances. The user experience should feel "quiet" yet "powerful," avoiding aggressive marketing patterns in favor of a utility-driven toolset.

## Colors

The palette is anchored by **Deep Navy (#1A237E)**, symbolizing stability and professional integrity. 

- **Primary:** Used for key actions, active states, and branding elements.
- **Semantic Accents:** Income and growth are represented by **Forest Green (#2E7D32)**. Expenses and critical alerts use **Deep Madder (#C62828)**. These colors are used sparingly to ensure they retain their communicative power.
- **Neutrals:** The interface relies on a layered white-on-off-white approach to create structure without heavy lines. Text uses high-contrast charcoal for primary data and a soft gray for metadata and captions.

## Typography

The design system utilizes **Inter** for its exceptional legibility and neutral, systematic tone. 

- **Currency Formatting:** Financial figures (Rupiah) should use the `display-currency` role with a slight negative letter-spacing to appear as a single cohesive unit of information.
- **Hierarchy:** Strong weight differentiation (SemiBold for headers vs. Regular for body) ensures that users can scan complex transaction lists efficiently.
- **Language Localization:** Ensure that the "Rp" prefix in Indonesian formatting is consistently weighted with the numerical value but may use a slightly secondary color to keep the focus on the amount.

## Layout & Spacing

The system follows a **8dp grid system** consistent with modern Android standards. 

- **Grid Model:** A fluid 4-column grid for mobile devices with a fixed **20px (1.25rem) side margin**.
- **Vertical Rhythm:** Elements are stacked using increments of 8px. Use 16px (stack-md) for most component spacing and 24px (stack-lg) for section separation.
- **Safe Areas:** Adhere strictly to system bars (Status Bar and Navigation Bar) to ensure privacy indicators and system gestures are never obstructed.

## Elevation & Depth

This design system uses a **Tonal Layering** approach rather than traditional heavy shadows. Depth is communicated through color and subtle borders:

1.  **Level 0 (Background):** #F8F9FA.
2.  **Level 1 (Cards/Surfaces):** #FFFFFF with a 1px solid #E0E0E0 border.
3.  **Active Elevation:** Only used for floating action buttons or temporary modals, utilizing a very soft, high-diffusion shadow: `0px 4px 12px rgba(0, 0, 0, 0.05)`.

Avoid any inner shadows or skeuomorphic bevels. Surfaces should appear as flat, clean planes of information.

## Shapes

The shape language is **Rounded**, reflecting a modern and approachable feel while maintaining professional structure.

- **Standard Containers:** Cards and input fields use a **16px (1rem)** corner radius.
- **Large Components:** Bottom sheets and prominent dashboard cards use **24px (1.5rem)** for a softer, more premium appearance.
- **Buttons:** Use **full-pill** rounding (100px) to maximize touch-target perception and differentiate actions from informational containers.

## Components

### Buttons
- **Primary:** Deep Navy (#1A237E) background, White text. Fully rounded.
- **Secondary:** Transparent background, Deep Navy border (1px), Deep Navy text.
- **Ghost:** Transparent background, Grey text (#757575). Used for "Batal" or "Lihat Semua" actions.

### Cards & Lists
- **Dashboard Cards:** White background, 16px radius, subtle border. Content should have 16px internal padding.
- **Transaction Items:** Horizontal layout. Icon on the left (contained in a soft-colored circle), title and category stacked in the center, and amount on the far right. Use color coding for amounts (Green for +, Charcoal for -).

### Inputs
- **Text Fields:** Outlined style with 16px corner radius. Labels move to the border on focus (Material 3 style).
- **Currency Input:** Specialized field with a fixed "Rp" prefix and large font size for the numeric value.

### Navigation
- **Bottom Navigation:** Uses the Material 3 tonal indicator (a pill shape behind the active icon). Icons are thin-line weights (1.5pt to 2pt).
- **Tabs:** Text-only tabs with a primary-colored underline indicator for the active state.

### Specialized Components
- **Privacy Shield:** A custom overlay or blurred state for sensitive balance information, toggled by a small eye icon.
- **Transaction Badges:** Small, low-saturation chips for categories (e.g., "Makan & Minum", "Transportasi").