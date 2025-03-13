#!/bin/bash

# Check if the backup path and storage parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Please provide the path to the Proxmox backups and storage destination as parameters."
    echo "For example:"
    echo " - Restore vm from local storage:"
    echo "    ./restore-vm.sh /path/to/backups local"
    echo " - Restore vm from NFS storage:"
    echo "    ./restore-vm.sh /path/to/backups nfs"
    echo " - Restore vm from LVM storage:"
    echo "    ./restore-vm.sh /path/to/backups storage-lvm"
    exit 1
fi

# Specify the path where the Proxmox backups are located
backup_path="$1"
storage="$2"

# Sort the files by VM ID numerically from lowest to biggest (considering numbers like 100, 1000, etc.)
sorted_files=$(find $backup_path -maxdepth 1 -type f -name "*.vma.zst" | sort -t '-' -k3,3n -k4,4n)

# Iterate over the sorted .vma.zst backups
for backup_file in $sorted_files; do
    # Extract the VM ID from the backup filename
    vm_id=$(echo "$backup_file" | grep -oP 'vzdump-qemu-\K\d+(?=-)')
    
    echo "Restoring VM $vm_id... using storage $storage"
    
    # Print the command to be executed
    echo " - Executing command:  qmrestore $backup_file $vm_id --force true --storage $storage"
    
    # Import the backup using the Proxmox qmrestore command with the extracted VM ID
    #qmrestore --storage $storage $vm_id "$backup_file"
    qmrestore "$backup_file" $vm_id --force true --storage $storage
done
