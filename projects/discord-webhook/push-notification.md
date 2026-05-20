# Gitea Push Notification Workflow
*Mudd Labs | n8n | Last updated: April 15, 2026*
 
---
 
## Overview
 
An event-driven n8n workflow that triggers on Gitea repository pushes. Formats push data from the raw webhook payload and routes it to two simultaneous outputs: a Discord channel notification and a persistent log file on the Fedora server.
 
Serves as the base template for all future repo monitoring workflows in Mudd Labs.
 
---
 
## Node Chain
 
```
[Webhook] → [Code node: format message] → [HTTP Request: Discord notification]
                                         → [Execute Command: append to log file]
```
 
---
 
## Node 1 — Webhook
 
| Field | Value |
|-------|-------|
| Method | POST |
| URL type | Production (not test) |
| URL format | `http://127.0.0.1:5678/webhook/<key>` |
| Configured in Gitea | Yes — one webhook per repo |
 
> Always use the production URL. The test URL only works when the listener is manually activated and times out after one call.
 
---
 
## Node 2 — Code Node
 
Extracts push data from the raw Gitea webhook payload and formats it into a clean message string.
 
```javascript
const message = $input.first().json.body.commits[0].message
const userName = $input.first().json.body.pusher.username
const repoName = $input.first().json.body.repository.name
const discordMessage = `[${repoName}] ${userName} pushed: "${message}"`
const cleanMessage = discordMessage.replace(/\n/g, ' ').replace(/"/g, "'")
 
return [{ json: { discordMessage, cleanMessage } }]
```
 
### Payload Path Reference
 
| Data | Path |
|------|------|
| Pusher username | `$input.first().json.body.pusher.username` |
| Repository name | `$input.first().json.body.repository.name` |
| Commit message | `$input.first().json.body.commits[0].message` |
 
### Variable Reference
 
| Variable | Purpose |
|----------|---------|
| `discordMessage` | Formatted message for Discord (preserves original formatting) |
| `cleanMessage` | Sanitized version — newlines stripped, double quotes replaced with single quotes — safe to pass to shell |
 
> `cleanMessage` exists specifically to prevent shell injection when passing to the Execute Command node. Never pass `discordMessage` directly to a shell command.
 
---
 
## Node 3 — HTTP Request (Discord)
 
Sends the formatted push notification to a Discord channel via incoming webhook.
 
| Field | Value |
|-------|-------|
| Method | POST |
| URL | Discord webhook URL (store securely, do not commit) |
| Body mode | Using Fields |
| Key | `content` |
| Value | `{{ $json.discordMessage }}` |
 
### Discord Webhook Setup
 
1. Open Discord → target channel → **Edit Channel**
2. **Integrations → Webhooks → New Webhook**
3. Name it, assign to channel, copy URL
4. Paste URL into n8n HTTP Request node
> Discord incoming webhooks expect a POST with `{"content": "your message"}`. The `content` field is all that's required for a plain text message.
 
---
 
## Node 4 — Execute Command (Log File)
 
Appends the push event as a line to a persistent log file on the host.
 
```bash
echo "{{ $json.cleanMessage }}" >> /var/log/n8n/<repo-name>.log
```
 
> Use `cleanMessage` here, not `discordMessage`. The shell will break on unescaped newlines and double quotes.
 
### Log File Location
 
```
/var/log/n8n/<repo-name>.log
```
 
One log file per repo. The `>>` operator creates the file if it doesn't exist and appends if it does.
 
### Verify Log Output
 
```bash
cat /var/log/n8n/<repo-name>.log
```
 
---
 
## Adding a New Repo
 
1. Push repo to Gitea instance
2. In Gitea repo → **Settings → Webhooks → Add Webhook → Gitea**
3. Set URL to `http://127.0.0.1:5678/webhook/<production-key>`
4. Set content type to `application/json`
5. Trigger on **Push events**
6. In n8n — duplicate the existing workflow
7. Update the Webhook node key to match the new webhook
8. Update the Execute Command log path to `/var/log/n8n/<new-repo-name>.log`
9. Activate the workflow
10. Push a test commit and verify Discord notification and log entry
---
 
## Troubleshooting Reference
 
| Symptom | Cause | Fix |
|---------|-------|-----|
| Webhook fires but nothing happens in n8n | Workflow not activated | Toggle activation switch top-right of n8n canvas |
| n8n receives webhook but Execute Command throws permission denied | Quotes or newlines in message breaking shell | Confirm `cleanMessage` sanitization is in Code node and used in Execute Command |
| Discord message shows raw `{{ }}` instead of value | Expression syntax error | Confirm body mode is set to "Using Fields", not raw JSON |
| Log file not updating | Wrong path or file not writable | Test manually: `docker exec n8n sh -c 'echo "test" >> /var/log/n8n/<file>'` |
| Gitea shows webhook queued but not delivered | n8n test listener timed out | Switch to production URL and activate workflow — test URL is one-shot only |
| Commit message shows `\n` in log | Raw newline in payload | Confirm `cleanMessage` replace is applied before Execute Command |
 
---
 
## Workflow Activation Checklist
 
When rebuilding or duplicating this workflow:
 
- [ ] Webhook node set to production URL
- [ ] Code node returns both `discordMessage` and `cleanMessage`
- [ ] HTTP Request node uses `{{ $json.discordMessage }}` with "Using Fields" body mode
- [ ] Execute Command uses `{{ $json.cleanMessage }}` with correct log file path
- [ ] Gitea webhook URL updated to match new production webhook key
- [ ] Workflow toggled active in n8n canvas
- [ ] Test push confirmed — Discord notification received and log entry written
---
 
## Example Output
 
**Discord notification:**
```
[homelab] admin-mudd pushed: "Adding Tailscale ACL architecture doc"
```
 
**Log file entry (`/var/log/n8n/homelab.log`):**
```
[homelab] admin-mudd pushed: 'Adding Tailscale ACL architecture doc'
```
