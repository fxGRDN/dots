#!/bin/bash
updates=$(checkupdates 2>/dev/null | wc -l)
if [ "$updates" -gt 0 ]; then
    echo "{\"text\": \"$updates\", \"class\": \"updates\", \"tooltip\": \"Pending updates: $updates\"}"
else
    # Output nothing
    echo ""
fi

