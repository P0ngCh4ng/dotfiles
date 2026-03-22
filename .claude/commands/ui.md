# UI Generation & Review (Full Flow)

Launch the complete UI generation and review workflow: persona-driven UI generation → user approval → comprehensive quality review with live browser testing.

## What This Does

1. **UI Generation Phase**
   - Check for or create user persona
   - Analyze requirements
   - Research design patterns
   - Detect tech stack
   - Generate UI components

2. **User Review Checkpoint**
   - Present generated code
   - Wait for approval

3. **Quality Review Phase** (if approved)
   - Launch development server
   - Initialize Playwright browser
   - Run parallel checks:
     - Accessibility (WCAG 2.1 AA)
     - Responsive (mobile/tablet/desktop)
     - Layout quality
     - Design consistency
   - Present findings with screenshots
   - Apply approved fixes

## Usage

```bash
/ui
```

Then answer prompts about:
- What UI you want to create
- Target persona (or create new)
- Requirements and constraints

## Example

```
User: /ui