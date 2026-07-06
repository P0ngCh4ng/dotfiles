#!/usr/bin/env node
/**
 * Track Documentation Updates (PostToolUse Hook)
 *
 * Watches for significant file modifications and suggests doc updates.
 * Reads tool input from stdin to detect which file was changed.
 */

const fs = require('fs');
const path = require('path');

let inputData = '';
const timeout = setTimeout(() => process.exit(0), 3000); // guard against stdin hang

process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => { inputData += chunk; });
process.stdin.on('end', () => {
  clearTimeout(timeout);
  try {
    const data = JSON.parse(inputData);
    const toolName = data.tool_name;
    if (toolName !== 'Edit' && toolName !== 'Write') return;

    const projectRoot = process.env.CLAUDE_PROJECT_ROOT || process.cwd();
    const stateFile = path.join(projectRoot, '.claude', 'context', 'mod-tracker.json');
    const contextDir = path.dirname(stateFile);

    if (!fs.existsSync(contextDir)) fs.mkdirSync(contextDir, { recursive: true });

    let state = { modCount: 0, dbModified: false, lastCheck: Date.now() };
    try { state = JSON.parse(fs.readFileSync(stateFile, 'utf8')); } catch (_) {}

    // Reset counter if last check was > 1 hour ago
    if (Date.now() - state.lastCheck > 3600000) {
      state.modCount = 0;
      state.dbModified = false;
    }

    state.modCount++;
    state.lastCheck = Date.now();

    const filePath = data.tool_input?.file_path || '';
    if (
      filePath.includes('migration') ||
      filePath.includes('schema.prisma') ||
      filePath.includes('schema.sql') ||
      filePath.includes('/models/') ||
      filePath.includes('/database/')
    ) {
      state.dbModified = true;
    }

    fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));

    if (state.modCount >= 5) {
      console.error(`[Auto-Doc] ${state.modCount} files modified - consider: /update-architecture`);
      state.modCount = 0;
      state.dbModified = false;
      fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
    } else if (state.dbModified) {
      console.error('[Auto-Doc] Schema/migration changed - consider: /update-database');
      state.dbModified = false;
      fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
    }
  } catch (_) {
    // Silently fail
  }
});
