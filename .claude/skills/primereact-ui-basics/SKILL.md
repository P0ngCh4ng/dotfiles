---
name: primereact-ui-basics
description: Essential UI/UX standards for PrimeReact - ensures usable, accessible, consistent interfaces
origin: chang-pong
version: 2.0
---

# PrimeReact UI Design Essentials

**Goal**: Usable, accessible, consistent PrimeReact UIs in any project (SPA, admin, internal tools).

## When to Use
- Building/modifying PrimeReact UI
- Creating forms, dialogs, tables, layouts
- Any React component using PrimeReact

---

## Core Rules

### 1. Component First
Use PrimeReact components, not raw HTML:
- `Button`, `InputText`, `Dropdown`, `DataTable`, `Dialog`, `Toast`
- Leverage props (`size`, `severity`, `loading`) over custom CSS

### 2. Critical Sizes (WCAG + Material Design)
**Touch Targets**: 44×44px minimum (WCAG), 48×48px ideal (Material)
- Buttons/controls: **36-48px** height minimum
- Never: `height < 32px`, `padding: 0`, or tiny text

**Typography**:
- Body: **16px** (1rem) minimum for readability
- Headings: **18-24px** (never smaller than body)
- Avoid: `font-size < 14px` (except dense data tables)
- Line height: **1.5** minimum (WCAG 1.4.12)

**Spacing** (8px grid system):
- Label → Control: **4-8px**
- Form fields: **12-16px** vertical
- Sections: **24-32px**
- Interactive elements: **8px** margin minimum (prevent mis-taps)
- Container padding: **16px+** (avoid edge-touching)

### 3. Mobile-First & Responsive
- Design for smallest screen first (2025: mobile traffic dominates)
- Test layouts at 320px, 768px, 1024px, 1440px
- Stack elements vertically on mobile, horizontal on desktop

### 4. Accessibility (WCAG 2.1 AA)
- **Labels required** (not just placeholders)
- **Color contrast**: 4.5:1 text, 3:1 UI components
- **Keyboard nav**: All actions reachable via Tab/Enter/Space
- **Focus visible**: Clear focus indicators on interactive elements
- **ARIA**: PrimeReact handles most; verify custom components

### 5. Forms & Validation
- **Labels always visible** (placeholders = hints only)
- **Group related fields** (Card, Panel, or headings)
- **Inline validation** near affected field (not just top)
- **Clear error messages** (not "Error occurred")
- **Disable during submit** + show loading state

### 6. Consistency Beats Creativity
- **Same control heights** in same row (InputText + Dropdown = same px)
- **Primary action right**, cancel left (or consistently reversed)
- **Severity prop** for actions: `danger` for destructive, default for primary
- **Empty states** with helpful message ("No data" + "Create new" action)

---

## Common Mistakes (Avoid These)

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| Button `height: 28px` | Min 36px, ideally 44-48px |
| `font-size: 12px` body text | 16px minimum |
| Zero margin between inputs | 12-16px spacing |
| Placeholder instead of label | Visible label + placeholder hint |
| Generic "Error" message | "Email format invalid" |
| Mixing 40px Dropdown + 32px Input | Same height via props/class |
| Desktop-only design | Mobile-first responsive |
| Slow page loads | Optimize images, lazy load tables |

---

## Self-Check Checklist

Before output, verify:
- [ ] All buttons/inputs ≥ 36px height
- [ ] Body text ≥ 16px, headings ≥ 18px
- [ ] Spacing: 12-16px between fields, 8px between interactive elements
- [ ] Labels present (not just placeholders)
- [ ] Controls in same row have consistent height
- [ ] Primary actions clearly visible
- [ ] Mobile responsive (test at 320px)
- [ ] Keyboard navigable (Tab order logical)
- [ ] Color contrast ≥ 4.5:1 for text

---

## Quick Reference

```typescript
// ✅ Good
<Button label="Save" className="w-full md:w-auto" /> // 44px default
<InputText className="w-full" />                     // Same height as Dropdown
<label htmlFor="email">Email</label>                 // Visible label
<span className="p-error">{error}</span>             // Near field

// ❌ Bad
<button style={{padding:0, height:24}}>Save</button> // Too small
<input placeholder="Email" />                         // No label
<div style={{fontSize:11}}>Info</div>                // Too small
<Button /><Button />                                  // No spacing
```

---

**Remember**: This is minimum usability. Layer project styles on top, but never violate size/spacing/accessibility rules.
