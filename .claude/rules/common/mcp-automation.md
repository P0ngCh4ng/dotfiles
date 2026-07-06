# MCP (Model Context Protocol) Automation Rules

## Auto-Use Policy

**CRITICAL**: Automatically use MCP tools when trigger keywords appear in user requests, without requiring explicit permission.

## Trigger Keywords by MCP Server

### Render MCP

Auto-use Render MCP tools when these keywords appear:

#### Deployment Keywords
- **日本語**: デプロイ, デプロイして, デプロイ状況, 本番環境, ステージング, リリース, 公開
- **English**: deploy, deployment, deploy status, production, staging, release, publish

#### Log Keywords
- **日本語**: ログ, ログ確認, ログを見て, エラーログ, デプロイログ, ビルドログ, デバッグ, トラブルシューティング
- **English**: log, logs, check logs, error log, deploy log, build log, debug, troubleshooting

#### Service Management Keywords
- **日本語**: サービス一覧, サービス状態, 稼働状況, 環境変数, 設定
- **English**: service list, service status, uptime, environment variables, env, config, configuration

#### Available Tools
1. **ListServices** - List all services in Render account
2. **GetService** - Get service details by ID
3. **ListDeploys** - Get deployment history
4. **GetDeployLogs** - Get logs for specific deploy
5. **GetLogs** - Get service logs
6. **TriggerDeploy** - Trigger new deployment
7. **GetEnvironmentVariables** - Get environment variables
8. **UpdateEnvironmentVariable** - Update environment variable

#### Typical Workflows

**Deploy Status Check:**
```
User: "デプロイ状況確認して"
→ 1. ListServices
→ 2. ListDeploys
→ 3. Report status
```

**Error Investigation:**
```
User: "最新デプロイのエラーログ見て"
→ 1. ListServices
→ 2. ListDeploys (get latest deploy ID)
→ 3. GetDeployLogs (with deploy ID)
→ 4. Analyze and report errors
```

**New Deployment:**
```
User: "デプロイして"
→ 1. Confirm changes
→ 2. TriggerDeploy
→ 3. Monitor with GetDeployLogs
→ 4. Report result
```

### Future MCP Servers

Add new sections here as new MCP servers are integrated:

#### Template for New MCP Server
```markdown
### [MCP Server Name]

Auto-use when these keywords appear:
- **日本語**: キーワード1, キーワード2
- **English**: keyword1, keyword2

Available Tools:
1. **ToolName** - Description

Typical Workflows:
- Workflow description
```

## Detection and Project Mapping

### Project Configuration Check

**BEFORE using MCP tools:**
1. Check if `.mcp.json` exists in current project
2. Verify MCP server is configured
3. If not configured, inform user about setup

### Configuration Examples

**Render MCP in hojocon:**
```json
{
  "mcpServers": {
    "render": {
      "type": "stdio",
      "command": "node",
      "args": [
        "/Users/pongchang/mcpCreate/render-mcp-server/dist/src/index.js"
      ],
      "env": {
        "RENDER_API_KEY": "rnd_..."
      }
    }
  }
}
```

## Best Practices

### When to Use MCP Tools

**ALWAYS use automatically when:**
- User request contains trigger keywords
- Project has MCP configured in `.mcp.json`
- Tool is available and operational

**NEVER ask permission:**
- ❌ "Render MCP を使ってもいいですか？"
- ✅ Just use it directly based on keywords

### Error Handling

**If MCP tool fails:**
1. Report error clearly
2. Suggest alternative approaches
3. Check `.mcp.json` configuration
4. Verify API keys are set

**Common errors:**
- Missing API key → Check environment variables
- 404 Not Found → Verify service ID / deploy ID
- Network error → Check internet connection
- Permission denied → Verify API key permissions

### Multi-Tool Workflows

**Execute in sequence when dependent:**
```
ListServices → GetService → ListDeploys → GetDeployLogs
```

**Execute in parallel when independent:**
```
GetService + GetEnvironmentVariables (parallel)
```

## Integration with Project Rules

**Project-specific MCP rules override global rules:**
- Check `<project>/CLAUDE.md` for project-specific MCP automation
- Global rules apply when project rules don't exist
- Project rules can extend or override these defaults

**Example:**
- Global: "deploy" → Use Render MCP
- hojocon: "deploy" → Use Render MCP + notify Slack (project-specific)

## Verification

**Test MCP automation:**
1. Navigate to project with MCP configured
2. Say trigger keyword (e.g., "デプロイ状況確認して")
3. Verify tool is called automatically without asking
4. Check results are presented correctly

## Related Documentation

- **Agent Automation**: `~/.claude/rules/common/agent-automation.md`
- **Project-Specific Rules**: `~/.claude/rules/project-specific-rules.md`
- **Render MCP README**: `~/mcpCreate/render-mcp-server/README.md`
- **Hojocon MCP Config**: `~/hojocon/.mcp.json`
- **Hojocon Claude Guide**: `~/hojocon/CLAUDE.md`

---

**Last Updated**: 2026-04-09
**Priority**: High (applies to all projects)
