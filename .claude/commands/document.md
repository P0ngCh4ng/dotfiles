# Document - Comprehensive Documentation Generation

Generate comprehensive documentation with deep codebase understanding and consistency checking.

$ARGUMENTS (target: feature, API, module, or "all" for full documentation)

---

## Workflow

### Phase 1: Documentation Scope Analysis

1. **Identify Documentation Target**
   - Parse $ARGUMENTS: specific feature, API, module, or full project
   - Determine documentation types needed:
     - **README:** Project overview, setup, usage
     - **API Documentation:** Endpoints, functions, classes
     - **User Guide:** How to use features
     - **Developer Guide:** How to contribute, architecture
     - **CHANGELOG:** Version history, breaking changes
     - **Migration Guide:** Upgrade instructions

2. **Assess Current Documentation State**
   - Find existing documentation: `Glob("**/*.md")`
   - Check for outdated docs (compare to recent code changes)
   - Identify gaps (undocumented features, missing examples)
   - Analyze documentation quality (completeness, accuracy, clarity)

### Phase 2: Multi-Agent Deep Analysis (Parallel Launch)

**Launch general-purpose agent and doc-updater in PARALLEL:**

#### Agent 1: Codebase Understanding

```javascript
Task({
  subagent_type: "general-purpose",
  description: "Deep codebase analysis for documentation",
  prompt: `Analyze codebase to extract comprehensive information for documentation.

Target: ${documentation_target}
Scope: ${scope}

Extract:
1. **Architecture and Structure**
   - Project structure (directories, modules, components)
   - Technology stack (languages, frameworks, libraries)
   - Design patterns used
   - Key abstractions and concepts

2. **Features and Functionality**
   - List all features (user-facing and internal)
   - How features work (high-level flow)
   - Configuration options
   - Environment variables

3. **API Surface**
   - Public APIs (REST, GraphQL, functions, classes)
   - Request/response formats
   - Authentication and authorization
   - Rate limits and quotas

4. **Setup and Dependencies**
   - Required dependencies (package.json, requirements.txt, etc.)
   - Environment setup steps
   - Configuration files
   - Database schema

5. **Usage Examples**
   - Common use cases
   - Code examples from tests or actual code
   - Best practices observed in code

6. **Edge Cases and Limitations**
   - Known limitations
   - Common pitfalls (from error handling code)
   - Performance considerations

Search codebase systematically:
- Use Glob to find relevant files
- Use Grep to search for patterns
- Use Read to understand implementations
- Extract actual code examples

Output: Comprehensive codebase analysis for documentation`
})
```

#### Agent 2: Documentation Quality and Consistency

```javascript
Task({
  subagent_type: "doc-updater",
  description: "Documentation quality and consistency analysis",
  prompt: `Analyze existing documentation for quality, gaps, and consistency.

Target: ${documentation_target}
Existing docs: ${existing_docs}
Recent changes: ${recent_code_changes}

Analyze:
1. **Documentation Gaps**
   - Undocumented features
   - Missing API documentation
   - Missing examples
   - Outdated information

2. **Quality Issues**
   - Unclear explanations
   - Incomplete information
   - Broken links or references
   - Inconsistent formatting

3. **Consistency**
   - Terminology consistency
   - Style consistency (tone, voice, format)
   - Cross-references accuracy
   - Version consistency

4. **Completeness**
   - Installation instructions complete?
   - Usage examples sufficient?
   - Troubleshooting section exists?
   - Contributing guidelines present?

5. **Accuracy**
   - Does documentation match actual code?
   - Are API signatures correct?
   - Are examples working?

Output: Documentation gaps, quality issues, consistency recommendations`
})
```

**Both agents run in PARALLEL** for comprehensive analysis

### Phase 3: Synthesize Documentation Plan

1. **Combine Agent Insights**
   - Codebase understanding from general-purpose agent
   - Documentation gaps and quality issues from doc-updater
   - Create comprehensive documentation plan

