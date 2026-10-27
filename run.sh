#!/bin/bash

set -e

USERNAME="exam"
PASSWORD="exam"
CONFIG="/etc/lightdm/lightdm.conf"

echo "=================================="
echo " Ubuntu User Creation Script"
echo "=================================="

# 1. Create user if it does not exist
if id "$USERNAME" >/dev/null 2>&1; then
    echo "User $USERNAME already exists."
else
    sudo useradd -m -s /bin/bash "$USERNAME"
    echo "User $USERNAME created."
fi

# 2. Set password
echo "$USERNAME:$PASSWORD" | sudo chpasswd
echo "Password configured."

# 3. Create LightDM configuration directory
sudo mkdir -p /etc/lightdm

# 4. Create configuration file if missing
if [ ! -f "$CONFIG" ]; then
    sudo touch "$CONFIG"
fi

# 5. Backup existing configuration
sudo cp "$CONFIG" "$CONFIG.backup"

# 6. Configure LightDM
sudo python3 - "$CONFIG" <<'PY'
import sys

path = sys.argv[1]

with open(path, "r") as f:
    lines = f.readlines()

section = "[Seat:*]"
settings = {
    "greeter-hide-users": "true",
    "greeter-show-manual-login": "true",
}

# Find the Seat section
start = next(
    (i for i, line in enumerate(lines)
     if line.strip() == section),
    None
)

if start is None:
    lines.extend(["\n", section + "\n"])
    start = len(lines) - 1

# Find where the section ends
end = len(lines)
for i in range(start + 1, len(lines)):
    if lines[i].strip().startswith("[") and lines[i].strip().endswith("]"):
        end = i
        break

# Remove existing copies of these settings in this section
lines = [
    line for i, line in enumerate(lines)
    if not (
        start < i < end
        and line.split("=", 1)[0].strip() in settings
    )
]

# Recalculate section boundaries
start = next(i for i, line in enumerate(lines)
             if line.strip() == section)

end = len(lines)
for i in range(start + 1, len(lines)):
    if lines[i].strip().startswith("[") and lines[i].strip().endswith("]"):
        end = i
        break

for key, value in settings.items():
    lines.insert(end, f"{key}={value}\n")
    end += 1

with open(path, "w") as f:
    f.writelines(lines)
PY

echo "LightDM configuration updated."
echo
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo
echo "System will restart in 10 seconds."
sleep 10

sudo reboot
