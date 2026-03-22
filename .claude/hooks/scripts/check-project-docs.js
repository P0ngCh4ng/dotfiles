#!/usr/bin/env node
/**
 * Check Project Documentation (SessionStart Hook)
 *
 * Checks if project has required documentation structure:
 * - .claude/architecture/
 * - .claude/database/
 *
 * If missing, suggests generating documentation.
 */

const fs = require('fs');
const path = require('path');

try {
  // Get project root from environment
  const projectRoot = process.env.CLAUDE_PROJECT_ROOT || process.cwd();

  // Check if this is a git project (skip if not a real project)
  const isGitProject = fs.existsSync(path.join(projectRoot, '.git'));
  if (!isGitProject) {
    // Not a git project, skip check
    process.exit(0);
  }

  // Check for .claude directory
  const claudeDir = path.join(projectRoot, '.claude');
  if (!fs.existsSync(claudeDir)) {
    // No .claude directory, maybe not a project that uses Claude Code
    process.exit(0);
  }

  // Check for architecture documentation
  const archDir = path.join(claudeDir, 'architecture');
  const archOverview = path.join(archDir, 'overview.md');
  const hasArchDocs = fs.existsSync(archOverview);

  // Check for database documentation
  const dbDir = path.join(claudeDir, 'database');
  const dbSchema = path.join(dbDir, 'schema.md');
  const hasDbDocs = fs.existsSync(dbSchema);

  // Detect if project has database (heuristic)
  const hasDatabase = (
    fs.existsSync(path.join(projectRoot, 'prisma', 'schema.prisma')) ||
    fs.existsSync(path.join(projectRoot, 'migrations')) ||
    fs.existsSync(path.join(projectRoot, 'database', 'migrations')) ||
    fs.existsSync(path.join(projectRoot, 'db', 'migrations')) ||
    fs.existsSync(path.join(projectRoot, 'models')) ||
    fs.existsSync(path.join(projectRoot, 'src', 'models'))
  );

  // Report findings
  let needsGeneration = false;

  if (!hasArchDocs) {
    console.error('[Auto-Doc] 📐 Project architecture documentation missing');
    console.error('[Auto-Doc]    Generate with: /update-architecture');
    needsGeneration = true;
  } else {
    // Check age of architecture docs
    const stats = fs.statSync(archOverview);
    const ageInDays = (Date.now() - stats.mtimeMs) / (1000 * 60 * 60 * 24);

    if (ageInDays > 30) {
      console.error('[Auto-Doc] 📐 Architecture docs are ' + Math.floor(ageInDays) + ' days old');
      console.error('[Auto-Doc]    Consider updating: /update-architecture');
    }
  }

  if (hasDatabase && !hasDbDocs) {
    console.error('[Auto-Doc] 🗄️  Database schema documentation missing');
    console.error('[Auto-Doc]    Generate with: /update-database');
    needsGeneration = true;
  } else if (hasDatabase && hasDbDocs) {
    // Check age of database docs
    const stats = fs.statSync(dbSchema);
    const ageInDays = (Date.now() - stats.mtimeMs) / (1000 * 60 * 60 * 24);

    if (ageInDays > 30) {
      console.error('[Auto-Doc] 🗄️  Database docs are ' + Math.floor(ageInDays) + ' days old');
      console.error('[Auto-Doc]    Consider updating: /update-database');
    }
  }

  if (needsGeneration) {
    console.error('');
    console.error('[Auto-Doc] 💡 Tip: Documentation helps preserve context across sessions');
    console.error('[Auto-Doc]       and prevents "forgetting" project structure');
  }

  // Always exit 0 (don't block session start)
  process.exit(0);

} catch (error) {
  // Silently fail - don't block session start
  process.exit(0);
}
