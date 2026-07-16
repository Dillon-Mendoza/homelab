#!/bin/bash
# Networking — tcpdump Lab: read packets like log lines
# Run on: tp-mudd only — all captures are loopback or tp-mudd's own traffic
# Estimated time: 45–60 min
#
# Goal: after this session, `tcpdump` output reads as sentences — SYN, SYN-ACK,
# ACK, who asked, who answered, what flag means what. This is the layer UNDER
# every 5.3 symptom: ss/curl/dig tell you THAT something failed; tcpdump shows
# the packets doing it.
# tcpdump needs root for capture: tasks use sudo. Captures write to $SCRATCH.

DRY_RUN=true  # Set to false to execute. true echoes commands instead of running them.

run_cmd() {
    if $DRY_RUN; then
        echo "[DRY RUN] $*"
    else
        eval "$@"
    fi
}

SCRATCH="/tmp/tcpdump-lab"
IFACE=$(ip route show default 2>/dev/null | awk '{print $5; exit}')

echo ""
echo "════════════════════════════════════════════════════════"
echo "  tcpdump Lab — Host: $(hostname) | $(date)"
echo "  DRY_RUN=$DRY_RUN | real iface: ${IFACE:-unknown}"
echo "════════════════════════════════════════════════════════"
echo ""

run_cmd "mkdir -p $SCRATCH"

# ── TASK 1: The TCP Handshake, Narrated ───────────────────────────────────────
# Why it matters: every "can't connect" symptom is a handshake that didn't
# finish. Knowing which of the three packets is missing names the culprit.
echo "── TASK 1: Three-Way Handshake on Loopback ──"

echo ""
echo "[1a] Server on :8080, capture on loopback, one curl through it:"
run_cmd "python3 -m http.server 8080 --bind 127.0.0.1 >/dev/null 2>&1 & echo \$! > $SCRATCH/srv.pid; sleep 1"
run_cmd "sudo timeout 6 tcpdump -i lo -nn 'tcp port 8080' -c 12 > $SCRATCH/handshake.txt 2>/dev/null & sleep 1; curl -s -o /dev/null http://127.0.0.1:8080; sleep 2"
run_cmd "head -6 $SCRATCH/handshake.txt"
echo "  READ IT: line 1 'Flags [S]' = SYN (client asks). Line 2 '[S.]' ="
echo "  SYN-ACK (server agrees — the dot IS the ACK). Line 3 '[.]' = ACK."
echo "  Then '[P.]' = PSH-ACK (data), and eventually '[F.]' = FIN (goodbye)."
echo "  -nn = no name/port lookups: raw numbers, no DNS noise in the capture."

echo ""
echo "[1b] Now a REFUSED connection — nothing listens on :8081:"
run_cmd "sudo timeout 4 tcpdump -i lo -nn 'tcp port 8081' -c 4 > $SCRATCH/refused.txt 2>/dev/null & sleep 1; curl -s -m 2 -o /dev/null http://127.0.0.1:8081; sleep 1"
run_cmd "head -3 $SCRATCH/refused.txt"
echo "  ^ SYN out, '[R.]' back — RST. THAT is 'connection refused' on the wire:"
echo "    host alive, port closed. A FILTERED port would show SYN... silence —"
echo "    which is 'timeout'. Refused vs timeout, now seen, not memorized."

echo ""

# ── TASK 2: DNS on the Wire ───────────────────────────────────────────────────
# Why it matters: DNS diagnosis so far used dig's OPINION. This is the packet
# truth — query out, answer in, IDs matching, over UDP 53.
echo "── TASK 2: Watch a DNS Query Happen ──"

echo ""
run_cmd "sudo timeout 6 tcpdump -i any -nn 'udp port 53' -c 6 > $SCRATCH/dns.txt 2>/dev/null & sleep 1; dig +short fedoraproject.org @1.1.1.1 >/dev/null; sleep 1"
run_cmd "head -4 $SCRATCH/dns.txt"
echo "  READ IT: 'A? fedoraproject.org' = the question; the reply line carries"
echo "  the answer count and IPs. The number before A? is the query ID — the"
echo "  reply must echo it (anti-spoofing, and how tcpdump pairs them for you)."
echo "  Note @1.1.1.1 was used ON PURPOSE: querying the local stub (127.0.0.53)"
echo "  stays on loopback and resolved may answer from cache — no packets at all."
echo "  A cache hit is INVISIBLE on the wire. Prove it:"
run_cmd "sudo timeout 4 tcpdump -i $IFACE -nn 'udp port 53' -c 2 > $SCRATCH/cached.txt 2>/dev/null & sleep 1; getent hosts fedoraproject.org >/dev/null; sleep 1; wc -l < $SCRATCH/cached.txt"
echo "  ^ likely 0 lines — resolved served it from cache; nothing left the box."

