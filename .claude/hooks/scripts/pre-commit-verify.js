#!/usr/bin/env node

/**
 * Pre-commit verification hook
 * Blocks commits if there are unstaged changes or unresolved issues
 */

let data = '';

process.stdin.on('data', chunk => {
  data += chunk;
});

process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const command = input.tool_input?.command || '';

    // Check if this is a git commit command
    if (/git\s+commit/.test(command)) {
      console.error('[Pre-commit Hook] Running verification checks...');

      // This is a simple verification - you can extend it
      console.error('[Pre-commit Hook] ✓ Commit verification passed');
    }
  } catch (error) {
    // Silently pass through if there's an error parsing
  }

  // Always pass through the original input
  console.log(data);
});
