#!/data/data/com.termux/files/usr/bin/bash
# ================================================================
#  VICKY  ·  System Integrity Daemon  ·  V4
#  Codename  : The Babysitter
#  Platform  : Termux (Android) — rootless — no root required
#  License   : MIT — open source, share freely
#  ----------------------------------------------------------------
#  23 Fairies. One Verdict. No excuses.
#  Run:  bash vicky.sh         — full scan
#  Run:  bash vicky.sh summary — quick status line
#  Run:  bash vicky.sh <fairy> — run one fairy only
#  Run:  bash vicky.sh watch   — continuous monitoring loop
#  Run:  bash vicky.sh export  — save report to file
# ================================================================

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  CONFIG — safe to push to GitHub as-is.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VICKY_K9="${VICKY_K9:-Daemon}"
VICKY_BRAND="${VICKY_BRAND:-System Integrity Daemon · V4}"

# Station script to audit in fairy_aj (auto-detected if blank)
VICKY_STATION_PATTERN="${VICKY_STATION_PATTERN:-}"

# Extra scripts to audit in fairy_aj (space-separated names in $HOME)
VICKY_EXTRA_SCRIPTS="${VICKY_EXTRA_SCRIPTS:-}"

# Backup suffix patterns fairy_veronica looks for in ~/storage/downloads
VICKY_BACKUP_SUFFIX="${VICKY_BACKUP_SUFFIX:-_BK.sh _BK}"

# Watch mode interval in seconds
VICKY_WATCH_INTERVAL="${VICKY_WATCH_INTERVAL:-300}"

# Fairies to skip (space-separated names)
VICKY_SKIP_FAIRIES="${VICKY_SKIP_FAIRIES:-}"
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ── PALETTE ─────────────────────────────────────────────────────
HOT=$'\033[38;5;198m'
PURP=$'\033[38;5;135m'
CYN=$'\033[38;5;51m'
GRN=$'\033[38;5;82m'
RED=$'\033[38;5;196m'
YEL=$'\033[38;5;226m'
WHT=$'\033[38;5;231m'
ORG=$'\033[38;5;208m'
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
TEAL=$'\033[38;5;45m'
LIME=$'\033[38;5;118m'

PASS=0; WARN=0; FAIL=0
REPORT_DIR="$HOME/.vicky"
REPORT_FILE="$REPORT_DIR/last_report.log"
HISTORY_DIR="$REPORT_DIR/history"
mkdir -p "$REPORT_DIR" "$HISTORY_DIR"

_line()   { printf "${PURP}%s${RESET}\n" "  ──────────────────────────────────────────────────────"; }
_pass()   { echo -e "  ${GRN}${BOLD}[  OK  ]${RESET}  $1"; PASS=$((PASS+1)); }
_warn()   { echo -e "  ${YEL}${BOLD}[ WARN ]${RESET}  $1"; WARN=$((WARN+1)); }
_fail()   { echo -e "  ${RED}${BOLD}[ FAIL ]${RESET}  $1"; FAIL=$((FAIL+1)); }
_info()   { echo -e "  ${CYN}[ INFO ]${RESET}  $1"; }
_head()   { echo -e "\n${HOT}${BOLD}  ▸ $1${RESET}"; _line; }
_skip()   { echo -e "  ${DIM}[ SKIP ]  $1${RESET}"; }

# ── SKIP HELPER ──────────────────────────────────────────────────
_should_skip() {
    local name="${1,,}"
    for s in $VICKY_SKIP_FAIRIES; do
        [[ "${s,,}" == "$name" ]] && return 0
    done
    return 1
}

# ── FAIRY ROSTER ─────────────────────────────────────────────────
declare -A FAIRY_DESC=(
    [timmy]="Dependency Scanner"
    [cosmo]="GitHub Sync Checker"
    [wanda]="Storage Health"
    [poof]="Network Connectivity"
    [crocker]="Security Sweep"
    [sparky]="Device & Battery Status"
    [jorgen]="Permission Enforcer"
    [tooth]="Cache Cleaner"
    [anticosmo]="Broken Link Monitor"
    [cupid]="API Connectivity"
    [binky]="Process Monitor"
    [juandissimo]="Theme Auditor"
    [blonda]="Media Scanner"
    [trixie]="Session & Uptime Monitor"
    [chester]="Package Update Scanner"
    [veronica]="Backup Integrity Checker"
    [aj]="Script Auditor"
    [wisteria]="Python Environment Auditor"
    [poofjr]="SSH Key Inspector"
    [schnookie]="Cron Job Auditor"
    [neptunia]="Log File Monitor"
    [remy]="Environment Variable Checker"
    [turbo]="Memory & Swap Monitor"
)

FAIRY_ORDER=(timmy cosmo wanda poof crocker sparky jorgen tooth anticosmo cupid
             binky juandissimo blonda trixie chester veronica aj
             wisteria poofjr schnookie neptunia remy turbo)

QUICK_FAIRIES=(timmy wanda crocker sparky jorgen tooth anticosmo binky blonda trixie veronica aj remy turbo)
NETWORK_SKIP=(cosmo poof chester cupid)

_print_roster() {
    local c; c=$(tput cols 2>/dev/null || echo 60)
    echo -e "${PURP}${BOLD}"
    printf "  %-14s %-28s  %-14s %-28s\n" "FAIRY" "ROLE" "FAIRY" "ROLE"
    printf "  %s\n" "$(printf '%0.s─' $(seq 1 $(( c - 4 ))))"
    echo -e "${RESET}"
    local i=0
    local row=()
    for fairy in "${FAIRY_ORDER[@]}"; do
        local num=$(( i + 1 ))
        local label; printf -v label "%02d · %-12s" "$num" "$fairy"
        local desc="${FAIRY_DESC[$fairy]}"
        row+=("$label" "$desc")
        if (( ${#row[@]} == 4 )); then
            printf "  ${CYN}%-17s${RESET} ${WHT}%-26s${RESET}  ${CYN}%-17s${RESET} ${WHT}%-26s${RESET}\n" \
                "${row[0]}" "${row[1]}" "${row[2]}" "${row[3]}"
            row=()
        fi
        (( i++ ))
    done
    if (( ${#row[@]} > 0 )); then
        printf "  ${CYN}%-17s${RESET} ${WHT}%-26s${RESET}\n" "${row[0]}" "${row[1]}"
    fi
    local c2; c2=$(tput cols 2>/dev/null || echo 60)
    echo -e "${PURP}  $(printf '%0.s─' $(seq 1 $(( c2 - 4 ))))${RESET}"
    echo
}

vicky_boot() {
    clear
    echo -e "${HOT}${BOLD}"
    cat << 'VICKY_ASCII'

  ██╗   ██╗██╗ ██████╗██╗  ██╗██╗   ██╗
  ██║   ██║██║██╔════╝██║ ██╔╝╚██╗ ██╔╝
  ██║   ██║██║██║     █████╔╝  ╚████╔╝ 
  ╚██╗ ██╔╝██║██║     ██╔═██╗   ╚██╔╝  
   ╚████╔╝ ██║╚██████╗██║  ██╗   ██║   
    ╚═══╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝  

VICKY_ASCII
    echo -e "${RESET}"
    echo -e "${PURP}${BOLD}  ════════════════════════════════════════════════════${RESET}"
    echo -e "${WHT}${BOLD}       S Y S T E M   I N T E G R I T Y   D A E M O N${RESET}"
    echo -e "${PURP}${BOLD}  ════════════════════════════════════════════════════${RESET}"
    echo
    echo -e "${DIM}${CYN}       Codename  : The Babysitter  ·  V4${RESET}"
    echo -e "${DIM}${HOT}       K9 Daemon : ${VICKY_K9}  [ ACTIVE ]${RESET}"
    echo -e "${DIM}${WHT}       Protocol  : ${VICKY_BRAND}${RESET}"
    echo
    echo -e "${PURP}${BOLD}  ════════════════════════════════════════════════════${RESET}"
    echo
    echo -e "${CYN}${BOLD}  FAIRY ROSTER — 23 DEPLOYED${RESET}"
    echo
    _print_roster
    echo -e "  ${WHT}${BOLD}23 Fairies standing by.  ${VICKY_K9} watching.${RESET}"
    echo
    echo -e "  ${HOT}${BOLD}[ENTER]${RESET}  Full scan — all 23 fairies"
    echo -e "  ${PURP}${BOLD}[Q]${RESET}     Queue builder — choose your fairies"
    echo -e "  ${CYN}${BOLD}[S]${RESET}     Quick scan — skip network fairies"
    echo -e "  ${CYN}${BOLD}[D]${RESET}     Deep scan — full 23, verbose"
    echo -e "  ${DIM}[E]${RESET}     Export last report to downloads"
    echo -e "  ${DIM}[X]${RESET}     Exit — fairies dismissed"
    echo
    printf "  ${PURP}${BOLD}» ${RESET}"
    read -r _boot_choice

    case "${_boot_choice^^}" in
        X)
            echo
            echo -e "  ${PURP}Vicky stands down. Fairies dismissed.${RESET}"
            echo -e "  ${DIM}${WHT}${VICKY_K9} is still watching though.${RESET}"
            echo
            exit 0
            ;;
        S)
            VICKY_SKIP_FAIRIES="$VICKY_SKIP_FAIRIES cosmo poof chester cupid"
            clear
            ;;
        D)
            clear
            ;;
        Q)
            vicky_queue
            exit 0
            ;;
        E)
            vicky_export
            exit 0
            ;;
        *)
            clear
            ;;
    esac
}

