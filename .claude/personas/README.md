# UI Personas Management

This directory stores user personas used by the UI generation system to create persona-aligned UI components.

## What Are Personas?

Personas are fictional representations of your target users, including:
- Demographics (age, occupation, tech skill level)
- Goals and motivations
- UI preferences and accessibility needs
- Devices and contexts
- Pain points

## Persona Schema

```json
{
  "id": "unique-id",
  "name": "Full Name",
  "age": 35,
  "occupation": "Job Title",
  "tech_skill": "初級|中級|上級",
  "goals": [
    "Primary goal",
    "Secondary goal"
  ],
  "ui_preferences": {
    "simplicity": "高|中|低",
    "color_preference": "Description",
    "font_size": "大きめ|標準|小さめ",
    "preferred_layouts": ["layout-type-1", "layout-type-2"]
  },
  "accessibility_needs": [
    "High contrast",
    "Large touch targets (minimum 44x44px)",
    "Clear labels"
  ],
  "devices": ["Device 1", "Device 2"],
  "pain_points": [
    "Pain point 1",
    "Pain point 2"
  ],
  "context": "When and where they use the app"
}
```

## Example Persona

```json
{
  "id": "persona-marketing-manager",
  "name": "田中太郎",
  "age": 35,
  "occupation": "マーケティングマネージャー",
  "tech_skill": "中級",
  "goals": [
    "データを素早く可視化して意思決定したい",
    "チームとレポートを簡単に共有したい"
  ],
  "ui_preferences": {
    "simplicity": "高",
    "color_preference": "落ち着いた色（ビジネス向け）",
    "font_size": "標準",
    "preferred_layouts": ["card-based", "dashboard-grid"]
  },
  "accessibility_needs": [
    "明確なラベルとボタン",
    "十分なコントラスト（オフィスの明るい照明下で見やすい）"
  ],
  "devices": ["MacBook Pro 14\"", "iPhone 13"],
  "pain_points": [
    "複雑なナビゲーションで目的の機能にたどり着けない",
    "グラフが小さくて詳細が見えない"
  ],
  "context": "主にオフィスのデスクトップで使用、時々移動中にモバイルでチェック"
}
```

## How Personas Are Used

### 1. UI Generation
When you run `/ui-generate`, the system:
1. Checks for existing personas in `personas.json`
2. If none exist, creates one based on your requirements
3. Uses persona preferences to inform design decisions:
   - **Tech skill 初級** → Simpler UI, more guidance
   - **Large touch targets** → min-w-[44px] min-h-[44px]
   - **High contrast** → WCAG AA+ contrast ratios

### 2. UI Review
When you run `/ui-review`, the system:
- Uses persona's accessibility needs to prioritize checks
- Tests on persona's devices (viewport sizes)
- Validates against persona's preferences

## Managing Personas

### Creating a New Persona

**Option 1**: Let the UI Generator create one
```bash
/ui-generate
# System will ask about target users and create persona
```

**Option 2**: Manually add to `personas.json`
```json
{
  "personas": [
    {
      "id": "your-persona-id",
      "name": "Name",
      // ... other fields
    }
  ]
}
```

### Editing Personas

Edit `personas.json` directly to:
- Update user needs
- Add new accessibility requirements
- Adjust preferences based on user feedback

### Using Specific Persona

When generating UI:
```
User: /ui-generate
Assistant: I found 3 personas. Which should I design for?
1. 田中太郎 (Marketing Manager, 初級)
2. 佐藤花子 (Data Analyst, 上級)
3. 鈴木一郎 (Executive, 初級)

User: 1
Assistant: Designing for 田中太郎...
```

## Best Practices

### 1. Base on Real Users
- Interview actual users
- Analyze user research data
- Validate assumptions with user testing

### 2. Keep Personas Focused
- 1-3 primary personas for most projects
- Each persona represents a distinct user segment
- Avoid too many personas (analysis paralysis)

### 3. Update Regularly
- Review personas quarterly
- Update based on user feedback
- Retire outdated personas

### 4. Document Design Decisions
The UI generation system logs:
```markdown
Design Decision: Used large buttons (min-h-[44px])
Reason: Persona '田中太郎' requires large touch targets
WCAG: Meets 2.5.5 (Target Size - Level AAA)
```

## Tech Skill Levels

| Level | Description | UI Implications |
|-------|-------------|-----------------|
| 初級 | Beginner, non-technical | Simple layouts, explicit labels, guided workflows |
| 中級 | Intermediate, some tech familiarity | Balanced complexity, keyboard shortcuts available |
| 上級 | Advanced, power users | Dense layouts, advanced features, customization |

## Accessibility Needs Examples

```json
{
  "accessibility_needs": [
    "Screen reader compatibility (ARIA labels)",
    "High contrast (WCAG AAA)",
    "Keyboard-only navigation",
    "Large touch targets (44x44px minimum)",
    "Clear focus indicators",
    "Reduced motion (prefers-reduced-motion)",
    "Color-blind friendly palette"
  ]
}
```

## Device Considerations

Based on persona devices, the system tests:
- **iPhone 13** → 390x844px viewport
- **iPad** → 768x1024px viewport
- **MacBook Pro 14"** → 1512x982px viewport (scaled)

## Integration with Design Review

Personas are automatically referenced during:
- `/design-review` - Validates against persona preferences
- `/ui-review` - Tests on persona's devices
- `/ui` - Full persona-driven generation + review

---

**Note**: Personas are project-specific. For global personas across projects, contact the team about extending the persona system to `~/.claude/personas/`.
