# 🛡️ wait_and_run.sh

**The "Smart Guard" for Process-Driven Automation.**

Ever had a script fire the moment a process flickered off, only for that process to restart a second later? Or had a script wait forever for a process that crashed into a zombie state?

`wait_and_run.sh` solves this by adding **Persistence** (confirmation the process is actually gone) and a **Safety Timeout** (a maximum wait limit).

---

## 📖 The Story

Imagine you are running a heavy `ffmpeg` render. You want the computer to go to sleep when it's done. 
1. **The Problem:** `ffmpeg` might finish one file and take 3 seconds to start the next. A basic script would see `ffmpeg` is "gone" and shut down the PC mid-render. 
2. **The Solution:** You set `WAIT_PERSISTENCE=10`. Now, the script must see the process is gone for **10 consecutive seconds** before it believes it's truly finished.
3. **The Backup:** You set `WAIT_TIMEOUT=7200`. If your render gets stuck in an infinite loop or a prompt, the script will force the "goodnight" command after 2 hours anyway, so your power isn't wasted all night.

---

## ⚙️ Configuration

Control the behavior using these Environment Variables:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `WAIT_PERSISTENCE` | `10` | Seconds the process must be absent before the command triggers. |
| `WAIT_TIMEOUT` | `0` | Total seconds to wait before giving up and running the command anyway (0 = infinite). |

---

## 🚀 Usage

### The "Goodnight" Wrapper
The most common use case is waiting for a task to finish before system sleep:
```bash
# Wait for ffmpeg to stay gone for 10s, then sleep
wait_and_goodnight "ffmpeg" "07:30"

```

### The Power User Mix

Wait for a sync to finish, but give up after 30 minutes regardless:

```bash
WAIT_PERSISTENCE=30 WAIT_TIMEOUT=1800 wait_and_run "rsync" "./cleanup.sh"

```

---

## 🛠️ Internal Logic

1. **Sudo Shield:** Automatically keeps your `sudo` credentials alive in the background so the final command doesn't hang on a password prompt after 4 hours of waiting.
2. **Polling:** Checks for the process every 5 seconds.
3. **The Countdown:** Once the process disappears, it switches to a 1-second "verification" mode. If the process reappears for even a moment, the persistence timer resets.
4. **Cleanup:** Kills all background "keep-alive" tasks immediately upon execution or exit.

---

## 📝 Technical Notes

* **Process Matching:** Uses `pgrep -x`, so it matches the *exact* process name.
* **Engine:** Uses `eval`, allowing you to pass complex strings, bash functions, or multi-stage commands as the second argument.