# ── QUEUE BUILDER ────────────────────────────────────────────────
vicky_queue() {
    clear
    echo -e "\n${HOT}${BOLD}  QUEUE BUILDER${RESET}"
    echo -e "${PURP}  ════════════════════════════════════════════════════${RESET}"
    echo -e "${DIM}  Type fairy names or numbers to add. Separate with spaces."
    echo -e "  Type 'all' for all 23. Type 'quick' for fast-only. Type 'done' to run.${RESET}"
    echo
    _print_roster

    local queue=()
    while true; do
        echo -e "  ${CYN}Current queue:${RESET}  ${WHT}${queue[*]:-empty}${RESET}"
        echo
        printf "  ${PURP}» Add fairy (name/number) or 'done': ${RESET}"
        read -r _input

        case "${_input,,}" in
            done|run)
                [[ ${#queue[@]} -eq 0 ]] && { echo -e "  ${YEL}Queue is empty. Exiting.${RESET}"; echo; return; }
                break
                ;;
            all)
                queue=("${FAIRY_ORDER[@]}")
                echo -e "  ${GRN}All 23 fairies added.${RESET}"
                ;;
            quick)
                queue=("${QUICK_FAIRIES[@]}")
                echo -e "  ${GRN}Quick scan fairies added (no network).${RESET}"
                ;;
            clear|reset)
                queue=()
                echo -e "  ${YEL}Queue cleared.${RESET}"
                ;;
            *)
                for token in $_input; do
                    if [[ "$token" =~ ^[0-9]+$ ]]; then
                        local idx=$(( token - 1 ))
                        if (( idx >= 0 && idx < ${#FAIRY_ORDER[@]} )); then
                            local fname="${FAIRY_ORDER[$idx]}"
                            queue+=("$fname")
                            echo -e "  ${GRN}Added:${RESET} $fname · ${FAIRY_DESC[$fname]}"
                        else
                            echo -e "  ${YEL}No fairy at number $token${RESET}"
                        fi
                    else
                        local found=0
                        for f in "${FAIRY_ORDER[@]}"; do
                            if [[ "${f,,}" == "${token,,}" ]]; then
                                queue+=("$f")
                                echo -e "  ${GRN}Added:${RESET} $f · ${FAIRY_DESC[$f]}"
                                found=1
                                break
                            fi
                        done
                        [[ $found -eq 0 ]] && echo -e "  ${YEL}Unknown fairy: $token${RESET}"
                    fi
                done
                ;;
        esac
        echo
    done

    clear
    PASS=0; WARN=0; FAIL=0
    echo -e "\n${PURP}${BOLD}  QUEUE RUNNING — ${#queue[@]} FAIRIES DEPLOYED${RESET}\n"
    for fairy in "${queue[@]}"; do
        "fairy_${fairy//-/}" 2>/dev/null || echo -e "  ${YEL}[ SKIP ] Unknown function: fairy_${fairy}${RESET}"
    done
    vicky_report
}

# ══════════════════════════════════════════════════════════════════
#  FAIRIES 1–17
# ══════════════════════════════════════════════════════════════════

fairy_timmy() {
    _should_skip "timmy" && { _skip "FAIRY TIMMY — Dependency Scanner"; return; }
    _head "FAIRY TIMMY  ·  Dependency Scanner"

    local core_deps=(git curl python python3 ffmpeg fzf dialog termux-api aria2c wget vim mpv jq zip unzip)
    _info "Checking core tools..."
    for dep in "${core_deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            _pass "$dep  — present  ($(command -v "$dep"))"
        else
            local dpkg_chk; dpkg_chk=$(dpkg -s "$dep" 2>/dev/null | grep "Status:" || echo "")
            if [[ "$dpkg_chk" == *"install ok installed"* ]]; then
                _pass "$dep  — installed (dpkg verified, not in PATH)"
            else
                _fail "$dep  — not installed  · Fix: pkg install $dep"
            fi
        fi
    done

    echo ""
    _info "Checking extended toolkit..."
    local ext_deps=(ranger ncdu htop tmux nano ssh gpg openssl bc)
    for dep in "${ext_deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 \
            && _pass "$dep  — available" \
            || _warn "$dep  — missing  · optional: pkg install $dep"
    done

    echo ""
    _info "Version audit..."
    command -v python3 >/dev/null 2>&1 && _info "python3  : $(python3 --version 2>&1)"
    command -v git     >/dev/null 2>&1 && _info "git      : $(git --version 2>&1)"
    command -v ffmpeg  >/dev/null 2>&1 && _info "ffmpeg   : $(ffmpeg -version 2>/dev/null | head -1)"
    echo
}

fairy_cosmo() {
    _should_skip "cosmo" && { _skip "FAIRY COSMO — GitHub Sync Checker"; return; }
    _head "FAIRY COSMO  ·  GitHub Sync Checker"

    if ! command -v git >/dev/null 2>&1; then
        _fail "Git not installed — Cosmo is lost"; echo; return
    fi

    local git_user; git_user=$(git config --global user.name 2>/dev/null)
    [[ -n "$git_user" ]] && _pass "git user.name  — configured" || _warn "git user.name  — not configured  · git config --global user.name 'Name'"

    echo ""
    _info "Scanning repositories in $HOME..."
    local repos
    repos=$(find "$HOME" -maxdepth 3 -name ".git" -type d 2>/dev/null | xargs -I{} dirname {} 2>/dev/null)
    if [[ -z "$repos" ]]; then
        _info "No repositories found in home directory (searched 3 levels)"; echo; return
    fi

    local repo_count=0
    while IFS= read -r repo; do
        [[ -z "$repo" ]] && continue
        (( repo_count++ ))
        local name; name=$(basename "$repo")
        local branch; branch=$(git -C "$repo" branch --show-current 2>/dev/null || echo "detached")
        local remote; remote=$(git -C "$repo" remote get-url origin 2>/dev/null || echo "none")
        local uncommitted; uncommitted=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l)

        if [[ "$remote" == "none" ]]; then
            _warn "$name  — no remote configured"
        else
            git -C "$repo" fetch --quiet 2>/dev/null
            local diff; diff=$(git -C "$repo" rev-list HEAD...origin/"$branch" --count 2>/dev/null || echo "?")
            if [[ "$diff" == "0" ]]; then
                _pass "$name ($branch)  — in sync with remote"
            elif [[ "$diff" == "?" ]]; then
                _warn "$name  — cannot reach remote"
            else
                _warn "$name ($branch)  — ${diff} commit(s) behind remote"
            fi
        fi

        [[ "$uncommitted" -gt 0 ]] && _warn "$name  — ${uncommitted} uncommitted change(s)"

    done <<< "$repos"
    [[ "$repo_count" -eq 0 ]] && _info "No git repos found"
    echo
}

fairy_wanda() {
    _should_skip "wanda" && { _skip "FAIRY WANDA — Storage Health"; return; }
    _head "FAIRY WANDA  ·  Storage Health"

    local disk; disk=$(df -h "$HOME" | awk 'NR==2 {print $3" used of "$2"  ("$5" full)"}')
    local used_pct; used_pct=$(df "$HOME" | awk 'NR==2 {gsub(/%/,""); print $5}')
    _info "Home partition: $disk"

    if [[ "$used_pct" -gt 90 ]]; then
        _fail "Storage above 90%  — CRITICAL — clear space immediately"
    elif [[ "$used_pct" -gt 80 ]]; then
        _fail "Storage above 80%  — getting tight — run pkg clean and clear downloads"
    elif [[ "$used_pct" -gt 70 ]]; then
        _warn "Storage above 70%  — keep an eye on it"
    else
        _pass "Storage levels healthy  — ${used_pct}% used"
    fi

    if [[ -d "$HOME/storage/downloads" ]]; then
        local dl_size; dl_size=$(du -sh "$HOME/storage/downloads" 2>/dev/null | cut -f1)
        _info "Downloads folder: $dl_size"
        local largest; largest=$(du -sh "$HOME/storage/downloads"/*/ 2>/dev/null | sort -rh | head -3)
        if [[ -n "$largest" ]]; then
            _info "Largest subfolders:"
            while IFS= read -r line; do
                _info "  └ $line"
            done <<< "$largest"
        fi
    fi

    local inode_pct; inode_pct=$(df -i "$HOME" 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}')
    if [[ -n "$inode_pct" && "$inode_pct" =~ ^[0-9]+$ ]]; then
        [[ "$inode_pct" -gt 80 ]] && _warn "Inode usage: ${inode_pct}%  — many small files" || _pass "Inode usage: ${inode_pct}%  — healthy"
    fi

    local prefix_size; prefix_size=$(du -sh "$PREFIX" 2>/dev/null | cut -f1)
    [[ -n "$prefix_size" ]] && _info "Termux prefix ($PREFIX): $prefix_size"
    echo
}

fairy_poof() {
    _should_skip "poof" && { _skip "FAIRY POOF — Network Connectivity"; return; }
    _head "FAIRY POOF  ·  Network Connectivity"

    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        _pass "Internet (Google DNS)  — reachable"
    elif ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
        _pass "Internet (Cloudflare DNS)  — reachable"
    else
        _fail "Internet  — unreachable  — check WiFi or mobile data"
    fi

    local services=(
        "api.github.com|GitHub API"
        "pypi.org|PyPI"
        "registry.npmjs.org|npm Registry"
        "packages.termux.dev|Termux Packages"
    )
    for entry in "${services[@]}"; do
        local host="${entry%%|*}" label="${entry##*|}"
        if curl -s --max-time 5 "https://${host}" >/dev/null 2>&1; then
            _pass "${label}  — reachable"
        else
            _warn "${label} (${host})  — unreachable or slow"
        fi
    done

    if command -v nslookup >/dev/null 2>&1; then
        nslookup github.com >/dev/null 2>&1 \
            && _pass "DNS resolution  — working" \
            || _warn "DNS resolution  — possible issue"
    fi
    echo
}

fairy_crocker() {
    _should_skip "crocker" && { _skip "FAIRY CROCKER — Security Sweep"; return; }
    _head "FAIRY CROCKER  ·  Security Sweep"

    local bashrc="$HOME/.bashrc"
    local hash_file="$REPORT_DIR/.bashrc.hash"
    if [[ -f "$bashrc" ]]; then
        local current_hash; current_hash=$(sha256sum "$bashrc" | cut -d' ' -f1)
        if [[ -f "$hash_file" ]]; then
            local stored_hash; stored_hash=$(<"$hash_file")
            if [[ "$current_hash" == "$stored_hash" ]]; then
                _pass ".bashrc  — untampered since last scan"
            else
                _warn ".bashrc  — MODIFIED since last scan  (update baseline with: vicky crocker)"
                echo "$current_hash" > "$hash_file"
            fi
        else
            echo "$current_hash" > "$hash_file"
            _info ".bashrc  — baseline stored (first run)"
        fi
    else
        _warn ".bashrc  — not found at $bashrc"
    fi

    local ww; ww=$(find "$HOME" -maxdepth 3 -type f -perm -o+w 2>/dev/null | wc -l)
    [[ "$ww" -gt 0 ]] && _warn "$ww world-writable file(s) detected in \$HOME" || _pass "No world-writable files found"

    local suid; suid=$(find "$HOME" -maxdepth 3 -type f -perm /4000 2>/dev/null | wc -l)
    [[ "$suid" -gt 0 ]] && _warn "$suid SUID file(s) detected" || _pass "No SUID files in home"

    local big; big=$(find "$HOME" -type f -size +50M 2>/dev/null | wc -l)
    [[ "$big" -gt 0 ]] && _info "$big large files (>50MB) in home" || _pass "No oversized files lurking"

    if [[ -d "$HOME/.ssh" ]]; then
        local ssh_perm; ssh_perm=$(stat -c '%a' "$HOME/.ssh" 2>/dev/null)
        if [[ "$ssh_perm" == "700" ]]; then
            _pass ".ssh directory  — permissions correct (700)"
        else
            _warn ".ssh directory  — permissions $ssh_perm  (should be 700)  · chmod 700 ~/.ssh"
        fi
        for key in "$HOME/.ssh"/id_*; do
            [[ -f "$key" ]] || continue
            local kperm; kperm=$(stat -c '%a' "$key" 2>/dev/null)
            [[ "$kperm" == "600" ]] && _pass "$(basename "$key")  — permissions correct (600)" \
                || _warn "$(basename "$key")  — permissions $kperm  (should be 600)  · chmod 600 $key"
        done
    fi

    local init_files=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    for f in "${init_files[@]}"; do
        [[ -f "$f" ]] || continue
        if grep -qE 'curl.*\|.*bash|wget.*\|.*bash|eval.*\$\(' "$f" 2>/dev/null; then
            _warn "$(basename "$f")  — contains curl/wget pipe-to-bash pattern  — review manually"
        fi
    done
    echo
}

fairy_sparky() {
    _should_skip "sparky" && { _skip "FAIRY SPARKY — Device & Battery Status"; return; }
    _head "FAIRY SPARKY  ·  Device & Battery Status"

    if command -v termux-battery-status >/dev/null 2>&1; then
        local batt_json; batt_json=$(timeout 4 termux-battery-status 2>/dev/null)
        if [[ -n "$batt_json" ]]; then
            local pct; pct=$(echo "$batt_json" | grep -o '"percentage":[0-9]*' | cut -d: -f2)
            local health; health=$(echo "$batt_json" | grep -o '"health":"[^"]*"' | cut -d'"' -f4)
            local status; status=$(echo "$batt_json" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            local plugged; plugged=$(echo "$batt_json" | grep -o '"plugged":"[^"]*"' | cut -d'"' -f4)
            local temp; temp=$(echo "$batt_json" | grep -o '"temperature":[0-9.]*' | cut -d: -f2)

            _info "Battery: ${pct}%  ·  Health: ${health}  ·  Status: ${status}  ·  ${plugged}"
            [[ -n "$temp" ]] && _info "Temperature: ${temp}°C"

            if [[ -n "$pct" && "$pct" -lt 10 ]]; then
                _fail "Battery CRITICAL (${pct}%)  — plug in now"
            elif [[ -n "$pct" && "$pct" -lt 20 ]]; then
                _fail "Battery very low (${pct}%)  — charge now or lose session"
            elif [[ -n "$pct" && "$pct" -lt 30 ]]; then
                _warn "Battery low  — ${pct}%"
            elif [[ -n "$pct" && "$pct" -lt 50 ]]; then
                _warn "Battery moderate  — ${pct}%"
            else
                _pass "Battery OK  — ${pct}%"
            fi

            [[ "$health" == "GOOD" || "$health" == "EXCELLENT" ]] && _pass "Battery health: ${health}" || _warn "Battery health: ${health}  — monitor closely"

            if [[ -n "$temp" ]]; then
                local temp_int; temp_int=${temp%.*}
                [[ "$temp_int" -gt 40 ]] && _warn "Battery temperature high: ${temp}°C" || _pass "Battery temperature normal: ${temp}°C"
            fi
        else
            _warn "termux-battery-status returned empty — is Termux:API app installed and permitted?"
        fi
    else
        _warn "termux-api not installed  — pkg install termux-api  then install Termux:API from F-Droid"
    fi
    echo
}

fairy_jorgen() {
    _should_skip "jorgen" && { _skip "FAIRY JORGEN — Permission Enforcer"; return; }
    _head "FAIRY JORGEN  ·  Permission Enforcer"

    local found=0
    while IFS= read -r script; do
        [[ -f "$script" ]] || continue
        found=1
        local name; name=$(basename "$script")
        local sz; sz=$(du -sh "$script" 2>/dev/null | cut -f1)
        if [[ -x "$script" ]]; then
            _pass "$name  (${sz})  — executable ✓"
        else
            _warn "$name  (${sz})  — not executable  · fix: chmod +x ~/$name"
        fi
        local shebang; shebang=$(head -1 "$script" 2>/dev/null)
        if [[ "$shebang" != "#!/"* ]]; then
            _warn "$name  — missing or invalid shebang: '$shebang'"
        fi
    done < <(find "$HOME" -maxdepth 1 -name "*.sh" 2>/dev/null)
    [[ $found -eq 0 ]] && _info "No .sh scripts found in $HOME"

    if [[ -d "$HOME/storage" ]]; then
        _pass "Termux storage  — set up (~/storage exists)"
    else
        _warn "Termux storage not set up  — run: termux-setup-storage"
    fi
    echo
}

fairy_tooth() {
    _should_skip "tooth" && { _skip "FAIRY TOOTH — Cache Cleaner"; return; }
    _head "FAIRY TOOTH  ·  Cache Cleaner"

    local pyc; pyc=$(find "$HOME" -name "*.pyc" 2>/dev/null | wc -l)
    local pycache; pycache=$(find "$HOME" -name "__pycache__" -type d 2>/dev/null | wc -l)
    [[ "$pyc" -gt 0 ]]      && _warn "$pyc .pyc bytecode files found  · find $HOME -name '*.pyc' -delete" \
                             || _pass "No .pyc bytecode files"
    [[ "$pycache" -gt 0 ]]  && _warn "$pycache __pycache__ directories" \
                             || _pass "No __pycache__ directories"

    local tmp; tmp=$(find "$HOME" -name "*.tmp" 2>/dev/null | wc -l)
    local swp; swp=$(find "$HOME" -name "*.swp" -o -name "*.swo" 2>/dev/null | wc -l)
    [[ "$tmp" -gt 0 ]] && _warn "$tmp .tmp files detected" || _pass "No .tmp clutter"
    [[ "$swp" -gt 0 ]] && _warn "$swp vim swap file(s) detected  · vim might have crashed" || _pass "No vim swap files"

    if [[ -d "$HOME/.npm" ]]; then
        local npm_size; npm_size=$(du -sh "$HOME/.npm" 2>/dev/null | cut -f1)
        _info "npm cache: $npm_size at ~/.npm  · clear: npm cache clean --force"
    else
        _pass "No npm cache"
    fi

    if [[ -d "$HOME/.cache/pip" ]]; then
        local pip_size; pip_size=$(du -sh "$HOME/.cache/pip" 2>/dev/null | cut -f1)
        _info "pip cache: $pip_size  · clear: pip cache purge --break-system-packages"
    fi

    if [[ -d "$HOME/.cache" ]]; then
        local cache_size; cache_size=$(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)
        _info "General cache: $cache_size at ~/.cache"
    fi

    local apt_cache; apt_cache=$(du -sh /data/data/com.termux/files/usr/var/cache/apt/archives 2>/dev/null | cut -f1)
    [[ -n "$apt_cache" ]] && _info "apt package cache: $apt_cache  · clear: pkg clean"
    echo
}

fairy_anticosmo() {
    _should_skip "anticosmo" && { _skip "FAIRY ANTI-COSMO — Broken Link Monitor"; return; }
    _head "FAIRY ANTI-COSMO  ·  Broken Link Monitor"

    local broken; broken=$(find "$HOME" -maxdepth 4 -xtype l 2>/dev/null)
    local broken_count; broken_count=$(echo "$broken" | grep -c . 2>/dev/null || echo 0)
    [[ -z "$broken" ]] && broken_count=0
    if [[ "$broken_count" -gt 0 ]]; then
        _fail "$broken_count broken symlink(s) detected"
        echo "$broken" | head -10 | while read -r link; do
            [[ -n "$link" ]] && _info "  ↳ $link"
        done
        [[ "$broken_count" -gt 10 ]] && _info "  ↳ ... and $(( broken_count - 10 )) more"
    else
        _pass "No broken symlinks found"
    fi

    local merging; merging=$(find "$HOME" -maxdepth 4 -name "MERGE_HEAD" 2>/dev/null | wc -l)
    [[ "$merging" -gt 0 ]] && _warn "$merging repo(s) with unresolved merge in progress" || _pass "No pending git merges"

    local rebasing; rebasing=$(find "$HOME" -maxdepth 4 -name "rebase-merge" -type d 2>/dev/null | wc -l)
    [[ "$rebasing" -gt 0 ]] && _warn "$rebasing repo(s) with rebase in progress" || _pass "No rebase-in-progress states"

    local empty_dirs; empty_dirs=$(find "$HOME" -maxdepth 2 -type d -empty 2>/dev/null | wc -l)
    [[ "$empty_dirs" -gt 5 ]] && _info "$empty_dirs empty directories in home (harmless but worth reviewing)" || _pass "Home directory structure clean"
    echo
}

fairy_cupid() {
    _should_skip "cupid" && { _skip "FAIRY CUPID — API Connectivity"; return; }
    _head "FAIRY CUPID  ·  API Connectivity"

    local api_cmds=(
        "termux-notification"
        "termux-battery-status"
        "termux-clipboard-get"
        "termux-clipboard-set"
        "termux-wifi-connectioninfo"
        "termux-toast"
        "termux-location"
        "termux-sms-send"
        "termux-camera-info"
        "termux-media-player"
    )
    for cmd in "${api_cmds[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 \
            && _pass "$cmd  — available" \
            || _warn "$cmd  — missing  · pkg install termux-api"
    done

    if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
        local wifi_test; wifi_test=$(timeout 3 termux-wifi-connectioninfo 2>/dev/null)
        if [[ -n "$wifi_test" && "$wifi_test" != *"error"* ]]; then
            local ssid; ssid=$(echo "$wifi_test" | grep -o '"ssid":"[^"]*"' | cut -d'"' -f4)
            _pass "Termux:API bridge  — active  · WiFi: ${ssid:-connected}"
        else
            _warn "Termux:API bridge  — installed but not responding  · check app permissions"
        fi
    fi
    echo
}

fairy_binky() {
    _should_skip "binky" && { _skip "FAIRY BINKY — Process Monitor"; return; }
    _head "FAIRY BINKY  ·  Process Monitor"

    local ssh_agents; ssh_agents=$(pgrep -c ssh-agent 2>/dev/null || echo 0)
    [[ "$ssh_agents" -gt 1 ]] && _warn "$ssh_agents ssh-agent instances (possible orphans)" || _pass "ssh-agent  — clean (${ssh_agents} instance)"

    local zombies; zombies=$(ps aux 2>/dev/null | awk '$8 == "Z"' | wc -l)
    [[ "$zombies" -gt 0 ]] && _warn "$zombies zombie process(es) detected" || _pass "No zombie processes"

    local top_proc; top_proc=$(ps aux 2>/dev/null | sort -k4 -rn | awk 'NR==2 {print $11" ("$4"%)"}')
    [[ -n "$top_proc" ]] && _info "Top memory process: $top_proc"

    local total_procs; total_procs=$(ps aux 2>/dev/null | wc -l)
    _info "Total active processes: $total_procs"

    pgrep -x mpv >/dev/null 2>&1 && _info "mpv is active (media player running in background)"

    local socat_count; socat_count=$(pgrep -c socat 2>/dev/null || echo 0)
    local nc_count; nc_count=$(pgrep -c nc 2>/dev/null || echo 0)
    [[ "$socat_count" -gt 0 ]] && _warn "$socat_count socat process(es) running — verify intent"
    [[ "$nc_count"    -gt 0 ]] && _warn "$nc_count netcat process(es) running"

    pgrep -x tor >/dev/null 2>&1 && _info "Tor daemon is running"

    pgrep -x crond >/dev/null 2>&1 && _pass "crond  — running" || _info "crond  — not running  · start: crond to enable scheduled jobs"
    echo
}

fairy_juandissimo() {
    _should_skip "juandissimo" && { _skip "FAIRY JUANDISSIMO — Theme Auditor"; return; }
    _head "FAIRY JUANDISSIMO  ·  Theme Auditor"

    local termux_dir="$HOME/.termux"
    local colors_file="$termux_dir/colors.properties"
    local font_file="$termux_dir/font.ttf"
    local props_file="$termux_dir/termux.properties"

    [[ -f "$colors_file" ]] && _pass "colors.properties  — present" || _warn "colors.properties  — missing  · create: $termux_dir/colors.properties"
    [[ -f "$font_file"   ]] && _pass "Custom font        — installed ($(du -sh "$font_file" 2>/dev/null | cut -f1))" || _info "No custom font — system default active"
    [[ -f "$props_file"  ]] && _pass "termux.properties  — present" || _warn "termux.properties  — missing"

    if [[ -f "$props_file" ]]; then
        grep -q "extra-keys" "$props_file" 2>/dev/null && _pass "extra-keys configured" || _info "extra-keys not configured in termux.properties"
        grep -q "allow-external-apps" "$props_file" 2>/dev/null && _pass "allow-external-apps configured" || _info "allow-external-apps not set"
        grep -q "bell-character" "$props_file" 2>/dev/null && _info "bell-character setting found"
    fi

    if grep -q 'PS1=' "$HOME/.bashrc" 2>/dev/null; then
        _pass "Custom PS1 prompt  — configured"
    else
        _info "PS1 prompt — using default"
    fi
    echo
}

fairy_blonda() {
    _should_skip "blonda" && { _skip "FAIRY BLONDA — Media Scanner"; return; }
    _head "FAIRY BLONDA  ·  Media Scanner"

    local dl_dir="$HOME/storage/downloads"
    if [[ ! -d "$dl_dir" ]]; then
        _warn "Downloads folder not accessible  — run: termux-setup-storage"; echo; return
    fi

    local total_size; total_size=$(du -sh "$dl_dir" 2>/dev/null | cut -f1 || echo "?")
    local total_files; total_files=$(find "$dl_dir" -type f 2>/dev/null | wc -l)
    _info "Downloads: $total_files files  ·  $total_size total"

    local large_files; large_files=$(find "$dl_dir" -type f -size +100M 2>/dev/null | wc -l)
    if [[ "$large_files" -gt 0 ]]; then
        _warn "$large_files file(s) over 100MB in downloads"
        find "$dl_dir" -type f -size +100M 2>/dev/null | while read -r f; do
            local sz; sz=$(du -sh "$f" 2>/dev/null | cut -f1)
            _info "  ↳ ${sz}   $(basename "$f")"
        done
    else
        _pass "No oversized files (>100MB) in downloads"
    fi

    local mp3_count; mp3_count=$(find "$dl_dir" -iname "*.mp3" 2>/dev/null | wc -l)
    local mp4_count; mp4_count=$(find "$dl_dir" -iname "*.mp4" 2>/dev/null | wc -l)
    local jpg_count; jpg_count=$(find "$dl_dir" -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" 2>/dev/null | wc -l)
    local pdf_count; pdf_count=$(find "$dl_dir" -iname "*.pdf" 2>/dev/null | wc -l)
    _info "Media breakdown — MP3: $mp3_count  ·  MP4: $mp4_count  ·  Images: $jpg_count  ·  PDFs: $pdf_count"
    echo
}

fairy_trixie() {
    _should_skip "trixie" && { _skip "FAIRY TRIXIE — Session & Uptime Monitor"; return; }
    _head "FAIRY TRIXIE  ·  Session & Uptime Monitor"

    local uptime_str; uptime_str=$(uptime 2>/dev/null | sed 's/.*up /up /' | cut -d',' -f1-2)
    [[ -n "$uptime_str" ]] && _info "System: $uptime_str"

    local load; load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1" "$2" "$3}')
    if [[ -n "$load" ]]; then
        _info "Load avg (1/5/15 min): $load"
        local load1; load1=$(echo "$load" | awk '{print $1}' | cut -d. -f1)
        if [[ "$load1" -gt 6 ]]; then
            _fail "CPU load very high  — close heavy processes"
        elif [[ "$load1" -gt 3 ]]; then
            _warn "CPU load elevated  — monitor running processes"
        else
            _pass "CPU load normal"
        fi
    fi

    if [[ -f /proc/meminfo ]]; then
        local mem_total; mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local mem_avail; mem_avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        if [[ -n "$mem_total" && -n "$mem_avail" ]]; then
            local mem_used=$(( mem_total - mem_avail ))
            local mem_pct=$(( mem_used * 100 / mem_total ))
            local mem_used_mb=$(( mem_used / 1024 ))
            local mem_total_mb=$(( mem_total / 1024 ))
            _info "Memory: ${mem_used_mb}MB / ${mem_total_mb}MB  (${mem_pct}% used)"
            [[ "$mem_pct" -gt 85 ]] && _fail "Memory very high — ${mem_pct}%" \
                || { [[ "$mem_pct" -gt 70 ]] && _warn "Memory elevated — ${mem_pct}%" \
                || _pass "Memory usage healthy — ${mem_pct}%"; }
        fi
    fi

    command -v termux-wake-lock >/dev/null 2>&1 && _info "termux-wake-lock  — available"
    _info "Shell: ${SHELL}  ·  PID: $$  ·  TERM: ${TERM:-unknown}"
    echo
}

fairy_chester() {
    _should_skip "chester" && { _skip "FAIRY CHESTER — Package Update Scanner"; return; }
    _head "FAIRY CHESTER  ·  Package Update Scanner"

    _info "Checking for upgradable apt packages..."
    local updates; updates=$(apt list --upgradable 2>/dev/null | grep -v "^Listing" | grep -c "/" || echo 0)
    if [[ "${updates:-0}" -eq 0 ]]; then
        _pass "All packages up to date"
    elif [[ "${updates:-0}" -lt 5 ]]; then
        _warn "$updates package(s) need updating  · run: pkg upgrade"
    elif [[ "${updates:-0}" -lt 20 ]]; then
        _warn "$updates packages behind  · run: pkg upgrade -y"
    else
        _fail "$updates packages behind  · run: pkg update && pkg upgrade -y"
    fi

    if command -v pip >/dev/null 2>&1; then
        _info "Checking outdated pip packages..."
        local pip_out; pip_out=$(pip list --outdated --break-system-packages 2>/dev/null | grep -v "^Package\|^-" | wc -l)
        if [[ "$pip_out" -gt 0 ]]; then
            _warn "$pip_out pip package(s) outdated  · pip list --outdated --break-system-packages"
        else
            _pass "pip packages all current"
        fi
    fi

    if command -v npm >/dev/null 2>&1; then
        local npm_out; npm_out=$(npm outdated -g 2>/dev/null | grep -c "." || echo 0)
        [[ "$npm_out" -gt 0 ]] && _warn "$npm_out global npm package(s) outdated  · npm update -g" || _pass "Global npm packages current"
    fi

    if command -v yt-dlp >/dev/null 2>&1; then
        local yt_ver; yt_ver=$(yt-dlp --version 2>/dev/null)
        _info "yt-dlp version: ${yt_ver:-unknown}  · update: yt-dlp -U"
    fi
    echo
}

fairy_veronica() {
    _should_skip "veronica" && { _skip "FAIRY VERONICA — Backup Integrity Checker"; return; }
    _head "FAIRY VERONICA  ·  Backup Integrity Checker"

    local dl="$HOME/storage/downloads"
    local found_any=0
    local all_good=1

    local backups; backups=$(find "$dl" -maxdepth 2 -name "*_BK.sh" -o -name "*_BK" -o -name "*.bak" 2>/dev/null)
    if [[ -z "$backups" ]]; then
        _warn "No backup files found in downloads  · run a backup now"
        all_good=0
    else
        while IFS= read -r bk; do
            [[ -z "$bk" ]] && continue
            found_any=1
            local name; name=$(basename "$bk")
            local sz; sz=$(du -sh "$bk" 2>/dev/null | cut -f1)
            local age_days; age_days=$(( ($(date +%s) - $(stat -c %Y "$bk" 2>/dev/null || echo 0)) / 86400 ))
            if [[ "$age_days" -gt 7 ]]; then
                _warn "$name  — ${sz}  ·  ${age_days}d old  — consider refreshing"
                all_good=0
            else
                _pass "$name  — ${sz}  ·  ${age_days}d old  — fresh"
            fi
        done <<< "$backups"
    fi

    if [[ -n "$VICKY_BACKUP_SUFFIX" ]]; then
        read -ra _bk_list <<< "$VICKY_BACKUP_SUFFIX"
        for _suffix in "${_bk_list[@]}"; do
            local _match; _match=$(find "$dl" -maxdepth 2 -name "*${_suffix}" 2>/dev/null | head -1)
            [[ -z "$_match" ]] && { _warn "No backup matching *${_suffix} found"; all_good=0; }
        done
    fi

    local bashrc_bk; bashrc_bk=$(find "$dl" -name "*bashrc*" 2>/dev/null | head -1)
    [[ -n "$bashrc_bk" ]] && _pass ".bashrc backup found  — $(basename "$bashrc_bk")" || _warn "No .bashrc backup in downloads"

    local pre_fixes; pre_fixes=$(find "$dl" -name "*PRE_*.sh" 2>/dev/null | wc -l)
    [[ "$pre_fixes" -gt 0 ]] && _info "$pre_fixes pre-fix backup(s) found — remove if stable"
    [[ "$all_good" -eq 1 && "$found_any" -eq 1 ]] && _pass "All detected backups verified — Veronica approves"
    echo
}

fairy_aj() {
    _should_skip "aj" && { _skip "FAIRY A.J. — Script Auditor"; return; }
    _head "FAIRY A.J.  ·  Script Auditor"

    local all_ok=1

    if [[ -n "$VICKY_STATION_PATTERN" ]]; then
        local station_script
        station_script=$(find "$HOME" -maxdepth 1 -name "$VICKY_STATION_PATTERN" 2>/dev/null \
            | sort -V | tail -1)
        if [[ -n "$station_script" ]]; then
            local name; name=$(basename "$station_script")
            local sz; sz=$(du -sh "$station_script" 2>/dev/null | cut -f1)
            local lines; lines=$(wc -l < "$station_script" 2>/dev/null)
            if bash -n "$station_script" 2>/dev/null; then
                if [[ -x "$station_script" ]]; then
                    _pass "Station ($name)  — ${sz}  ·  ${lines} lines  ·  syntax OK  ·  executable ✓"
                else
                    _warn "Station ($name)  — not executable  · chmod +x $name"
                    all_ok=0
                fi
            else
                local err; err=$(bash -n "$station_script" 2>&1 | head -1)
                _fail "Station ($name)  — SYNTAX ERROR: $err"
                all_ok=0
            fi
        else
            _info "No station script found matching: $VICKY_STATION_PATTERN"
        fi
    else
        _info "VICKY_STATION_PATTERN not set — skipping station check"
    fi

    local vicky_path="$HOME/vicky.sh"
    if [[ -f "$vicky_path" ]]; then
        local vsz; vsz=$(du -sh "$vicky_path" 2>/dev/null | cut -f1)
        if bash -n "$vicky_path" 2>/dev/null; then
            _pass "vicky.sh  — ${vsz}  ·  syntax OK"
        else
            _fail "vicky.sh  — SYNTAX ERROR"
            all_ok=0
        fi
    else
        _warn "vicky.sh  — not found at $vicky_path"
        all_ok=0
    fi

    while IFS= read -r script; do
        [[ -z "$script" ]] && continue
        local sname; sname=$(basename "$script")
        [[ "$sname" == "vicky.sh" ]] && continue
        local ssz; ssz=$(du -sh "$script" 2>/dev/null | cut -f1)
        local slines; slines=$(wc -l < "$script" 2>/dev/null)
        if bash -n "$script" 2>/dev/null; then
            [[ -x "$script" ]] && _pass "$sname  — ${ssz}  ·  ${slines}L  ·  syntax OK  ·  executable ✓" \
                                || _warn "$sname  — not executable  · chmod +x $sname"
        else
            local serr; serr=$(bash -n "$script" 2>&1 | head -1)
            _fail "$sname  — SYNTAX ERROR: $serr"
            all_ok=0
        fi
    done < <(find "$HOME" -maxdepth 1 -name "*.sh" 2>/dev/null)

    if [[ -n "$VICKY_EXTRA_SCRIPTS" ]]; then
        read -ra _extra <<< "$VICKY_EXTRA_SCRIPTS"
        for script in "${_extra[@]}"; do
            local path="$HOME/$script"
            if [[ -f "$path" && -s "$path" ]]; then
                local sz2; sz2=$(du -sh "$path" 2>/dev/null | cut -f1)
                bash -n "$path" 2>/dev/null \
                    && _pass "$script  — ${sz2}  ·  syntax OK" \
                    || { _fail "$script  — SYNTAX ERROR"; all_ok=0; }
            elif [[ -f "$path" ]]; then
                _fail "$script  — FILE IS EMPTY"
                all_ok=0
            else
                _fail "$script  — NOT FOUND at $path"
                all_ok=0
            fi
        done
    fi

    if grep -qE "^source.*\.sh$|^\. .*\.sh$" "$HOME/.bashrc" 2>/dev/null; then
        local sourced_scripts; sourced_scripts=$(grep -E "^source.*\.sh$|^\. .*\.sh$" "$HOME/.bashrc" 2>/dev/null)
        _info ".bashrc sources these scripts on reload:"
        while IFS= read -r line; do
            _info "  → $line"
        done <<< "$sourced_scripts"
    fi

    [[ "$all_ok" -eq 1 ]] && _pass "All scripts pass — A.J. signs off clean"
    echo
}

# ══════════════════════════════════════════════════════════════════
#  FAIRIES 18–23
# ══════════════════════════════════════════════════════════════════

fairy_wisteria() {
    _should_skip "wisteria" && { _skip "FAIRY WISTERIA — Python Environment Auditor"; return; }
    _head "FAIRY WISTERIA  ·  Python Environment Auditor"

    if ! command -v python3 >/dev/null 2>&1; then
        _fail "Python3 not installed  · pkg install python"; echo; return
    fi

    _info "Python: $(python3 --version 2>&1)"
    _info "Location: $(command -v python3)"

    if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
        local pip_ver; pip_ver=$(pip3 --version 2>/dev/null || pip --version 2>/dev/null)
        _info "pip: $pip_ver"
    else
        _warn "pip not found  · python3 -m ensurepip --break-system-packages"
    fi

    local py_packages=(requests beautifulsoup4 pillow numpy flask)
    for pkg in "${py_packages[@]}"; do
        python3 -c "import ${pkg//-/_}" 2>/dev/null \
            && _pass "python: $pkg  — installed" \
            || _info "python: $pkg  — not installed (optional)"
    done

    local venvs; venvs=$(find "$HOME" -maxdepth 3 -name "pyvenv.cfg" 2>/dev/null | wc -l)
    [[ "$venvs" -gt 0 ]] && _info "$venvs virtual environment(s) found in home" || _info "No virtual environments detected"

    local py_path; py_path=$(python3 -c "import sys; print(':'.join(sys.path))" 2>/dev/null | tr ':' '\n' | grep -v '^$' | head -3)
    _info "Python path (first 3): $(echo "$py_path" | tr '\n' '  ')"
    echo
}

fairy_poofjr() {
    _should_skip "poofjr" && { _skip "FAIRY POOF JR — SSH Key Inspector"; return; }
    _head "FAIRY POOF JR  ·  SSH Key Inspector"

    local ssh_dir="$HOME/.ssh"
    if [[ ! -d "$ssh_dir" ]]; then
        _info "No ~/.ssh directory found  · ssh-keygen -t ed25519 to create"
        echo; return
    fi

    _pass "~/.ssh  — exists"

    local key_count=0
    for keyfile in "$ssh_dir"/id_*; do
        [[ -f "$keyfile" ]] || continue
        [[ "$keyfile" == *.pub ]] && continue
        (( key_count++ ))
        local kname; kname=$(basename "$keyfile")
        local kperm; kperm=$(stat -c '%a' "$keyfile" 2>/dev/null)
        local ktype; ktype=$(ssh-keygen -l -f "$keyfile" 2>/dev/null | awk '{print $4}')
        local kbits; kbits=$(ssh-keygen -l -f "$keyfile" 2>/dev/null | awk '{print $1}')

        if [[ "$kperm" == "600" ]]; then
            _pass "$kname  — ${ktype:-unknown}  ·  ${kbits:-?} bits  ·  permissions OK"
        else
            _warn "$kname  — permissions ${kperm} (should be 600)  · chmod 600 $keyfile"
        fi

        [[ -f "${keyfile}.pub" ]] && _pass "${kname}.pub  — public key present" || _warn "${kname}.pub  — missing public key"
    done

    [[ "$key_count" -eq 0 ]] && _info "No SSH keys found  · generate: ssh-keygen -t ed25519 -C 'label'"

    if [[ -f "$ssh_dir/known_hosts" ]]; then
        local kh_count; kh_count=$(wc -l < "$ssh_dir/known_hosts" 2>/dev/null)
        _info "known_hosts: $kh_count entries"
    else
        _info "No known_hosts file yet"
    fi

    [[ -f "$ssh_dir/config" ]] && _pass "SSH config file  — present" || _info "No SSH config file  · optional but useful for aliases"

    if [[ -n "$SSH_AUTH_SOCK" ]]; then
        local loaded; loaded=$(ssh-add -l 2>/dev/null | wc -l)
        _pass "ssh-agent running  · $loaded key(s) loaded"
    else
        _info "ssh-agent not running  · eval \$(ssh-agent) && ssh-add"
    fi
    echo
}

fairy_schnookie() {
    _should_skip "schnookie" && { _skip "FAIRY SCHNOOKIE — Cron Job Auditor"; return; }
    _head "FAIRY SCHNOOKIE  ·  Cron Job Auditor"

    if pgrep -x crond >/dev/null 2>&1; then
        _pass "crond  — running"
    else
        _info "crond  — not running  · start: crond  · or: sv start crond (if using runit)"
    fi

    local cron_entries; cron_entries=$(crontab -l 2>/dev/null)
    if [[ -z "$cron_entries" ]]; then
        _info "No cron jobs scheduled  · set up: crontab -e"
    else
        local cron_count; cron_count=$(echo "$cron_entries" | grep -v '^#' | grep -v '^$' | wc -l)
        _pass "$cron_count cron job(s) configured"
        echo "$cron_entries" | grep -v '^#' | grep -v '^$' | while IFS= read -r line; do
            _info "  → $line"
        done
    fi

    if command -v atq >/dev/null 2>&1; then
        local at_jobs; at_jobs=$(atq 2>/dev/null | wc -l)
        [[ "$at_jobs" -gt 0 ]] && _info "$at_jobs at job(s) queued" || _info "No at jobs queued"
    else
        _info "at not installed  · pkg install at  for one-shot scheduled tasks"
    fi
    echo
}

fairy_neptunia() {
    _should_skip "neptunia" && { _skip "FAIRY NEPTUNIA — Log File Monitor"; return; }
    _head "FAIRY NEPTUNIA  ·  Log File Monitor"

    local tmp_dir="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
    if [[ -d "$tmp_dir" ]]; then
        local tmp_size; tmp_size=$(du -sh "$tmp_dir" 2>/dev/null | cut -f1)
        local tmp_count; tmp_count=$(find "$tmp_dir" -type f 2>/dev/null | wc -l)
        _info "TMPDIR: $tmp_size  ·  $tmp_count files  ·  $tmp_dir"
        [[ "$tmp_count" -gt 200 ]] && _warn "Many temp files accumulating  · clear: rm -rf ${tmp_dir:?}/*" || _pass "Temp directory clean"
    fi

    if [[ -f "$REPORT_FILE" ]]; then
        local log_age; log_age=$(( ($(date +%s) - $(stat -c %Y "$REPORT_FILE" 2>/dev/null || echo 0)) / 3600 ))
        _info "Last Vicky report: ${log_age}h ago"
    fi

    local log_files; log_files=$(find "$HOME" -name "*.log" -type f 2>/dev/null | wc -l)
    [[ "$log_files" -gt 0 ]] && _info "$log_files .log file(s) in home" || _pass "No stray log files"
    echo
}

fairy_remy() {
    _should_skip "remy" && { _skip "FAIRY REMY — Environment Variable Checker"; return; }
    _head "FAIRY REMY  ·  Environment Variable Checker"

    local critical_vars=(HOME PATH TMPDIR PREFIX)
    for var in "${critical_vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            _pass "$var  — set: ${!var:0:60}"
        else
            _fail "$var  — NOT SET  — this will cause errors"
        fi
    done

    if [[ "$PATH" == *"/data/data/com.termux/files/usr/bin"* ]]; then
        _pass "Termux bin in PATH"
    else
        _warn "Termux bin not in PATH  · add to .bashrc: export PATH=\$PREFIX/bin:\$PATH"
    fi

    echo ""
    _info "Optional environment variables:"
    local opt_vars=(EDITOR VISUAL PAGER LANG LC_ALL TERM)
    for var in "${opt_vars[@]}"; do
        [[ -n "${!var}" ]] && _pass "$var  — ${!var}" || _info "$var  — not set (optional)"
    done

    echo ""
    _info "Shell: ${SHELL}  ·  BASH_VERSION: ${BASH_VERSION%%(*}"
    [[ "$-" == *"i"* ]] && _pass "Interactive shell  — confirmed" || _info "Non-interactive shell (running from script)"
    echo
}

fairy_turbo() {
    _should_skip "turbo" && { _skip "FAIRY TURBO — Memory & Swap Monitor"; return; }
    _head "FAIRY TURBO  ·  Memory & Swap Monitor"

    if [[ -f /proc/meminfo ]]; then
        local mem_total; mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
        local mem_free;  mem_free=$(awk '/MemFree/{print $2}' /proc/meminfo)
        local mem_avail; mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
        local swap_total; swap_total=$(awk '/SwapTotal/{print $2}' /proc/meminfo)
        local swap_free;  swap_free=$(awk '/SwapFree/{print $2}' /proc/meminfo)

        local mem_used=$(( mem_total - mem_avail ))
        local mem_pct=$(( mem_used * 100 / mem_total ))
        local mem_used_mb=$(( mem_used / 1024 ))
        local mem_total_mb=$(( mem_total / 1024 ))
        local mem_avail_mb=$(( mem_avail / 1024 ))

        _info "RAM total    : ${mem_total_mb} MB"
        _info "RAM used     : ${mem_used_mb} MB  (${mem_pct}%)"
        _info "RAM available: ${mem_avail_mb} MB"

        if [[ "$mem_pct" -gt 90 ]]; then
            _fail "Memory critically high — ${mem_pct}%  — close apps now"
        elif [[ "$mem_pct" -gt 75 ]]; then
            _warn "Memory high — ${mem_pct}%  — close unused processes"
        else
            _pass "Memory usage healthy — ${mem_pct}%"
        fi

        if [[ -n "$swap_total" && "$swap_total" -gt 0 ]]; then
            local swap_used=$(( swap_total - swap_free ))
            local swap_pct=$(( swap_used * 100 / swap_total ))
            local swap_used_mb=$(( swap_used / 1024 ))
            local swap_total_mb=$(( swap_total / 1024 ))
            _info "Swap: ${swap_used_mb}MB / ${swap_total_mb}MB  (${swap_pct}%)"
            [[ "$swap_pct" -gt 70 ]] && _warn "Heavy swap usage — ${swap_pct}%  — device under memory pressure" || _pass "Swap usage normal"
        else
            _info "No swap configured (normal on Android)"
        fi

        echo ""
        _info "Top 5 memory-consuming processes:"
        ps aux 2>/dev/null | sort -k4 -rn | awk 'NR>1 && NR<=6 {printf "    %-20s  %s%%\n", $11, $4}' | while IFS= read -r line; do
            _info "$line"
        done
    else
        _warn "/proc/meminfo not readable"
    fi
    echo
}

# ══════════════════════════════════════════════════════════════════
#  REPORT, SUMMARY & EXPORT
# ══════════════════════════════════════════════════════════════════

vicky_report() {
    echo
    echo -e "${PURP}${BOLD}  ════════════════════════════════════════════════════${RESET}"
    echo -e "${HOT}${BOLD}         V I C K Y ' S   V E R D I C T${RESET}"
    echo -e "${PURP}${BOLD}  ════════════════════════════════════════════════════${RESET}"
    echo
    echo -e "  ${GRN}${BOLD}  PASSED  :  $PASS${RESET}"
    echo -e "  ${YEL}${BOLD}  WARNED  :  $WARN${RESET}"
    echo -e "  ${RED}${BOLD}  FAILED  :  $FAIL${RESET}"
    echo
    echo -e "${PURP}${BOLD}  ────────────────────────────────────────────────────${RESET}"
    echo

    local verdict_text=""
    if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
        echo -e "  ${GRN}${BOLD}  ✓  ALL CLEAR — 23 Fairies report clean. ${VICKY_K9} stands down.${RESET}"
        verdict_text="ALL CLEAR"
    elif [[ $FAIL -eq 0 ]]; then
        echo -e "  ${YEL}${BOLD}  ⚠  WARNINGS PRESENT — ${VICKY_K9} is watching. Address these.${RESET}"
        verdict_text="WARNINGS PRESENT"
    else
        echo -e "  ${RED}${BOLD}  ✗  ISSUES DETECTED — Vicky is not impressed. Fix it.${RESET}"
        verdict_text="ISSUES DETECTED"
    fi

    echo
    echo -e "${PURP}${BOLD}  ════════════════════════════════════════════════════${RESET}"
    echo -e "  ${DIM}${WHT}Report saved → $REPORT_FILE${RESET}"
    [[ -n "$VICKY_BRAND" ]] && echo -e "  ${DIM}${WHT}${VICKY_BRAND}${RESET}"
    echo -e "  ${DIM}${WHT}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo -e "${PURP}${BOLD}  ════════════════════════════════════════════════════${RESET}"
    echo

    {
        echo "=== VICKY REPORT — $(date) ==="
        echo "PASS: $PASS | WARN: $WARN | FAIL: $FAIL"
        echo "VERDICT: $verdict_text"
        echo "K9: ${VICKY_K9}"
    } > "$REPORT_FILE"

    cp "$REPORT_FILE" "$HISTORY_DIR/report_$(date +%Y%m%d_%H%M%S).log" 2>/dev/null

    if command -v termux-notification >/dev/null 2>&1; then
        local issues=$(( FAIL + WARN ))
        if [[ $issues -gt 0 ]]; then
            termux-notification -t "VICKY — System Integrity" -c "$FAIL failure(s), $WARN warning(s) found. Run: vicky" --priority high 2>/dev/null
        else
            termux-notification -t "VICKY — All Clear" -c "23 fairies report clean. ${VICKY_K9} stands down." --priority default 2>/dev/null
        fi
    fi

    echo -e "  ${CYN}Press ENTER to exit${RESET}"
    read -r
}

vicky_summary() {
    if [[ -f "$REPORT_FILE" ]]; then
        local verdict; verdict=$(grep "VERDICT:" "$REPORT_FILE" | cut -d: -f2-)
        local pass; pass=$(grep "PASS:" "$REPORT_FILE" | grep -oP 'PASS: \K[0-9]+')
        local warn; warn=$(grep "PASS:" "$REPORT_FILE" | grep -oP 'WARN: \K[0-9]+')
        local fail; fail=$(grep "PASS:" "$REPORT_FILE" | grep -oP 'FAIL: \K[0-9]+')
        local age; age=$(( ($(date +%s) - $(stat -c %Y "$REPORT_FILE" 2>/dev/null || echo 0)) / 3600 ))
        echo -e "${HOT}${BOLD}[VICKY]${RESET}${verdict}  ·  P:${GRN}${pass}${RESET} W:${YEL}${warn}${RESET} F:${RED}${fail}${RESET}  ·  ${age}h ago  ·  run ${CYN}vicky${RESET} to refresh"
    else
        echo -e "${HOT}${BOLD}[VICKY]${RESET} No scan on record  ·  Run ${CYN}vicky${RESET} now"
    fi
}

vicky_export() {
    local out="$HOME/storage/downloads/vicky_report_$(date +%Y%m%d_%H%M%S).txt"
    if [[ -f "$REPORT_FILE" ]]; then
        cp "$REPORT_FILE" "$out" 2>/dev/null \
            && echo -e "  ${GRN}Exported: $out${RESET}" \
            || echo -e "  ${RED}Export failed — storage not set up?${RESET}"
    else
        echo -e "  ${YEL}No report to export — run vicky first${RESET}"
    fi
}

vicky_watch() {
    local interval="${VICKY_WATCH_INTERVAL:-300}"
    echo -e "${HOT}${BOLD}[VICKY WATCH]${RESET} Monitoring every ${interval}s — Ctrl+C to stop"
    while true; do
        PASS=0; WARN=0; FAIL=0
        fairy_wanda; fairy_trixie; fairy_turbo; fairy_sparky; fairy_binky
        vicky_summary
        echo -e "  ${DIM}Next scan in ${interval}s — $(date '+%H:%M:%S')${RESET}"
        sleep "$interval"
    done
}

vicky_history() {
    echo ""
    echo -e "${PURP}${BOLD}  VICKY REPORT HISTORY${RESET}"
    echo -e "${PURP}  ──────────────────────────────────────${RESET}"
    local count=0
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        (( count++ ))
        local fname; fname=$(basename "$f")
        local verdict; verdict=$(grep "VERDICT:" "$f" 2>/dev/null | cut -d: -f2- | xargs)
        local pass; pass=$(grep "PASS:" "$f" 2>/dev/null | grep -oP 'PASS: \K[0-9]+')
        local warn; warn=$(grep "PASS:" "$f" 2>/dev/null | grep -oP 'WARN: \K[0-9]+')
        local fail; fail=$(grep "PASS:" "$f" 2>/dev/null | grep -oP 'FAIL: \K[0-9]+')
        echo -e "  ${CYN}${fname}${RESET}  P:${GRN}${pass:-?}${RESET} W:${YEL}${warn:-?}${RESET} F:${RED}${fail:-?}${RESET}  ${DIM}${verdict}${RESET}"
    done < <(ls -1t "$HISTORY_DIR"/*.log 2>/dev/null | head -10)
    [[ "$count" -eq 0 ]] && echo -e "  ${DIM}No history yet — run vicky to generate reports${RESET}"
    echo
}

vicky_core() {
    vicky_boot
    echo -e "${PURP}${BOLD}  SCANNING INITIATED — 23 FAIRIES DEPLOYED${RESET}"
    echo -e "${DIM}${WHT}  ${VICKY_K9} is standing by. ${VICKY_BRAND}.${RESET}\n"
    sleep 0.3
    fairy_timmy; fairy_cosmo; fairy_wanda; fairy_poof; fairy_crocker
    fairy_sparky; fairy_jorgen; fairy_tooth; fairy_anticosmo; fairy_cupid
    fairy_binky; fairy_juandissimo; fairy_blonda
    fairy_trixie; fairy_chester; fairy_veronica; fairy_aj
    fairy_wisteria; fairy_poofjr; fairy_schnookie; fairy_neptunia
    fairy_remy; fairy_turbo
    vicky_report
}

# ── DISPATCH ───────────────────────────────────────────────────
case "${1:-}" in
    summary)     vicky_summary ;;
    watch)       vicky_watch ;;
    export)      vicky_export ;;
    history)     vicky_history ;;
    queue)       PASS=0; WARN=0; FAIL=0; vicky_queue ;;
    timmy)       fairy_timmy ;;
    cosmo)       fairy_cosmo ;;
    wanda)       fairy_wanda ;;
    poof)        fairy_poof ;;
    crocker)     fairy_crocker ;;
    sparky)      fairy_sparky ;;
    jorgen)      fairy_jorgen ;;
    tooth)       fairy_tooth ;;
    anticosmo)   fairy_anticosmo ;;
    cupid)       fairy_cupid ;;
    binky)       fairy_binky ;;
    juandissimo) fairy_juandissimo ;;
    blonda)      fairy_blonda ;;
    trixie)      fairy_trixie ;;
    chester)     fairy_chester ;;
    veronica)    fairy_veronica ;;
    aj)          fairy_aj ;;
    wisteria)    fairy_wisteria ;;
    poofjr)      fairy_poofjr ;;
    schnookie)   fairy_schnookie ;;
    neptunia)    fairy_neptunia ;;
    remy)        fairy_remy ;;
    turbo)       fairy_turbo ;;
    help|--help)
        echo ""
        echo -e "${HOT}${BOLD}  VICKY  ·  USAGE${RESET}"
        echo -e "${PURP}  ──────────────────────────────────────────────────${RESET}"
        echo -e "  ${CYN}vicky${RESET}               Full 23-fairy system scan"
        echo -e "  ${CYN}vicky summary${RESET}       One-line status from last report"
        echo -e "  ${CYN}vicky queue${RESET}         Queue builder — pick your fairies"
        echo -e "  ${CYN}vicky watch${RESET}         Continuous monitoring loop"
        echo -e "  ${CYN}vicky export${RESET}        Save report to downloads"
        echo -e "  ${CYN}vicky history${RESET}       View past reports"
        echo -e "  ${CYN}vicky <fairy>${RESET}       Run one fairy (e.g. vicky wanda)"
        echo ""
        echo -e "  ${DIM}Fairies: timmy cosmo wanda poof crocker sparky jorgen tooth${RESET}"
        echo -e "  ${DIM}         anticosmo cupid binky juandissimo blonda trixie chester${RESET}"
        echo -e "  ${DIM}         veronica aj wisteria poofjr schnookie neptunia remy turbo${RESET}"
        echo ""
        echo -e "  ${DIM}Queue shortcuts: 'all' · 'quick' · numbers 1-23 · fairy names${RESET}"
        echo ""
        ;;
    *)           vicky_core ;;
esac
