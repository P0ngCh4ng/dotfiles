#!/usr/bin/env node
/**
 * Track Documentation Updates (PostToolUse Hook)
 *
 * Tracks file modifications and suggests updating documentation when:
 * - 5+ files modified
 * - Database/migration files changed
 * - Major refactoring detected
 */

const fs = require('fs');
const path = require('path');

try {
  // Read tool use input from stdin
  let inputData = '';
  process.stdin.on('data', chunk => {
    inputData += chunk;
  });

  process.stdin.on('end', () => {
    try {
      const data = JSON.parse(inputData);
      const toolName = data.tool_name;
      const toolInput = data.tool_input || {};

      // Only track Edit and Write operations
      if (toolName !== 'Edit' && toolName !== 'Write') {
        console.log(inputData);
        return;
      }

      const projectRoot = process.env.CLAUDE_PROJECT_ROOT || process.cwd();
      const stateFile = path.join(projectRoot, '.claude', 'context', 'mod-tracker.json');

      // Ensure context directory exists
      const contextDir = path.join(projectRoot, '.claude', 'context');
      if (!fs.existsSync(contextDir)) {
        fs.mkdirSync(contextDir, { recursive: true });
      }

      // Load or initialize state
      let state = { modCount: 0, dbModified: false, lastCheck: Date.now() };
      if (fs.existsSync(stateFile)) {
        try {
          state = JSON.parse(fs.readFileSync(stateFile, 'utf8'));
        } catch (e) {
          // Corrupted state, reset
        }
      }

      // Reset counter if last check was > 1 hour ago
      if (Date.now() - state.lastCheck > 3600000) {
        state.modCount = 0;
        state.dbModified = false;
      }

      // Increment modification counter
      state.modCount++;
      state.lastCheck = Date.now();

      // Check if database/migration file was modified
      const filePath = toolInput.file_path || '';
      if (
        filePath.includes('migration') ||
        filePath.includes('schema.prisma') ||
        filePath.includes('schema.sql') ||
        filePath.includes('/models/') ||
        filePath.includes('/database/')
      ) {
        state.dbModified = true;
      }

      // Save updated state
      fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));

      // Check thresholds and suggest updates
      const shouldSuggestArchUpdate = state.modCount >= 5;
      const shouldSuggestDbUpdate = state.dbModified;

      if (shouldSuggestArchUpdate || shouldSuggestDbUpdate) {
        console.error('');
        console.error('[Auto-Doc] 📝 Significant changes detected');

        if (shouldSuggestArchUpdate) {
          console.error('[Auto-Doc]    ' + state.modCount + ' files modified - consider updating architecture docs');
          console.error('[Auto-Doc]    Run: /update-architecture');
        }

        if (shouldSuggestDbUpdate) {
          console.error('[Auto-Doc]    Database/schema changes detected');
          console.error('[Auto-Doc]    Run: /update-database');
        }

        // Reset counters after suggesting
        state.modCount = 0;
        state.dbModified = false;
        fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
      }

      // Pass through original input
      console.log(inputData);

    } catch (error) {
      // On error, pass through input unchanged
      console.log(inputData);
    }
  });

} catch (error) {
  // Silently fail - pass through stdin
  process.stdin.pipe(process.stdout);
}
