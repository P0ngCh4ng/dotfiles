#!/usr/bin/env node

/**
 * Post-edit hook for Emacs configuration files
 * Automatically verifies Emacs config after editing init.el or elisp files
 */

const { execSync } = require('child_process');
const path = require('path');

let data = '';

process.stdin.on('data', chunk => {
  data += chunk;
});

process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const filePath = input.tool_input?.file_path || '';

    // Check if this is an Emacs configuration file
    const isEmacsConfig =
      filePath.includes('.emacs.d/init.el') ||
      filePath.includes('.emacs.d/elisp/') ||
      filePath.includes('.emacs.d/conf/');

    if (isEmacsConfig) {
      console.error('[Emacs Hook] Detected Emacs config edit: ' + path.basename(filePath));
      console.error('[Emacs Hook] Running verification checks...');

      try {
        // Backup the file first
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
        const backupPath = `${filePath}.backup.${timestamp}`;

        try {
          execSync(`cp "${filePath}" "${backupPath}"`, { encoding: 'utf8' });
          console.error(`[Emacs Hook] ✓ Backup created: ${path.basename(backupPath)}`);
        } catch (backupError) {
          console.error('[Emacs Hook] ⚠ Warning: Could not create backup');
        }

        // Run basic syntax check
        const syntaxCheck = execSync(
          `emacs --batch -l "${filePath}" 2>&1 || true`,
          { encoding: 'utf8', timeout: 10000 }
        );

        // Check for errors in output
        const hasErrors = /error/i.test(syntaxCheck) || /warning/i.test(syntaxCheck);

        if (hasErrors) {
          console.error('[Emacs Hook] ⚠ Verification found issues:');
          console.error(syntaxCheck.trim());
          console.error('[Emacs Hook] Please review and fix these issues');
        } else {
          console.error('[Emacs Hook] ✓ Syntax check passed');
        }

        // Run runtime test
        try {
          const runtimeTest = execSync(
            `emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1 || true`,
            { encoding: 'utf8', timeout: 5000 }
          );

          if (/error/i.test(runtimeTest) || /warning/i.test(runtimeTest)) {
            console.error('[Emacs Hook] ⚠ Runtime test found issues:');
            console.error(runtimeTest.trim());
          } else {
            console.error('[Emacs Hook] ✓ Runtime test passed');
          }
        } catch (runtimeError) {
          console.error('[Emacs Hook] ⚠ Runtime test timed out or failed');
        }

        console.error('[Emacs Hook] Verification complete. Review warnings above if any.');

      } catch (error) {
        console.error('[Emacs Hook] ⚠ Verification failed:', error.message);
      }
    }
  } catch (error) {
    // Silently pass through if there's an error parsing
  }

  // Always pass through the original input
  console.log(data);
});
