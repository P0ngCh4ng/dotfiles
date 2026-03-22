#!/usr/bin/env node
/**
 * Agent Registry Consistency Check Hook
 *
 * Ensures .claude/agents/AGENTS.md stays in sync with actual agent files.
 * Runs on PreToolUse for Write/Edit operations in .claude/agents/ directory.
 *
 * Exit codes:
 * - 0: Success, registry is consistent
 * - 1: Warning, registry may need update (non-blocking)
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const MAX_STDIN = 1024 * 1024;
let data = '';
process.stdin.setEncoding('utf8');

process.stdin.on('data', chunk => {
  if (data.length < MAX_STDIN) {
    const remaining = MAX_STDIN - data.length;
    data += chunk.substring(0, remaining);
  }
});

process.stdin.on('end', () => {
  try {
    const input = JSON.parse(data);
    const filePath = input.tool_input?.file_path || '';

    // Only check operations in ~/.claude/agents/ directory
    const globalAgentsPath = path.join(os.homedir(), '.claude/agents');

    if (!filePath.startsWith(globalAgentsPath) || filePath.endsWith('AGENTS.md')) {
      process.stdout.write(data);
      process.exit(0);
    }

    // Check if this is an agent definition file (.md, not AGENTS.md)
    if (!filePath.endsWith('.md')) {
      process.stdout.write(data);
      process.exit(0);
    }

    const agentsDir = path.join(os.homedir(), '.claude/agents');
    const registryPath = path.join(agentsDir, 'AGENTS.md');

    // Count agent files (exclude AGENTS.md)
    let agentFiles = [];
    try {
      agentFiles = fs.readdirSync(agentsDir)
        .filter(f => f.endsWith('.md') && f !== 'AGENTS.md')
        .map(f => f.replace('.md', ''));
    } catch (err) {
      // Directory doesn't exist yet, that's fine
      process.stdout.write(data);
      process.exit(0);
    }

    // Check if AGENTS.md exists and count entries
    if (!fs.existsSync(registryPath)) {
      if (agentFiles.length > 0) {
        console.error('[Hook] WARNING: Agent files exist but AGENTS.md is missing');
        console.error('[Hook] Please create .claude/agents/AGENTS.md to document your agents');
        console.error('[Hook] Found agents:', agentFiles.join(', '));
      }
      process.stdout.write(data);
      process.exit(0);
    }

    // Read AGENTS.md and count ### entries (agent sections)
    const registryContent = fs.readFileSync(registryPath, 'utf8');
    const agentSections = (registryContent.match(/^### \w+/gm) || [])
      .map(line => line.replace('### ', '').trim());

    // Compare counts and contents
    const fileSet = new Set(agentFiles);
    const registrySet = new Set(agentSections);

    const missingInRegistry = agentFiles.filter(a => !registrySet.has(a));
    const extraInRegistry = agentSections.filter(a => !fileSet.has(a));

    if (missingInRegistry.length > 0) {
      console.error('[Hook] WARNING: Agents not documented in AGENTS.md:');
      missingInRegistry.forEach(a => console.error(`  - ${a}`));
      console.error('[Hook] Please update .claude/agents/AGENTS.md');
    }

    if (extraInRegistry.length > 0) {
      console.error('[Hook] WARNING: AGENTS.md references non-existent agents:');
      extraInRegistry.forEach(a => console.error(`  - ${a}`));
      console.error('[Hook] Please update .claude/agents/AGENTS.md');
    }

    if (missingInRegistry.length === 0 && extraInRegistry.length === 0 && agentFiles.length > 0) {
      console.error('[Hook] ✓ Agent registry is consistent');
    }

  } catch (err) {
    // Ignore parse errors, pass through
  }

  // Always pass through - this is a warning hook, not a blocker
  process.stdout.write(data);
  process.exit(0);
});
