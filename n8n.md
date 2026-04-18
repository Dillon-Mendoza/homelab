Workflow nodes

Webhook node

Method: POST URL: http://127.0.0.1:5678/webhook/
Gitea webhook set to HTTP (not HTTPS) pointing to localhost

Code node (JavaScript)

const message = $input.first().json.body.commits[0].message
const userName = $input.first().json.body.pusher.username
const repoName = $input.first().json.body.repository.name
const discordMessage = [${repoName}] ${userName} pushed: "${message}"
const cleanMessage = discordMessage.replace(/\n/g, ' ').replace(/"/g, "'")
return [{ json: { discordMessage, cleanMessage } }]

HTTP Request node (Discord)

Method: POST
URL: Discord webhook URL
Body: Using Fields — key: content, value: {{ $json.discordMessage }}

Execute Command node (log file)

echo "{{ $json.cleanMessage }}" >> /var/log/n8n/<new.log.name>.log

*** See mudd-labs/dashboard repo for list of troubleshoot. ***