#!/usr/bin/env node

/**
 * Post-edit hook for Emacs configuration files
 * Automatically verifies Emacs config after editing init.el or elisp files
 * Performs 5 comprehensive checks and attempts auto-fix
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

let data = '';

process.stdin.on('data', chunk => {
  data += chunk;
});

// Run all 5 verification checks
function runAllVerificationChecks(filePath) {
  const results = {
    syntaxCheck: { passed: false, output: '', errors: [], warnings: [] },
    runtimeTest: { passed: false, output: '', errors: [], warnings: [] },
    messagesCheck: { passed: false, output: '', errors: [], warnings: [] },
    byteCompile: { passed: false, output: '', errors: [], warnings: [] },
    packageCheck: { passed: false, output: '', errors: [], warnings: [] }
  };

  // 1. Syntax Check
  try {
    const output = execSync(
      `emacs --batch -l "${filePath}" 2>&1 || true`,
      { encoding: 'utf8', timeout: 10000 }
    );
    results.syntaxCheck.output = output;
    results.syntaxCheck.errors = extractErrors(output);
    results.syntaxCheck.warnings = extractWarnings(output);
    results.syntaxCheck.passed = results.syntaxCheck.errors.length === 0;
  } catch (err) {
    results.syntaxCheck.output = err.message;
    results.syntaxCheck.errors.push('Syntax check failed: ' + err.message);
  }

  // 2. Runtime Test
  try {
    const output = execSync(
      `emacs --eval "(run-with-timer 3 nil #'kill-emacs)" 2>&1 || true`,
      { encoding: 'utf8', timeout: 5000 }
    );
    results.runtimeTest.output = output;
    results.runtimeTest.errors = extractErrors(output);
    results.runtimeTest.warnings = extractWarnings(output);
    results.runtimeTest.passed = results.runtimeTest.errors.length === 0;
  } catch (err) {
    results.runtimeTest.output = err.message;
    results.runtimeTest.errors.push('Runtime test failed: ' + err.message);
  }

  // 3. Messages Buffer Check
  try {
    const output = execSync(
      `emacs --batch --eval "(progn (load-file \\"${filePath}\\") (with-current-buffer \\"*Messages*\\" (princ (buffer-string))))" 2>&1 || true`,
      { encoding: 'utf8', timeout: 10000 }
    );
    results.messagesCheck.output = output;
    results.messagesCheck.errors = extractErrors(output);
    results.messagesCheck.warnings = extractWarnings(output);
    results.messagesCheck.passed = results.messagesCheck.errors.length === 0;
  } catch (err) {
    results.messagesCheck.output = err.message;
    results.messagesCheck.errors.push('Messages check failed: ' + err.message);
  }

  // 4. Byte Compile Check
  try {
    const output = execSync(
      `emacs --batch --eval "(byte-compile-file \\"${filePath}\\")" 2>&1 || true`,
      { encoding: 'utf8', timeout: 10000 }
    );
    results.byteCompile.output = output;
    results.byteCompile.errors = extractErrors(output);
    results.byteCompile.warnings = extractWarnings(output);
    results.byteCompile.passed = results.byteCompile.errors.length === 0;
  } catch (err) {
    results.byteCompile.output = err.message;
    results.byteCompile.errors.push('Byte compile failed: ' + err.message);
  }

  // 5. Package Verification
  try {
    const output = execSync(
      `emacs --batch --eval "(progn (require 'package) (package-initialize))" 2>&1 || true`,
      { encoding: 'utf8', timeout: 10000 }
    );
    results.packageCheck.output = output;
    results.packageCheck.errors = extractErrors(output);
    results.packageCheck.warnings = extractWarnings(output);
    results.packageCheck.passed = results.packageCheck.errors.length === 0;
  } catch (err) {
    results.packageCheck.output = err.message;
    results.packageCheck.errors.push('Package check failed: ' + err.message);
  }

  return results;
}

// Extract error messages from output
function extractErrors(output) {
  const errors = [];
  const lines = output.split('\n');
  for (const line of lines) {
    if (/error:/i.test(line) && !line.includes('0 errors')) {
      errors.push(line.trim());
    }
  }
  return errors;
}

// Extract warning messages from output
function extractWarnings(output) {
  const warnings = [];
  const lines = output.split('\n');
  for (const line of lines) {
    if (/warning:/i.test(line) && !line.includes('0 warnings')) {
      warnings.push(line.trim());
    }
  }
  return warnings;
}

// Attempt auto-fix using bin/emacs-auto-fix
function attemptAutoFix(filePath, errors) {
  try {
    const projectRoot = execSync('git rev-parse --show-toplevel 2>/dev/null || pwd', {
      encoding: 'utf8',
      cwd: path.dirname(filePath)
    }).trim();

    const autoFixScript = path.join(projectRoot, 'bin', 'emacs-auto-fix');

    if (!fs.existsSync(autoFixScript)) {
      return { success: false, message: 'Auto-fix script not found' };
    }

    const input = JSON.stringify({ file: filePath, errors });
    const result = execSync(
      `echo '${input}' | "${autoFixScript}"`,
      { encoding: 'utf8', timeout: 30000 }
    );

    return JSON.parse(result);
  } catch (err) {
    return { success: false, error: err.message };
  }
}

// Count total errors and warnings
function countIssues(results) {
  let totalErrors = 0;
  let totalWarnings = 0;

  for (const check of Object.values(results)) {
    totalErrors += check.errors.length;
    totalWarnings += check.warnings.length;
  }

  return { totalErrors, totalWarnings };
}

// Main verification with auto-fix loop
function verifyWithAutoFix(filePath, maxIterations = 10) {
  let iteration = 0;
  let lastResults = null;

  console.error(`[Emacs Hook] Starting verification (max ${maxIterations} iterations)...`);

  while (iteration < maxIterations) {
    iteration++;
    console.error(`\n[Emacs Hook] ═══ Iteration ${iteration}/${maxIterations} ═══`);

    const results = runAllVerificationChecks(filePath);
    const { totalErrors, totalWarnings } = countIssues(results);

    console.error(`[Emacs Hook] Found ${totalErrors} errors, ${totalWarnings} warnings`);

    // Success condition: zero errors and zero warnings
    if (totalErrors === 0 && totalWarnings === 0) {
      console.error('[Emacs Hook] ✅ All checks passed! Configuration is clean.');
      return { success: true, iterations: iteration, results };
    }

    // Report each check
    for (const [name, result] of Object.entries(results)) {
      const status = result.passed ? '✓' : '✗';
      const errorCount = result.errors.length;
      const warningCount = result.warnings.length;
      console.error(`[Emacs Hook]   ${status} ${name}: ${errorCount} errors, ${warningCount} warnings`);
    }

    // Attempt auto-fix if there are errors
    if (totalErrors > 0) {
      console.error('[Emacs Hook] Attempting auto-fix...');

      const allErrors = [];
      for (const check of Object.values(results)) {
        allErrors.push(...check.errors);
      }

      const fixResult = attemptAutoFix(filePath, allErrors);

      if (fixResult.success && fixResult.fixCount > 0) {
        console.error(`[Emacs Hook] ✓ Applied ${fixResult.fixCount} fixes:`);
        for (const fix of fixResult.fixes || []) {
          console.error(`[Emacs Hook]   - ${fix}`);
        }
      } else if (!fixResult.success) {
        console.error('[Emacs Hook] ⚠ Auto-fix unavailable or failed');
        break;
      } else {
        console.error('[Emacs Hook] ⚠ No automatic fixes available for these errors');
        break;
      }
    } else if (totalWarnings > 0) {
      // Only warnings remain - report them but don't try to fix
      console.error('[Emacs Hook] ⚠ Warnings remain (no auto-fix for warnings):');
      for (const check of Object.values(results)) {
        for (const warning of check.warnings) {
          console.error(`[Emacs Hook]   - ${warning}`);
        }
      }
      break;
    }

    lastResults = results;
  }

  // Failed to achieve clean state
  const { totalErrors, totalWarnings } = countIssues(lastResults);
  console.error(`\n[Emacs Hook] ⚠ Could not achieve clean state after ${iteration} iterations`);
  console.error(`[Emacs Hook] Remaining: ${totalErrors} errors, ${totalWarnings} warnings`);
  console.error('[Emacs Hook] Please review and fix manually.');

  return { success: false, iterations: iteration, results: lastResults };
}

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
      console.error('[Emacs Hook] ════════════════════════════════════════');
      console.error('[Emacs Hook] Detected Emacs config edit: ' + path.basename(filePath));
      console.error('[Emacs Hook] ════════════════════════════════════════');

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

        // Run verification with auto-fix
        verifyWithAutoFix(filePath);

        console.error('[Emacs Hook] ════════════════════════════════════════');
        console.error('[Emacs Hook] Verification complete');
        console.error('[Emacs Hook] ════════════════════════════════════════');

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
