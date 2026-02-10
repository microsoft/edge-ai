#!/bin/sh

# Run the multi_trigger binary that handles both alert and analytics_disabled messages
./multi_trigger &
TRIGGER_PID=$!

# Wait for the process to exit
wait $TRIGGER_PID

# Exit with status 0
exit 0
