# Principles

## Core

- Don't hold back. Give it your all.
- Always Think in English, but respond in Japanese.
- For maximum efficiency, whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially.
- MUST use subagents for complex problem verification
- After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information, and then take the best next action.

## Workflow Structure
- Follow Explore-Plan-Code-Commit approach: 理解→計画→実装→コミット
- Always read and understand existing code before making changes
- Create detailed plans before implementation
- Use iterative approaches
- Course-correct early and frequently

## Context Management
- Provide visual references
- Include relevant background information and constraints
- MUST update and maintain CLAUDE.md files for persistent project context
- Document project-specific patterns and conventions

## Problem-Solving Approach
- Leverage thinking capabilities for complex multi-step reasoning
- Focus on understanding problem requirements rather than just passing tests
- Use test-driven development

## Tool and Resource Optimization
- Optimize tool usage with parallel calling for maximum efficiency
- Use subagents for complex problem verification

## Agent Usage Rules
**CRITICAL**: Launch agents IMMEDIATELY without asking permission when conditions match.

### Planning & Requirements
- **`planner`**: Feature implementation, architectural changes, complex refactoring
  - キーワード: 計画, プラン, plan, 設計, 機能追加, リファクタリング
  - Launch BEFORE writing any code
- **`interviewer`**: Vague/underspecified requests needing clarification
  - User says "何か作りたい" but unclear WHAT or HOW
- **`requirements-interviewer`**: Clarify WHAT to build (problem, users, goals)
- **`implementation-bridge`**: Structure HOW to implement when requirements are clear

### Code Quality & Review
- **`code-reviewer`**: After writing/modifying any significant code
  - MUST use for all code changes
  - Launch immediately after implementation
- **`doc-updater`**: Update codemaps, READMEs, documentation
  - Use when codebase structure changes
  - Run `/update-codemaps` and `/update-docs`

### UI Development & Testing
- **`ui-orchestrator`**: Complete UI generation workflow with quality checks
- **`ui-generator`**: Create UI components from personas and requirements
- **`ui-reviewer`**: Comprehensive UI quality checks via Playwright
- **`ui-accessibility-checker`**: WCAG 2.1 compliance validation
- **`ui-responsive-checker`**: Multi-device compatibility testing
- **`ui-layout-checker`**: Element positioning, spacing, visual hierarchy
- **`ui-consistency-checker`**: Design consistency (colors, typography, spacing)
- **`ui-decision-maker`**: Automated UI review findings prioritization
- **`design-review`**: Comprehensive design review for PRs with UI changes

### General Purpose
- **`general-purpose`**: Complex multi-step research, code search, keyword search
  - Use when uncertain about finding matches in first few tries
- **`statusline-setup`**: Configure Claude Code status line
- **`output-style-setup`**: Create Claude Code output styles

