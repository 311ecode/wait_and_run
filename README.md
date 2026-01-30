# wait_and_run.sh

## Environment Variables
- **`WAIT_PERSISTENCE`** (optional, default: `10`): Seconds the process must be gone before acting.
- **`WAIT_TIMEOUT`** (optional): Maximum total seconds to wait before forcing execution regardless of process state.

## Usage with Timeout
```bash
# Wait for ffmpeg, but force 'goodnight' after 2 hours (7200s) even if still running
WAIT_TIMEOUT=7200 wait_and_run "ffmpeg" "goodnight 07:30"

```

