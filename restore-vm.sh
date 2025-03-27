#!/bin/bash

# Check if the backup path and storage parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Please provide vm id to backup [all or vm id (coma separated)] and then the path to the Proxmox backups and storage destination as parameters."
    echo "For example:"
    echo ""
    echo "-----------------------------------------"
    echo " Example usage for restore all vms:"
    echo "-----------------------------------------"
    echo " - Restore all vms from /path/to/backups and set vm to use local storage:"
    echo "    ./restore-vm.sh all /path/to/backups local"
    echo " - Restore all vms from /path/to/backups and set vm to use NFS storage:"
    echo "    ./restore-vm.sh all /path/to/backups nfs"
    echo " - Restore all vms from /path/to/backups and set vm to use LVM storage:"
    echo "    ./restore-vm.sh all /path/to/backups storage-lvm"
    echo "-----------------------------------------"
    echo " Example usage for restore specific vm:"
    echo "-----------------------------------------"
    echo " - Restore vm with id 100 from /path/to/backups and set vm to use local storage:"
    echo "    ./restore-vm.sh 100 /path/to/backups local"
    echo " - Restore vms with id 100,101 from /path/to/backups and set vm to use local storage:"
    echo "    ./restore-vm.sh 100,101 /path/to/backups local"
    exit 1
fi

# Specify the path where the Proxmox backups are located
vm_id="$1"
backup_path="$2"
storage="$3"

# Check if the backup path exists
if [ ! -d "$backup_path" ]; then
    echo "Backup path $backup_path does not exist."
    exit 1
fi

# Check if the storage destination is valid
if ! pvesm status | grep -q "^$storage\s"; then
    echo "Storage destination $storage does not exist."
    exit 1
fi

restore_vm() {
    local files_to_restore="$1"

    # Print the VMs to be restored and ask for confirmation
    echo "The following VMs will be restored:"
    for backup_file in $files_to_restore; do
        vm_id=$(echo "$backup_file" | grep -oP 'vzdump-qemu-\K\d+(?=-)')
        echo " - VM ID: $vm_id from file: $backup_file"
    done

    read -p "Do you want to continue with the restoration? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Restoration aborted."
        exit 1
    fi

    for backup_file in $files_to_restore; do
        # Extract the VM ID from the backup filename
        vm_id=$(echo "$backup_file" | grep -oP 'vzdump-qemu-\K\d+(?=-)')
        
        echo "Restoring VM $vm_id... using storage $storage"
        
        # Print the command to be executed
        echo " - Executing command:  qmrestore $backup_file $vm_id --force true --storage $storage"
        
        # Import the backup using the Proxmox qmrestore command with the extracted VM ID
        #qmrestore --storage $storage $vm_id "$backup_file"
        qmrestore "$backup_file" $vm_id --force true --storage $storage
    done
}

# Determine the files to restore based on the vm_id argument
if [ "$vm_id" == "all" ]; then
    # Sort the files by VM ID numerically from lowest to biggest (considering numbers like 100, 1000, etc.)
    files_to_restore=$(find $backup_path -maxdepth 1 -type f -name "*.vma.zst" | sort -t '-' -k3,3n -k4,4n)
else
    IFS=',' read -ra vm_ids <<< "$vm_id"
    files_to_restore=""
    for id in "${vm_ids[@]}"; do
        file=$(find $backup_path -maxdepth 1 -type f -name "*vzdump-qemu-$id-*.vma.zst")
        if [ -z "$file" ]; then
            echo "Backup file for VM ID $id does not exist."
            exit 1
        fi
        files_to_restore="$files_to_restore $file"
    done
fi
restore_vm "$files_to_restore"