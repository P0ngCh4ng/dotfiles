#!/usr/bin/env node
/**
 * Enforce Session Start Protocol
 *
 * Automatically loads project context at session start:
 * 1. Detect current project from pwd
 * 2. Read ~/dotfiles/projects.yml
 * 3. Display project context to Claude Code
 *
 * Outputs to stderr so Claude Code sees it.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

try {
  const cwd = process.cwd();
  const projectsFile = path.join(process.env.HOME, 'dotfiles', 'projects.yml');

  console.error('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.error('⚙️  SESSION START PROTOCOL (Auto-enforced by hooks)');
  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  // Step 1: Detect current directory
  console.error(`\n📂 Current Directory: ${cwd}`);

  // Step 2: Check if projects.yml exists
  if (!fs.existsSync(projectsFile)) {
    console.error('⚠️  Warning: ~/dotfiles/projects.yml not found');
    console.error('   Project configuration unavailable\n');
    process.exit(0);
  }

  // Step 3: Read projects.yml
  const projectsYml = fs.readFileSync(projectsFile, 'utf-8');

  // Step 4: Find matching project (simple YAML parsing)
  let matchedProject = null;
  const lines = projectsYml.split('\n');
  let currentProject = null;
  let inProjectsSection = false;

  for (const line of lines) {
    // Detect projects: section
    if (line.trim() === 'projects:') {
      inProjectsSection = true;
      continue;
    }

    if (!inProjectsSection) continue;

    // Detect project name (indented, ends with :)
    const projectMatch = line.match(/^  (\w+):$/);
    if (projectMatch) {
      currentProject = projectMatch[1];
      continue;
    }

    // Detect path
    if (currentProject) {
      const pathMatch = line.match(/^\s+path:\s+(.+)$/);
      if (pathMatch) {
        const projectPath = pathMatch[1].replace('~', process.env.HOME);
        if (path.resolve(cwd) === path.resolve(projectPath)) {
          matchedProject = currentProject;
          break;
        }
      }
    }
  }

  // Step 5: Display context
  if (matchedProject) {
    console.error(`\n✅ Project Context Loaded: ${matchedProject}`);
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Try to run pj-info command (if available)
    try {
      const shellCmd = `source ~/.zshrc && pj-info ${matchedProject} 2>&1`;
      const output = execSync(shellCmd, {
        shell: '/bin/zsh',
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe']
      });
      console.error(output);
    } catch (e) {
      // Fallback: manual parsing
      console.error(`   Project: ${matchedProject}`);
      console.error(`   Path: ${cwd}`);

      // Extract basic info from projects.yml
      const projectSection = projectsYml.split(`${matchedProject}:`)[1]?.split(/\n  \w+:/)[0] || '';
      const portsMatch = projectSection.match(/ports:\s+\[([^\]]*)\]/);
      const techMatch = projectSection.match(/tech:\s+\[([^\]]*)\]/);
      const descMatch = projectSection.match(/description:\s+"([^"]*)"/);

      if (portsMatch) console.error(`   Ports: ${portsMatch[1] || 'none'}`);
      if (techMatch) console.error(`   Tech: ${techMatch[1]}`);
      if (descMatch) console.error(`   Description: ${descMatch[1]}`);

      // Check for databases
      const dbCount = (projectSection.match(/databases:/g) || []).length;
      if (dbCount > 0) {
        console.error(`   Databases: ${dbCount} configured`);
      }
    }

    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('\n📋 REMINDER: Follow rules in ~/.claude/rules/common/00-session-start.md');
    console.error('   • Auto-launch agents when conditions match');
    console.error('   • Check ports/databases proactively');
    console.error('   • Use project context for suggestions\n');

  } else {
    console.error('\nℹ️  Not a registered project');
    console.error(`   Working in: ${cwd}`);
    console.error('   (Add to ~/dotfiles/projects.yml if needed)\n');
  }

  console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Always exit 0 (don't block session start)
  process.exit(0);

} catch (error) {
  console.error('⚠️  Session start hook error:', error.message);
  // Don't block session start on errors
  process.exit(0);
}
