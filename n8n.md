Workflow nodes

Webhook node

Method: POST URL: http://127.0.0.1:5678/webhook/ Gitea webhook set to HTTP (not HTTPS) pointing to localhost

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

Issues encountered and fixes

Issue | Cause | Fix TLS error on webhook | Gitea webhook set to HTTPS, n8n not serving TLS directly | Changed webhook URL to http://127.0.0.1:5678/...

Webhook denied by Gitea | No [webhook] block in app.ini | Added ALLOWED_HOST_LIST = 127.0.0.1 to /etc/gitea/app.ini, restarted Gitea

n8n container permission denied on startup | SELinux blocking writes to host-mounted volume | Added :z flag to volume mounts in docker run command

Execute Command permission denied | Quotes and newlines in message breaking shell command | Added cleanMessage sanitization in Code node

To add a new repo

    Create webhook in Gitea repo pointing to http://127.0.0.1:5678/webhook/
    Duplicate workflow in n8n, update webhook node key
    Update Execute Command log path to /var/log/n8n/.log
