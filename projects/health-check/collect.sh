#!/bin/bash
# collect.sh — Gathers raw system metrics and writes to /tmp/mudd_snapshot.txt
# Part of mudd_health: System Health Monitor
# Usage: bash collect.sh

OUTFILE="/tmp/mudd_snapshot.txt"

echo "=== MUDD HEALTH SNAPSHOT ===" > $OUTFILE
echo "timestamp=$(date +%s)" >> $OUTFILE

# CPU usage — extract idle % from mpstat, calculate used
CPU_IDLE=$(mpstat 1 1 | awk '/Average/ {print $12}')
CPU_USED=$(echo "100 - $CPU_IDLE" | bc)
echo "cpu_used=$CPU_USED" >> $OUTFILE

# Memory — total and available in MB
MEM_TOTAL=$(free -m | awk '/^Mem/ {print $2}')
MEM_AVAIL=$(free -m | awk '/^Mem/ {print $7}')
MEM_USED=$(( MEM_TOTAL - MEM_AVAIL ))
MEM_PCT=$(echo "scale=1; ($MEM_USED / $MEM_TOTAL) * 100" | bc)
echo "mem_total=$MEM_TOTAL" >> $OUTFILE
echo "mem_used=$MEM_USED" >> $OUTFILE
echo "mem_pct=$MEM_PCT" >> $OUTFILE

# Disk — used % on root partition
DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
echo "disk_pct=$DISK_PCT" >> $OUTFILE

# Load average — 1-minute
LOAD_1=$(cat /proc/loadavg | awk '{print $1}')
echo "load_1=$LOAD_1" >> $OUTFILE

# Uptime in seconds
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime)
echo "uptime_sec=$UPTIME_SEC" >> $OUTFILE

# Top 3 CPU-consuming processes
echo "top_procs=$(ps aux --sort=-%cpu | awk 'NR>1 && NR<=4 {print $11":"$3}' | tr '\n' ',')" >> $OUTFILE

echo "[collect.sh] Snapshot written to $OUTFILE"