2. **Documentation Generation Plan**
   ```markdown
   ## Documentation Plan: ${target}

   ### Current State
   - Existing docs: ${existing_doc_list}
   - Documentation coverage: ${coverage_percentage}%
   - Gaps identified: ${gap_count}
   - Quality issues: ${quality_issue_count}

   ### Documentation to Generate/Update

   #### 1. README.md
   - [ ] Project overview and description
   - [ ] Key features list
   - [ ] Installation instructions
   - [ ] Quick start guide
   - [ ] Usage examples
   - [ ] Configuration options
   - [ ] Troubleshooting
   - [ ] Contributing guidelines
   - [ ] License information

   #### 2. API Documentation
   **Endpoints/Functions to document:**
   - ${api_1}: ${description_1}
   - ${api_2}: ${description_2}
   - ...

   **Format:** OpenAPI/Swagger | JSDoc | TypeDoc | Sphinx | etc.

   #### 3. User Guide (docs/user-guide.md)
   - [ ] Getting started
   - [ ] Core concepts
   - [ ] Feature tutorials
   - [ ] Best practices
   - [ ] FAQ
   - [ ] Examples gallery

   #### 4. Developer Guide (docs/developer-guide.md)
   - [ ] Architecture overview
   - [ ] Project structure
   - [ ] Development setup
   - [ ] Code style guidelines
   - [ ] Testing strategy
   - [ ] Deployment process

   #### 5. CHANGELOG.md
   - [ ] Version history
   - [ ] Breaking changes
   - [ ] New features
   - [ ] Bug fixes
   - [ ] Deprecations

   #### 6. Migration Guides
   - [ ] v1 to v2 migration
   - [ ] Breaking changes explanation
   - [ ] Code examples (before/after)

   ### Content Sources
   - Code examples from: ${source_files}
   - Architecture from: ${architecture_files}
   - API signatures from: ${api_files}
   - Configuration from: ${config_files}

   ### Quality Standards
   - Clear and concise language
   - Consistent terminology: ${terminology_map}
   - Working code examples (tested)
   - Proper formatting (Markdown)
   - Cross-references where appropriate
   ```

### Phase 4: User Confirmation

**Present plan and wait for approval:**

```markdown
## Documentation Plan Ready

**Multi-agent analysis complete:**
- 📖 general-purpose: Analyzed ${file_count} files, extracted ${feature_count} features
- ✍️ doc-updater: Found ${gap_count} gaps, ${quality_issue_count} quality issues

**Documentation to generate:**
1. README.md (${status_readme})
2. API Documentation (${api_count} endpoints)
3. User Guide (${section_count} sections)
4. Developer Guide (${dev_section_count} sections)
5. CHANGELOG.md (${changelog_status})

**Estimated time:** ${time_estimate}

**Next Steps:**
- ✅ Approve: Generate all documentation
- 📝 Modify: Adjust scope or priorities
- 🔍 Review: Check plan first

Would you like me to proceed with documentation generation?
```

### Phase 5: Documentation Generation (After Approval)

1. **Generate Documentation Files**
   - Create/update README.md
   - Generate API documentation
   - Write user guide sections
   - Write developer guide sections
   - Update CHANGELOG.md

2. **Extract and Format Code Examples**
   - Extract working examples from tests
   - Format with proper syntax highlighting
   - Add explanatory comments
   - Verify examples are accurate

3. **Add Cross-References**
   - Link related sections
   - Add table of contents
   - Create index of key terms
   - Link to external resources

4. **Ensure Consistency**
   - Use consistent terminology throughout
   - Follow style guide (Markdown formatting)
   - Maintain consistent tone and voice
   - Use consistent code formatting

### Phase 6: Documentation Review

**Auto-launch doc-updater for quality check:**

```javascript
Task({
  subagent_type: "doc-updater",
  description: "Documentation quality review",
  prompt: `Review generated documentation for quality and completeness.

Generated docs: ${generated_docs}

Check:
- Completeness (all planned sections present)
- Accuracy (matches actual code)
- Clarity (easy to understand)
- Examples (working and relevant)
- Formatting (proper Markdown)
- Links (no broken references)
- Consistency (terminology, style)

Provide:
- Issues found
- Suggestions for improvement
- Missing sections
- Approval status`
})
```

### Phase 7: Finalize and Commit

1. **Apply Review Feedback**
   - Fix issues identified by doc-updater
   - Improve clarity where needed
   - Add missing information
   - Verify all links work

