#!/usr/bin/env node
/**
 * Enforce Agent Auto-Launch
 * Outputs a short directive every time code is modified.
 */

const toolName = process.env.TOOL_NAME || 'unknown';

if (['Edit', 'Write', 'MultiEdit'].includes(toolName)) {
  console.error('[RULE] Code modified. NOW launch code-reviewer agent automatically.');
  console.error('[RULE] Call: Agent({subagent_type:"code-reviewer", description:"Review changes", prompt:"Review the recent code changes for quality, security, and correctness."})');
}
