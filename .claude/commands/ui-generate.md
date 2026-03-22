# UI Generation

Generate UI components based on user personas and requirements using research-backed design patterns.

## What This Does

1. Check for existing persona or create new one
2. Analyze requirements and constraints
3. Research design patterns via web search
4. Detect project's tech stack
5. Generate UI components with:
   - Proper accessibility (WCAG 2.1 AA)
   - Responsive design
   - TypeScript types (if applicable)
   - Component documentation

## Usage

```bash
/ui-generate
```

Then provide:
- What UI component/feature you need
- Target users (or describe persona)
- Any specific requirements

## Example

```
User: /ui-generate
Assistant: I'll help generate UI components. What would you like to create?

User: A login form for a marketing dashboard
Assistant: Great! Let me check if you have a persona defined for marketing users...

[Creates persona if needed]
[Detects React + Tailwind]
[Researches accessible login form patterns]
[Generates LoginForm component with proper labels, ARIA, focus management]
```

## Output

- Generated component files
- Persona definition (saved to `.claude/personas/`)
- Design decisions documentation
- Recommendation to run `/ui-review` for quality check
