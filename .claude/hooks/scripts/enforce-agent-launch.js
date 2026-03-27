#!/usr/bin/env node
/**
 * Enforce Agent Auto-Launch
 *
 * Reminds Claude Code to launch appropriate agents after tool use:
 * - After Edit/Write: Suggest code-reviewer
 * - Track state to avoid excessive reminders
 *
 * Outputs to stderr so Claude Code sees it.
 */

const fs = require('fs');
const path = require('path');

try {
  const toolName = process.env.TOOL_NAME || 'unknown';
  const stateDir = path.join(process.env.HOME, '.claude', 'local');
  const stateFile = path.join(stateDir, 'agent-reminder-state.json');

  // Ensure state directory exists
  if (!fs.existsSync(stateDir)) {
    fs.mkdirSync(stateDir, { recursive: true });
  }

  // Load state
  let state = { lastReminder: 0, reminderCount: 0 };
  if (fs.existsSync(stateFile)) {
    try {
      state = JSON.parse(fs.readFileSync(stateFile, 'utf-8'));
    } catch (e) {
      // Ignore parse errors
    }
  }

  const now = Date.now();
  const timeSinceLastReminder = now - state.lastReminder;
  const REMINDER_COOLDOWN = 5 * 60 * 1000; // 5 minutes

  // Only remind if cooldown has passed
  if (timeSinceLastReminder < REMINDER_COOLDOWN) {
    // Too soon, skip reminder
    process.exit(0);
  }

  // Tool-specific reminders
  let shouldRemind = false;
  let agentSuggestion = '';

  if (toolName === 'Edit' || toolName === 'Write') {
    shouldRemind = true;
    agentSuggestion = 'code-reviewer';
  } else if (toolName === 'MultiEdit') {
    shouldRemind = true;
    agentSuggestion = 'code-reviewer';
  }

  if (shouldRemind) {
    console.error('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('🤖 AGENT AUTO-LAUNCH REMINDER');
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error(`\n⚠️  Code was modified (${toolName} tool used)`);
    console.error(`\n💡 According to ~/.claude/rules/common/00-session-start.md:`);
    console.error(`   You SHOULD launch the \`${agentSuggestion}\` agent automatically`);
    console.error(`   (No permission needed - auto-launch is REQUIRED)\n`);
    console.error(`Example:`);
    console.error(`   Use Task tool with subagent_type="${agentSuggestion}"\n`);
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Update state
    state.lastReminder = now;
    state.reminderCount += 1;
    fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
  }

  // Always exit 0 (don't block tool use)
  process.exit(0);

} catch (error) {
  console.error('⚠️  Agent launch hook error:', error.message);
  // Don't block on errors
  process.exit(0);
}
