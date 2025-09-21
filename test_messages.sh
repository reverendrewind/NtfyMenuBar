#!/bin/bash

# Test script for NtfyMenuBar message filtering
# This script sends various messages to test topic and priority filtering

SERVER="https://ntfy.2137.wtf"
USERNAME="rimskij"
PASSWORD="?4D0n41!"

echo "🧪 Testing NtfyMenuBar message filtering..."
echo "Sending messages to $SERVER"
echo

# Test different topics and priorities
declare -a topics=("proxmox" "server" "backup" "security" "monitoring" "alerts")
declare -a priorities=(1 2 3 4 5)
declare -a messages=(
    "System backup completed successfully"
    "High CPU usage detected on VM-101"
    "Security scan finished - no threats found"
    "Database backup failed - check logs"
    "Network connectivity restored"
    "Disk space warning - 85% full"
    "Service restart required"
    "Update available for Proxmox VE"
    "SSL certificate expires in 30 days"
    "Replication job completed"
    "Container LXC-200 stopped unexpectedly"
    "Memory usage critical on node-02"
    "Firewall rules updated"
    "Scheduled maintenance in 2 hours"
    "Performance monitoring alert"
)

declare -a tags=(
    "urgent,critical"
    "warning,system"
    "info,success"
    "error,fail"
    "network,connection"
    "storage,disk"
    "maintenance,scheduled"
    "security,auth"
    "backup,database"
    "performance,cpu"
    "docker,container"
    "ssl,certificate"
    "proxmox,pve"
    "vm,virtual"
    "lxc,container"
)

# Function to send message
send_message() {
    local topic=$1
    local priority=$2
    local message=$3
    local tag=$4
    local title=$5

    echo "📤 Sending: [$topic] Priority $priority - $message"

    curl -s -u "$USERNAME:$PASSWORD" \
        -H "Priority: $priority" \
        -H "Title: $title" \
        -H "Tags: $tag" \
        -d "$message" \
        "$SERVER/$topic"

    echo
    sleep 1
}

# Send test messages
echo "🚀 Sending test messages..."
echo

# Critical system alerts
send_message "proxmox" 5 "CRITICAL: Node-01 is down - immediate attention required!" "urgent,critical,server" "🚨 System Critical"
send_message "security" 5 "SECURITY BREACH: Unauthorized access detected" "urgent,security,breach" "🔒 Security Alert"
send_message "backup" 4 "Backup failed for VM-105 - manual intervention needed" "error,backup,fail" "❌ Backup Failed"

# High priority operational messages
send_message "monitoring" 4 "High memory usage on node-02 (92%)" "warning,memory,performance" "⚠️ Memory Warning"
send_message "server" 4 "Service outage detected - investigating" "warning,service,outage" "🔧 Service Issue"
send_message "alerts" 4 "Disk space critical on storage-01 (95% full)" "warning,disk,storage" "💿 Storage Alert"

# Normal priority informational messages
send_message "proxmox" 3 "VM-203 started successfully" "info,vm,success" "✅ VM Started"
send_message "backup" 3 "Daily backup completed for all VMs" "info,backup,success" "📦 Backup Complete"
send_message "monitoring" 3 "System health check passed" "info,health,success" "💚 Health Check"
send_message "server" 3 "Load balancer configuration updated" "info,network,config" "🌐 Config Updated"

# Low priority maintenance messages
send_message "security" 2 "SSL certificate renewal scheduled" "info,ssl,maintenance" "📄 SSL Renewal"
send_message "proxmox" 2 "Weekly maintenance window starts in 24h" "info,maintenance,scheduled" "🔧 Maintenance"
send_message "monitoring" 2 "Performance report generated" "info,report,analytics" "📊 Report Ready"

# Minimal priority logs
send_message "server" 1 "Log rotation completed" "info,logs,maintenance" "📝 Logs Rotated"
send_message "backup" 1 "Archive cleanup completed" "info,cleanup,storage" "🗑️ Cleanup Done"

echo
echo "✅ Test messages sent successfully!"
echo
echo "📋 Test scenarios covered:"
echo "   • 5 different topics: proxmox, security, backup, monitoring, server, alerts"
echo "   • All priority levels: 1 (min) to 5 (max)"
echo "   • Various tags for emoji testing"
echo "   • Different message types: critical, warnings, info, maintenance"
echo
echo "🔍 You can now test filtering in NtfyMenuBar:"
echo "   • Filter by specific topics (proxmox, security, etc.)"
echo "   • Filter by priority levels (1-5)"
echo "   • Test grouping by topic and priority"
echo "   • Search for specific keywords"
echo
echo "💡 Additional manual test suggestions:"
echo "   • Test multi-selection in topic dropdown"
echo "   • Test multi-selection in priority dropdown"
echo "   • Test 'Clear filters' functionality"
echo "   • Test grouping mode switching"
echo "   • Test search with various keywords"