2. **Commit Documentation**
   ```bash
   git add docs/ *.md
   git commit -m "docs: generate comprehensive documentation for ${target}

   Generated:
   - README.md: project overview, setup, usage
   - API documentation: ${api_count} endpoints
   - User guide: ${section_count} sections
   - Developer guide: architecture, setup, contribution

   Includes:
   - Working code examples
   - Architecture diagrams
   - Configuration reference
   - Troubleshooting guide

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

3. **Report Results**
   ```markdown
   ## Documentation Generation Complete

   **Generated/Updated:**
   - ✅ README.md (${readme_sections} sections)
   - ✅ API Documentation (${api_count} endpoints)
   - ✅ User Guide (${user_guide_sections} sections)
   - ✅ Developer Guide (${dev_guide_sections} sections)
   - ✅ CHANGELOG.md (up to date)

   **Quality Metrics:**
   - Documentation coverage: ${coverage_percentage}%
   - Code examples: ${example_count}
   - Cross-references: ${link_count}
   - Images/diagrams: ${image_count}

   **Next Steps:**
   - Review generated documentation
   - Deploy to documentation site (if applicable)
   - Announce documentation updates
   ```

---

## Documentation Types

### 1. README.md
**Purpose:** First impression, quick start
**Sections:**
- Project description
- Key features
- Installation
- Quick start
- Usage examples
- Configuration
- Contributing
- License

### 2. API Documentation
**Purpose:** Reference for developers using the API
**Formats:**
- **REST:** OpenAPI/Swagger
- **GraphQL:** Schema documentation
- **Libraries:** JSDoc, TypeDoc, Sphinx, Godoc
**Sections:**
- Authentication
- Endpoints/Functions
- Request/Response formats
- Error codes
- Rate limits
- Examples

### 3. User Guide
**Purpose:** Teach users how to use features
**Sections:**
- Getting started
- Core concepts
- Tutorials (step-by-step)
- Best practices
- FAQ
- Troubleshooting

### 4. Developer Guide
**Purpose:** Help contributors understand and extend codebase
**Sections:**
- Architecture overview
- Project structure
- Development setup
- Code style guidelines
- Testing strategy
- Contribution process
- Deployment

### 5. CHANGELOG
**Purpose:** Track changes between versions
**Format:** Keep a Changelog format
**Sections:**
- [Version] - Date
  - Added
  - Changed
  - Deprecated
  - Removed
  - Fixed
  - Security

### 6. Migration Guides
**Purpose:** Help users upgrade between versions
**Sections:**
- Breaking changes
- Deprecated features
- New features
- Code examples (before/after)
- Step-by-step upgrade instructions

---

## Documentation Best Practices

### Writing Style
- ✅ Clear and concise
- ✅ Active voice ("Run the command" not "The command should be run")
- ✅ Present tense
- ✅ Simple language (avoid jargon)
- ✅ Short sentences and paragraphs

### Structure
- ✅ Logical flow (general → specific)
- ✅ Table of contents for long docs
- ✅ Headers and subheaders
- ✅ Bulleted and numbered lists
- ✅ Code blocks with syntax highlighting

### Code Examples
- ✅ Working examples (tested)
- ✅ Complete examples (copy-paste ready)
- ✅ Realistic use cases
- ✅ Commented explanations
- ✅ Show both input and output

### Maintenance
- ✅ Keep docs in sync with code
- ✅ Update docs in same PR as code changes
- ✅ Review docs regularly (quarterly)
- ✅ Version docs with releases
- ✅ Mark deprecated features

---

## Auto-Launch Conditions

This command automatically triggers when:
- User requests: "Document [feature]"
- User requests: "Generate documentation"
- User mentions: "ドキュメント生成", "docs更新"
- Keywords: "document", "docs", "documentation"

---

## Success Criteria

✅ Comprehensive codebase analysis completed
✅ Documentation gaps identified
✅ Documentation generated/updated
✅ Code examples included and working
✅ Quality reviewed by doc-updater agent
✅ Consistent formatting and terminology
✅ All links verified
✅ Committed with descriptive message

---

## Notes

- **Deep understanding:** general-purpose agent analyzes codebase thoroughly
- **Quality focus:** doc-updater ensures consistency and completeness
- **Working examples:** Extract actual code examples from tests/implementation
- **Living documentation:** Keep docs in sync with code (update together)
- **Multi-format:** Support README, API docs, guides, changelogs
