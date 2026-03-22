# UI Quality Review

Run comprehensive UI quality review using live browser testing with Playwright MCP.

## What This Does

1. **Setup**
   - Detect and start dev server if needed
   - Initialize Playwright browser
   - Navigate to your UI

2. **Parallel Quality Checks**
   - **Accessibility**: WCAG 2.1 AA compliance, keyboard navigation, screen reader support, color contrast
   - **Responsive**: Mobile/tablet/desktop layouts, touch targets, content reflow
   - **Layout**: Element overlaps, spacing consistency, alignment, visual hierarchy
   - **Consistency**: Color palette, typography, component styles, design system adherence

3. **Results**
   - Detailed findings with screenshots
   - Auto-fix vs. approval-required categorization
   - Priority recommendations
   - Before/after comparisons

## Usage

```bash
/ui-review
```

## Requirements

- Development server running (or will be started automatically)
- Playwright installed (or will be installed automatically)

## Example

```
User: /ui-review
Assistant: Starting UI quality review...

✓ Dev server detected at http://localhost:3000
✓ Browser initialized
✓ Running 4 parallel checks...

## Review Results

**Summary**: 23 issues found
- Critical: 3 (missing labels, keyboard traps)
- High: 8 (contrast, touch targets)
- Medium: 10 (spacing, alignment)
- Low: 2 (optimizations)

**Auto-Fix Ready (12 issues)**:
- Add missing alt attributes
- Fix color contrast
- Increase touch targets

**Requires Approval (8 issues)**:
- Layout adjustments
- Design system updates

**Screenshots**: Saved to `.claude/ui-review-2026-03-04/`
```

## Output

- Comprehensive review report
- Screenshots from multiple viewports
- Auto-fix recommendations
- Manual fix suggestions with code examples
- Verification results after fixes
