# 🧸 VICKY · THE BABYSITTER  
### Rootless System Integrity Daemon for Termux (Android)

> **A system by GRANT “FEZZY” FESTERS**  
> BOJACK · SOI · RAVENSMEAD — embedded in every scan

---

## 🧠 OVERVIEW

Vicky is a **rootless, silent, modular system integrity daemon** built for Termux on Android.

She monitors.  
She audits.  
She reports.  

And then she disappears.

No popups.  
No interference.  
No automated “fixes” that break your setup.

Just **truth about your system — on demand.**

---

## ⚡ CORE IDEA

Most Termux environments slowly degrade:

• packages drift out of sync  
• scripts break silently  
• permissions get messy  
• configs stack on top of forgotten configs  

Vicky exists to stop that decay.

Not by controlling your system —  
but by **making it fully visible again.**

---

## 🧸 PHILOSOPHY

Vicky follows strict rules:

• **Rootless only** — runs on stock Android  
• **Silent by default** — no noise unless called  
• **Modular design** — every check is isolated  
• **User authority** — nothing changes without you  
• **Readable output** — no cryptic logs  

She is not an AI.  
She is not automation.  

She is a **watcher.**

---

## 📦 INSTALLATION

Clone the repository:

```bash
git clone https://github.com/philfesters/vicky.git
cd vicky
```

Or with SSH:

```bash
git clone git@github.com:philfesters/vicky.git
cd vicky
```

Run directly:

```bash
bash vicky.sh
```

---

🚀 EXECUTION MODES

FULL SYSTEM SCAN

```bash
bash ~/vicky.sh
```

Runs all 23 fairies across the system.

SUMMARY MODE

```bash
bash ~/vicky.sh summary
```

Displays last known system state.

WATCH MODE (DAEMON LOOP)

```bash
bash ~/vicky.sh watch
```

Runs continuous audits in the background.
Default interval: 5 minutes.

QUEUE MODE (SELECTIVE)

```bash
bash ~/vicky.sh queue
```

Choose specific fairies. Skip heavy checks.

---

🎭 ALIASES (FAST ACCESS)

Edit your .bashrc:

```bash
nano ~/.bashrc
```

Add these three lines:

```bash
alias vicky='bash ~/vicky.sh'
alias vicky-watch='bash ~/vicky.sh watch'
alias vicky-quick='bash ~/vicky.sh queue'
```

Save (Ctrl+O, Enter, Ctrl+X) and reload:

```bash
source ~/.bashrc
```

Now you can use:

Alias What it does
vicky Full 23‑fairy scan
vicky-watch Continuous monitoring loop
vicky-quick Queue builder (fast mode)

---

👁️ WATCH CONFIG

Set a custom interval (in seconds):

```bash
export VICKY_WATCH_INTERVAL=600
```

Vicky logs quietly.
No interruptions.
You check when you want.

---

🧸 THE 23 FAIRIES

Each fairy is a self-contained audit module:

Fairy Role
timmy Dependency Scanner
cosmo Git Sync Status
wanda Storage Health
poof Network Check
crocker Security Sweep
sparky Battery & Device
jorgen Permissions
tooth Cache Cleaner
anticosmo Broken Links
cupid API Reachability
binky Running Processes
juandissimo Theme Integrity
blonda Media Files
trixie Session / Uptime
chester Package Updates
veronica Backup Validation
aj Script Integrity
wisteria Python Environment
poofjr SSH Keys
schnookie Cron Jobs
neptunia Logs
remy Environment Variables
turbo Memory & Swap

---

⚙️ ADVANCED CONFIG

```bash
export VICKY_STATION_PATTERN="myscript.sh"
export VICKY_EXTRA_SCRIPTS="foo.sh bar.sh"
export VICKY_SKIP_FAIRIES="cosmo poof"
export VICKY_WATCH_INTERVAL=600
```

---

🧩 ARCHITECTURE

Vicky is built as:

• Single entry script (vicky.sh)
• Modular function blocks (fairies)
• Stateless execution model
• File‑based logging
• Zero external services

No cloud.
No tracking.
No dependencies beyond Termux basics.

---

🧠 ECOSYSTEM (FEZZY STATION)

Vicky operates inside a larger system:

• Albert → error detection & anomaly alerts
• Sentinel → threat scanning & security focus
• K9 Daemon → persistent background observer

Together they form a lightweight command environment.

---

🚫 REQUIREMENTS

• Android device
• Termux installed
• Basic packages (bash, coreutils, etc.)

No root required.
No kernel mods.

---

🧾 LICENSE

MIT License — use it, modify it, break it, rebuild it.

---

🐙 REPOSITORY

https://github.com/philfesters/vicky

---

🧙 SIGNATURE

GRANT “FEZZY” FESTERS
BOJACK · SOI · RAVENSMEAD

“My name must travel — and with Vicky, it does.”

---

🧸 FINAL STATE

Vicky does not shut down.
She returns to idle.

Fairies dismissed.
System observed.
Nothing forgotten.

```