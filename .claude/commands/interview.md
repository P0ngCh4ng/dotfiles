---
description: Launch Socratic interview session to refine vague ideas into concrete requirements through structured questioning. Use before planning or implementing features.
---

# Interview Command

This command launches an intelligent interview session that automatically detects whether you need help with **WHAT** to build (requirements) or **HOW** to build it (implementation), then routes you to the right specialist.

## What This Command Does

1. **Smart Detection** - Asks 2-3 questions to understand what kind of help you need
2. **Auto-Routing** - Routes you to either:
   - **WHAT Interview** (Requirements Clarification) - when you're unclear on what to build
   - **HOW Interview** (Implementation Structuring) - when you know what but need help organizing how
3. **Focused Questions** - One question at a time to explore deeply
4. **Structured Output** - Delivers clear documentation (requirements or implementation plan)
5. **Next Steps** - Guides you to the right next action

## When to Use

Use `/interview` when:

- You have a vague idea that needs refinement (WHAT help)
- You know what to build but not sure how to structure implementation (HOW help)
- Requirements are unclear or incomplete
- You have steps in mind but they're scattered or disconnected
- You want to explore different approaches before committing
- You're unsure about technical implementation
- Before using `/plan` to create a detailed implementation plan

## How It Works

### Phase 0: Smart Detection (2-3 questions)

The router asks quick questions to understand your state:

1. "何を実現したいか、一言で教えてください"
2. "それは誰のどんな問題を解決しますか？"
3. "実現に必要なステップは思いついていますか？"

**Then automatically routes you to:**

### Path A: WHAT Interview (Requirements Clarification)

**When:** You're unclear on what to build, who it's for, or why it's needed

**Process:**
1. Context Discovery - Understand trigger and background
2. Requirement Exploration - Dig into core needs and goals
3. Clarification - Surface edge cases and priorities
4. Validation & Summary

**Output:**
- Problem statement
- Key requirements
- Constraints
- Success criteria
- 2-3 viable approaches
- Out of scope items

### Path B: HOW Interview (Implementation Structuring)

**When:** You know what to build but need help structuring how

**Process:**
1. Step Extraction - Get steps out of your head easily
2. Dependency Mapping - Understand connections and order
3. Gap Identification - Find missing pieces
4. Technical Investigation - Research unclear implementations
5. Finalization & Structuring

**Output:**
- Structured implementation steps
- Dependency flow diagram
- Knowledge gaps with researched solutions
- Parallel work opportunities
- Critical path
- Estimated timeline

## Example Usage

```
User: /interview

Interviewer: I'm here to help refine your idea through some questions.
What would you like to explore today?

User: I want to build a dashboard for my app

Interviewer: What problem are you trying to solve with this dashboard?

User: Users can't see their activity and metrics

Interviewer: What specific metrics matter most to your users?

User: Daily usage, total points, and leaderboard ranking

... [Interview continues] ...

Interviewer:
# Refined Idea: Gamified Activity Dashboard

## Problem Statement
Gamers can't track their progress or compare performance with friends,
reducing engagement and competitive motivation.

## Key Requirements
1. Display user's leaderboard ranking (primary metric)
2. Show daily usage and total points (secondary metrics)
3. Compare with friends' rankings
4. Fallback to global top 10 if no friends
5. Mobile-friendly interface

## Constraints
- Must work on mobile devices
- Near real-time updates preferred (not critical)

## Success Criteria
- Users can view their ranking within 2 seconds of loading
- Clear comparison with friends or global leaderboard
- Increased engagement (measured by return visits)

## Viable Approaches

### Option A: Server-Side Rendering with Periodic Refresh
- **Pros**: Simple, reliable, low server cost
- **Cons**: Not real-time, users must refresh manually
- **Best for**: MVP, budget-conscious projects

### Option B: WebSocket-Based Live Updates
- **Pros**: Real-time, engaging user experience
- **Cons**: Higher server costs, more complex
- **Best for**: High-engagement apps with active users

## Out of Scope
- Historical trend charts (future v2 feature)
- In-depth analytics beyond the 3 core metrics

## Next Steps
- Create implementation plan with `/plan`

Does this capture what you're looking for?
```

## Important Notes

### Interview Best Practices

- **Be patient**: The interviewer asks one question at a time (not overwhelming)
- **Be honest**: If you don't know something, say so
- **Think deeply**: Take time to consider each question
- **Challenge back**: If a question doesn't make sense, ask for clarification
- **Expect 8-15 questions**: Thorough exploration takes time

### What to Expect

The interviewer will:
- ✅ Ask focused, open-ended questions
- ✅ Build on your answers (not propose new ideas)
- ✅ Stay at the requirements level (WHAT, not HOW)
- ✅ Gently challenge assumptions
- ✅ Present 2-3 approaches when helpful

The interviewer will NOT:
- ❌ Ask multiple questions at once
- ❌ Jump to implementation details
- ❌ Propose features you didn't mention
- ❌ Rush through the process

## Integration with Other Commands

Typical workflow:

```
/interview (this command)
    ↓
Review refined idea summary
    ↓
/plan (create implementation plan)
    ↓
/tdd (implement with tests)
    ↓
/code-review (review completed code)
```

## When NOT to Use

Skip `/interview` if:
- You already have clear, documented requirements
- You're fixing a specific bug (not exploring an idea)
- You've already been through this process for the same feature
- You just need to implement something straightforward

## Tips for a Great Interview

1. **Start broad**: Begin with the problem, not the solution
2. **Provide context**: Share relevant background when asked
3. **Give examples**: Real-world scenarios help clarify needs
4. **Think out loud**: Share your reasoning, not just answers
5. **Be open**: Sometimes the best solution differs from your initial idea

## Architecture

This command works with multiple specialized agents:

```
/interview (entry point)
    ↓
Interviewer Router (detection & routing)
    ↓
├─ Requirements Interviewer (WHAT specialist)
│  └─ Clarifies problems, users, goals, success criteria
│
└─ Implementation Bridge (HOW specialist)
   └─ Extracts steps, maps dependencies, researches solutions
```

## Related Components

- **Interviewer Router** (`~/.claude/agents/interviewer.md`): Smart detection and routing
- **Requirements Interviewer** (`~/.claude/agents/requirements-interviewer.md`): WHAT specialist
- **Implementation Bridge** (`~/.claude/agents/implementation-bridge.md`): HOW specialist
- **Idea Refinement Skill** (`~/.claude/skills/idea-refinement/`): Auto-detects vague ideas
- **Plan Command** (`/plan`): Next step - creates detailed implementation plan

---

**Remember**: Great software starts with clarity. This command helps you achieve clarity on both WHAT to build and HOW to structure it.

Ready to refine your idea? Just type `/interview` and the system will guide you!
