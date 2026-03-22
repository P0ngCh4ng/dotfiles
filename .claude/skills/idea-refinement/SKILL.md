---
name: idea-refinement
description: Automatically detects vague or unclear ideas and initiates Socratic dialogue to refine them into concrete requirements. Use when user mentions ideas that lack clear requirements, success criteria, or scope definition.
origin: chang-pong
---

# Idea Refinement Skill

This skill helps transform vague ideas into concrete, actionable requirements through structured Socratic questioning.

## When to Activate

Activate this skill when you detect any of these patterns in user messages:

- **Vague feature requests**: "I want to build a dashboard" (lacks specifics)
- **Unclear goals**: "Make the app better" (no measurable outcome)
- **Solution without problem**: "We need AI" (no problem statement)
- **Missing constraints**: Ideas with no timeline, budget, or scope
- **Ambiguous requirements**: "Add notifications" (what kind? when? to whom?)
- **Brainstorming requests**: "I'm thinking about..." or "What if we..."
- **Early-stage ideas**: Ideas that haven't been validated or scoped

**Examples of trigger phrases:**
- "I want to build/create/add..."
- "I'm thinking about..."
- "What if we..."
- "I need something that..."
- "Can we make..."
- "I have an idea for..."

## Activation Process

When you detect a vague idea:

1. **Acknowledge** the idea positively
2. **Invoke the interviewer router agent** to determine the type of help needed
3. **The router will**:
   - Ask 2-3 questions to detect if user needs WHAT (requirements) or HOW (implementation) help
   - Delegate to the appropriate specialist agent
4. **Produce a refined specification** before any planning or implementation

## How to Use This Skill

### Step 1: Detect Vague Ideas

Look for ideas that are missing:
- **Problem statement**: Why is this needed?
- **User/audience**: Who will use this?
- **Success criteria**: How will we know it works?
- **Constraints**: Timeline, budget, technical limits
- **Scope**: What's in and out of scope?

### Step 2: Initiate Interview

Immediately invoke the `interviewer` router agent using the Task tool:

```
I notice you have an idea that could benefit from some refinement.
Let me ask a few questions to understand what kind of help you need.

[Invoke interviewer agent with user's initial idea]
```

### Step 3: Let the Router Guide

The interviewer router will:
- Ask 2-3 detection questions to understand user's state
- Route to either:
  - **requirements-interviewer** (WHAT to build)
  - **implementation-bridge** (HOW to build)
- The specialist agent will then conduct deep exploration
- Produce a structured summary

### Step 4: Transition to Next Phase

After the interview completes:
- Present the refined idea summary
- Ask user to confirm the understanding
- Suggest next steps (usually `/plan` for implementation planning)

## Key Principles

### DO ✅

- **Act early**: Intervene before jumping into implementation
- **Stay neutral**: Help refine the user's idea, don't replace it
- **Be thorough**: 8-15 questions minimum for complex ideas
- **Focus on WHAT**: Requirements, not implementation details
- **Validate understanding**: Summarize periodically

### DON'T ❌

- **Don't assume**: Always ask instead of guessing
- **Don't rush**: Take time to explore the idea fully
- **Don't propose new features**: Stick to what the user mentioned
- **Don't skip to HOW**: Resist jumping to technical solutions
- **Don't ask multiple questions at once**: One focused question at a time

## Integration with Other Skills/Commands

This skill works best **before** other development activities:

```
Idea Refinement (this skill)
    ↓
/plan (create implementation plan)
    ↓
/tdd (test-driven development)
    ↓
/code-review (review completed code)
```

## Example Activation

**User**: "I want to add a notification system to my app"

**You** (with this skill active):
> I can help with that! Before we dive into implementation, let me ask a few questions to ensure we build exactly what you need.
>
> [Invoke interviewer agent]
>
> **Interviewer**: What problem are you trying to solve with notifications?

**User**: "Users don't know when important events happen"

**Interviewer**: "What kind of events are most important to notify users about?"

... [Interview continues] ...

**Interviewer**:
> # Refined Idea: Event Notification System
>
> ## Problem Statement
> Users miss important events (new messages, status updates, deadlines) because they don't check the app frequently enough.
>
> ## Key Requirements
> 1. Real-time notifications for new messages
> 2. Daily digest for status updates
> 3. Deadline reminders (24h and 1h before)
> 4. User preferences for notification channels (email, push, in-app)
>
> [... rest of summary ...]

**You**: Does this capture what you're looking for? If so, shall we create an implementation plan with `/plan`?

## Success Metrics

This skill is successful when:

- Users have clear, documented requirements before coding starts
- Assumptions are explicitly validated
- Edge cases are identified early
- The scope is well-defined (both in and out)
- Users feel heard and their idea has been improved (not replaced)

## Anti-Patterns to Watch For

⚠️ **Premature Planning**
- Don't invoke `/plan` before requirements are clear
- Symptom: User says "I don't know" to basic questions

⚠️ **Solution Fixation**
- Don't get attached to the user's initial solution
- The real need might be different from what they first described

⚠️ **Scope Creep**
- Don't expand the idea beyond what the user needs
- Keep the interview focused on the stated problem

## Related Skills and Commands

- **Interviewer Router** (`~/.claude/agents/interviewer.md`): The routing agent this skill invokes
- **Requirements Interviewer** (`~/.claude/agents/requirements-interviewer.md`): WHAT specialist
- **Implementation Bridge** (`~/.claude/agents/implementation-bridge.md`): HOW specialist
- **Plan Command** (`/plan`): Next step after idea refinement
- **TDD Workflow** (`/tdd`): Implementation with tests
- **Coding Standards**: Applied during implementation

---

**Remember**: Great software starts with great requirements. This skill ensures we understand WHAT to build before deciding HOW to build it.