echo ""

# ── TASK 3: Filter Language — Ask Precise Questions ───────────────────────────
# Why it matters: real interfaces are firehoses. Unfiltered tcpdump on a busy
# box is noise; the filter language is what makes it a tool.
echo "── TASK 3: BPF Filters ──"

echo ""
echo "  The vocabulary (combine with and/or/not, group with parens):"
echo "    host 1.1.1.1        src/dst host X      net 192.168.1.0/24"
echo "    port 443            src/dst port X      portrange 8000-9000"
echo "    tcp / udp / icmp    'tcp[tcpflags] & tcp-syn != 0'  (SYNs only)"
echo ""
echo "[3a] Only YOUR https traffic, no LAN chatter — run a curl meanwhile:"
run_cmd "sudo timeout 6 tcpdump -i $IFACE -nn 'tcp port 443 and host 140.82.112.3 or (tcp port 443 and tcp[tcpflags] & tcp-syn != 0)' -c 6 > $SCRATCH/filtered.txt 2>/dev/null & sleep 1; curl -s -o /dev/null https://github.com; sleep 2; head -4 $SCRATCH/filtered.txt"
echo "  ^ only SYNs and github traffic survived the filter. Everything else"
echo "    never reached the output. Filters run IN THE KERNEL — cheap even"
echo "    on saturated links."

echo ""

# ── TASK 4: Capture Files — the -w / -r Workflow ──────────────────────────────
# Why it matters: production truth — capture NOW (cheap), analyze LATER
# (calm). Also the handoff format: a .pcap is what you'd attach to a ticket
# or open in Wireshark.
echo "── TASK 4: Write, Then Read, a pcap ──"

echo ""
run_cmd "sudo timeout 5 tcpdump -i lo -nn 'tcp port 8080' -w $SCRATCH/session.pcap 2>/dev/null & sleep 1; curl -s -o /dev/null http://127.0.0.1:8080/; curl -s -o /dev/null http://127.0.0.1:8080/nope; sleep 2"
run_cmd "sudo tcpdump -r $SCRATCH/session.pcap -nn 2>/dev/null | wc -l && sudo tcpdump -r $SCRATCH/session.pcap -nn -A 2>/dev/null | grep -E 'GET|HTTP/1' | head -4"
echo "  ^ -w wrote raw packets; -r replays them; -A dumps payload as ASCII —"
echo "    both HTTP requests and the 200/404 responses are readable in plain"
echo "    text. THIS is why 'HTTP is unencrypted' isn't abstract: anyone on"
echo "    the path reads it like you just did. TLS exists because of -A."

echo ""

# ── TASK 5: Close the Loop with ss ────────────────────────────────────────────
# Why it matters: ss shows connection STATE (the endpoints' view), tcpdump
# shows PACKETS (the wire's view). Fluency is moving between them at will.
echo "── TASK 5: Same Connection, Two Instruments ──"

echo ""
run_cmd "curl -s -o /dev/null http://127.0.0.1:8080/ & ss -tnp state established '( dport = :8080 or sport = :8080 )' 2>/dev/null | head -3"
run_cmd "ss -tlnp 2>/dev/null | grep 8080"
echo "  ^ LISTEN row = the server socket; established rows = live connections."
echo "    Triage order on a real 'service unreachable': ss -tlnp (is it"
echo "    listening?) → firewall (is it reachable?) → tcpdump (what do the"
echo "    packets actually say?). Each tool answers exactly one question."

echo ""

# ── CLEANUP ───────────────────────────────────────────────────────────────────
echo "── Cleanup ──"
run_cmd "kill \$(cat $SCRATCH/srv.pid) 2>/dev/null; rm -rf $SCRATCH"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  tcpdump Lab Complete — practiced on tp-mudd only:"
echo "  ✓ handshake read as sentences; RST vs silence = refused vs filtered"
echo "  ✓ DNS query/answer pairing on the wire; cache hits proven invisible"
echo "  ✓ BPF filters — kernel-side precision instead of firehose"
echo "  ✓ -w/-r/-A workflow; plaintext HTTP read off the wire"
echo "  ✓ ss (state) vs tcpdump (packets) — one triage, two instruments"
echo "════════════════════════════════════════════════════════"
