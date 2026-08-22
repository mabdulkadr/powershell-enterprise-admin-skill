# macOS Enterprise Script Patterns

Bash script patterns for macOS enterprise management with Microsoft Intune. These are **Type 3 (General CLI)** scripts.

**Two output modes — never mix them:**
- **Standard scripts:** `log_message` (structured `[timestamp] [LEVEL] message` to console + `/var/log/`) and `exit 1` on failure.
- **Intune custom attributes (only when explicitly requested):** `output_result` prints ONE line and always exits 0. A success exit on failure in a standard script makes Intune/operators believe it succeeded — only custom attributes exit 0 with an error message.

---

## Table of Contents

1. [Script Header Format](#script-header-format)
2. [Script Structure](#script-structure)
3. [Variables and Initialization](#variables-and-initialization)
4. [Functions](#functions)
5. [Main Script Logic](#main-script-logic)
6. [Error Handling](#error-handling)
7. [Common Patterns](#common-patterns)
8. [Intune Custom Attributes](#intune-custom-attributes)

---

## Script Header Format

Every macOS script uses this structured header:

```bash
#!/bin/bash

# TITLE: [Script Title - Brief descriptive name]
# SYNOPSIS: [One-line description of what the script does]
# DESCRIPTION: [Detailed description of the script's functionality, purpose, and use cases]
# TAGS: [Category],[Subcategory] (e.g., Monitoring,Device or Security,Compliance)
# PLATFORM: macOS
# MIN_OS_VERSION: [Minimum macOS version required - e.g., 10.15]
# AUTHOR: AI Generated
# VERSION: [Version number - start with 1.0]
# LASTUPDATE: [Date of last update]
# CHANGELOG:
#   [Version] - [Description of changes]
#   1.0 - Initial release
#
# EXAMPLE:
#   [Script filename]
#   [Description of what this example does]
#
# NOTES:
#   [Additional notes, requirements, or important information]
#   - [Any special requirements or dependencies]
#   - [Performance considerations]
#   - [Known limitations]
```

### Header Fields Reference

| Field | Required | Purpose |
|-------|----------|---------|
| `TITLE` | Yes | Brief, descriptive name |
| `SYNOPSIS` | Yes | One-line summary |
| `DESCRIPTION` | Yes | Detailed explanation including "why" |
| `TAGS` | Yes | `Category,Subcategory` for discoverability |
| `PLATFORM` | Yes | `macOS` |
| `MIN_OS_VERSION` | Yes | Minimum macOS version required |
| `AUTHOR` | Yes | Author name |
| `VERSION` | Yes | Semantic version (start with 1.0) |
| `LASTUPDATE` | Yes | Date of last update |
| `CHANGELOG` | Yes | Version history with dates |
| `EXAMPLE` | Yes | At least 1 realistic example |
| `NOTES` | Yes | Requirements, limitations, links |

---

## Script Structure

```bash
#!/bin/bash

# ============================================================================
# HEADER (see above)
# ============================================================================

# ============================================================================
# VARIABLES AND INITIALIZATION
# ============================================================================

SCRIPT_VERSION="1.0"
loggedInUser=$(stat -f "%Su" /dev/console 2>/dev/null)

# Common paths (initialize only if user is valid)
if [ -n "$loggedInUser" ] && [ "$loggedInUser" != "root" ] && [ "$loggedInUser" != "_windowserver" ]; then
    USER_HOME=$(dscl . -read /Users/"$loggedInUser" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    LIBRARY_PATH="$USER_HOME/Library"
fi

# ============================================================================
# FUNCTIONS
# ============================================================================

# Function to output result (Intune custom attributes ONLY — prints ONE line, exits 0)
output_result() {
    echo "$1"
    exit 0
}

# Function to log a line in the structured format [timestamp] [LEVEL] message
# (canonical definition in the "Logging Function" section below)
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check minimum OS version
check_os_version() {
    local required_version=$1
    local current_version=$(sw_vers -productVersion)
    
    if [[ $(echo -e "$current_version\n$required_version" | sort -V | head -n1) != "$required_version" ]]; then
        log_message "ERROR" "Unsupported OS: $current_version (requires $required_version+)"
        exit 1
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR" "Error: Root access required"
        exit 1
    fi
}

# ============================================================================
# MAIN SCRIPT LOGIC
# ============================================================================

main() {
    # Add your main script logic here
    :
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

# trap 'log_message "Error: Script failed: line $LINENO" "ERROR"; exit 1' ERR

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

exit 0
```

---

## Variables and Initialization

### Get Logged-In User

```bash
# Get the current console user
# Returns "root" or "_windowserver" when no user is logged in
loggedInUser=$(stat -f "%Su" /dev/console 2>/dev/null)

# Check if user is valid
if [ -n "$loggedInUser" ] && [ "$loggedInUser" != "root" ] && [ "$loggedInUser" != "_windowserver" ]; then
    USER_HOME=$(dscl . -read /Users/"$loggedInUser" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    LIBRARY_PATH="$USER_HOME/Library"
    echo "Logged-in user: $loggedInUser"
    echo "Home directory: $USER_HOME"
else
    echo "No user logged in or running as system"
fi
```

### Common Paths

```bash
# System paths
SYSTEM_LOG="/var/log/system.log"
PLIST_DIR="/Library/Preferences"
LAUNCH_AGENTS="/Library/LaunchAgents"
LAUNCH_DAEMONS="/Library/LaunchDaemons"

# User paths
USER_PLIST="$USER_HOME/Library/Preferences"
USER_LAUNCH_AGENTS="$USER_HOME/Library/LaunchAgents"
USER_APPLICATION_SUPPORT="$USER_HOME/Library/Application Support"
```

### Get System Information

```bash
# macOS version
OS_VERSION=$(sw_vers -productVersion)
OS_BUILD=$(sw_vers -buildVersion)

# Hardware info
MODEL=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}')
SERIAL=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk -F': ' '{print $2}')
CHIP=$(system_profiler SPHardwareDataType | grep "Chip" | awk -F': ' '{print $2}')

# Disk info
DISK_FREE=$(df -g / | tail -1 | awk '{print $4}')
```

---

## Functions

### Logging Function

```bash
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/intune-script-$(date +%Y%m%d).log"

log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Usage
log_message "INFO" "Starting script execution"
log_message "WARN" "Disk space low"
log_message "ERROR" "Failed to update configuration"
```

### Output Result Function (Intune Custom Attributes)

```bash
# For Intune custom attributes, output should be a single line
output_result() {
    echo "$1"
    exit 0
}

# Usage
output_result "Status: OK"
output_result "Version: 1.2.3"
output_result "Error: Configuration failed"
```

### OS Version Check

```bash
check_os_version() {
    local required_version=$1
    local current_version=$(sw_vers -productVersion)
    
    if [[ $(echo -e "$current_version\n$required_version" | sort -V | head -n1) != "$required_version" ]]; then
        log_message "ERROR" "macOS $required_version or higher is required. Current version: $current_version"
        exit 1
    fi
}

# Usage
check_os_version "10.15"  # Requires macOS Catalina or later
check_os_version "12.0"   # Requires macOS Monterey or later
```

### Root Check

```bash
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR" "This script must be run as root"
        exit 1
    fi
}

# Usage at start of main()
check_root
```

### Prerequisite Validation

```bash
validate_prerequisites() {
    # Check if required tools exist
    if ! command -v /usr/libexec/PlistBuddy &> /dev/null; then
        log_message "ERROR" "PlistBuddy not found"
        return 1
    fi
    
    # Check if required directories exist
    if [[ ! -d "/Library/Preferences" ]]; then
        log_message "ERROR" "Preferences directory not found"
        return 1
    fi
    
    return 0
}
```

---

## Main Script Logic

### Structure

```bash
main() {
    log_message "INFO" "Starting script execution (v$SCRIPT_VERSION)"
    
    # Step 1: Validate prerequisites
    if ! validate_prerequisites; then
        log_message "ERROR" "Prerequisites validation failed"
        exit 1
    fi
    
    # Step 2: Execute main logic
    log_message "INFO" "Executing main logic..."
    
    # Your code here
    
    # Step 3: Report result
    log_message "INFO" "Script completed successfully"
    output_result "Status: OK"
}
```

### Execution Guard

```bash
# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

**Why this pattern?** It allows the script to be sourced for testing individual functions without executing the main logic.

---

## Error Handling

### Trap Errors

```bash
# Log errors with line number — use this trap in STANDARD scripts
trap 'log_message "ERROR" "Script failed at line $LINENO with exit code $?"; exit 1' ERR

# For Intune custom attributes ONLY — output error and exit
trap 'output_result "Error: Script failed at line $LINENO"' ERR
```

### Try-Catch Pattern (Bash 4+)

```bash
# Function with error handling
safe_operation() {
    local result
    if ! result=$(some_command 2>&1); then
        log_message "ERROR" "Operation failed: $result"
        return 1
    fi
    echo "$result"
    return 0
}

# Usage
if ! output=$(safe_operation); then
    log_message "ERROR" "Could not complete operation"
    exit 1
fi
```

### Cleanup on Exit

```bash
cleanup() {
    log_message "INFO" "Performing cleanup..."
    # Remove temporary files
    rm -f /tmp/intune-script-temp-*
    # Kill background processes if needed
    # kill $BACKGROUND_PID 2>/dev/null
}

trap cleanup EXIT
```

---

## Common Patterns

### Check and Install Application

```bash
# Check if app is installed
APP_PATH="/Applications/Google Chrome.app"
if [[ -d "$APP_PATH" ]]; then
    APP_VERSION=$(defaults read "$APP_PATH/Contents/Info" CFBundleShortVersionString 2>/dev/null)
    log_message "INFO" "App installed: $APP_VERSION"
else
    log_message "INFO" "App not installed, installing..."
    # Install logic here
fi
```

### Manage Plist Values

```bash
PLIST_PATH="/Library/Preferences/com.example.app"

# Read value
VALUE=$(/usr/libexec/PlistBuddy -c "Print :SettingKey" "$PLIST_PATH" 2>/dev/null)

# Set value
/usr/libexec/PlistBuddy -c "Add :SettingKey string 'desired-value'" "$PLIST_PATH" 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Set :SettingKey 'desired-value'" "$PLIST_PATH"

# Delete value
/usr/libexec/PlistBuddy -c "Delete :SettingKey" "$PLIST_PATH" 2>/dev/null
```

### Manage Launch Agents/Daemons

```bash
# Check if Launch Agent is loaded
AGENT_LABEL="com.example.agent"
if launchctl list | grep -q "$AGENT_LABEL"; then
    log_message "INFO" "Launch Agent is loaded"
else
    log_message "INFO" "Loading Launch Agent..."
    launchctl load "/Library/LaunchAgents/$AGENT_LABEL.plist"
fi

# Unload Launch Agent
launchctl unload "/Library/LaunchAgents/$AGENT_LABEL.plist" 2>/dev/null
```

### File Operations

```bash
# Check if file exists and is readable
if [[ -f "$FILE_PATH" ]] && [[ -r "$FILE_PATH" ]]; then
    # Process file
    :
fi

# Create directory if it doesn't exist
if [[ ! -d "$DIR_PATH" ]]; then
    mkdir -p "$DIR_PATH"
    log_message "INFO" "Created directory: $DIR_PATH"
fi

# Copy file with backup
if [[ -f "$TARGET_FILE" ]]; then
    cp "$TARGET_FILE" "$TARGET_FILE.bak.$(date +%Y%m%d)"
fi
cp "$SOURCE_FILE" "$TARGET_FILE"
```

### User Account Operations

```bash
# Get all local users
dscl . list /Users | grep -v '^_'

# Check if user exists
USERNAME="jsmith"
if dscl . -read /Users/"$USERNAME" &> /dev/null; then
    log_message "INFO" "User $USERNAME exists"
else
    log_message "INFO" "User $USERNAME does not exist"
fi

# Get user's groups
dscl . -read /Groups "$USERNAME" GroupMembership 2>/dev/null | awk -F': ' '{print $2}'
```

### Network Operations

```bash
# Check network connectivity
if ping -c 1 "example.com" &> /dev/null; then
    log_message "INFO" "Network connectivity OK"
else
    log_message "ERROR" "No network connectivity"
    exit 1
fi

# Check if specific port is open
if nc -z "server.example.com" 443 2>/dev/null; then
    log_message "INFO" "Port 443 is open"
else
    log_message "ERROR" "Port 443 is not accessible"
fi
```

---

## Intune Custom Attributes

For Intune custom attributes, the script must output a **single line** as the result:

```bash
#!/bin/bash

# Get the information
OS_VERSION=$(sw_vers -productVersion)

# Output single line result
echo "macOS $OS_VERSION"
exit 0
```

### Examples

```bash
# Disk space check
DISK_FREE=$(df -g / | tail -1 | awk '{print $4}')
echo "Free disk: ${DISK_FREE}GB"

# Last login check
LAST_LOGIN=$(last -1 "$loggedInUser" | head -1 | awk '{print $4, $5, $6, $7, $8}')
echo "Last login: $LAST_LOGIN"

# App version check
APP_VERSION=$(defaults read "/Applications/Chrome.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "Not installed")
echo "Chrome: $APP_VERSION"

# Compliance status
if [[ "$DISK_FREE" -gt 10 ]]; then
    echo "Compliant"
else
    echo "Non-compliant: Low disk space"
fi
```

---

## Cleanup

```bash
cleanup() {
    log_message "INFO" "Performing cleanup..."
    # Remove temporary files
    rm -f /tmp/intune-script-temp-*
}

trap cleanup EXIT
```

**Why cleanup on EXIT?** It ensures temporary files are removed even if the script fails unexpectedly.
