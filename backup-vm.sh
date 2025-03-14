#!/bin/bash

# Check if the backup path and storage parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide vm id to backup [all or vm id (coma separated)] and the path to the Proxmox backups as parameters."
    echo "For example:"
    echo " - Backup all vm to path:"
    echo "    ./backup-vm.sh all /path/to/backups"
    echo " - Backup vm with id 100 to path:"
    echo "    ./backup-vm.sh 100 /path/to/backups"
    echo " - Backup vm with id 100 and 101 to path:"
    echo "    ./backup-vm.sh 100,101 /path/to/backups"

    echo "Specify backup mode (if not specified default snapshot mode is used):"
    echo "  * snapshot – takes a live snapshot of a Proxmox virtual machine or container. This mode is used by default and allows you to perform a backup when a VM or container is running."
    echo "  * suspend – this mode is used to suspend the VM or container before backing up which allows you to ensure that data is consistent. Short downtime caused by this mode is a disadvantage."
    echo "  * stop – stops the virtual machine or container before performing the backup. This approach allows you to preserve backup data consistency but requires more extended downtime."
    echo "For example:" 
    echo "    ./backup-vm.sh all /path/to/backups snapshot"
    echo "    ./backup-vm.sh 100 /path/to/backups snapshot"
    echo "    ./backup-vm.sh 100,101 /path/to/backups snapshot"
    exit 1
fi

# Specify the path where the Proxmox backups are located
vm_id="$1"
backup_path="$2"
backup_mode="$3"

# Create backup directory if it doesn't exist
mkdir -p "$backup_path"

# Function to backup a single VM
backup_vm() {
    local id=$1
    
    # Check if VM exists
    if ! qm list | grep -q "^[[:space:]]*$id[[:space:]]"; then
        echo "VM with ID $id does not exist"
        return 1
    fi

    echo "Backing up VM $id..."

    if [ -n "$backup_mode" ]; then
        # Print the command to be executed with mode
        echo " - Executing command:  vzdump $id --compress zstd --dumpdir $backup_path --mode $backup_mode"
        vzdump $id --compress zstd --dumpdir "$backup_path" --mode "$backup_mode"
    else
        # Print the command to be executed without mode
        echo " - Executing command:  vzdump $id --compress zstd --dumpdir $backup_path"
        vzdump $id --compress zstd --dumpdir "$backup_path"
    fi
}

# Check if we should backup all VMs or specific ones
if [ "$vm_id" = "all" ]; then
    echo "Backing up all VMs..."
    qm list | tail -n +2 | awk '{print $1}' | while read id; do
        backup_vm $id
    done
else
    # Split comma-separated VM IDs and backup each one
    IFS=',' read -ra VM_IDS <<< "$vm_id"
    for id in "${VM_IDS[@]}"; do
        if [[ $id =~ ^[0-9]+$ ]]; then
            backup_vm $id
        else
            echo "Invalid VM ID: $id"
        fi
    done
fi