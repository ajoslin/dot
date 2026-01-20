#!/bin/bash
# Start voice input daemon in background

LOG_FILE="/tmp/opencode-voice.log"
PID_FILE="/tmp/opencode-voice.pid"

# Check if already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "⚠️  Voice input already running (PID: $PID)"
        exit 0
    else
        # Clean up stale PID file
        rm "$PID_FILE"
    fi
fi

# Start the daemon
echo "🎤 Starting voice input daemon..."
nohup python3 ~/.config/opencode/voice-input.py > "$LOG_FILE" 2>&1 &
PID=$!

# Save PID
echo $PID > "$PID_FILE"

# Wait a moment to check if it started successfully
sleep 1

if ps -p $PID > /dev/null 2>&1; then
    echo "✅ Voice input started (PID: $PID)"
    echo "📋 Logs: tail -f $LOG_FILE"
else
    echo "❌ Failed to start voice input"
    echo "Check logs: cat $LOG_FILE"
    rm "$PID_FILE" 2>/dev/null
    exit 1
fi
