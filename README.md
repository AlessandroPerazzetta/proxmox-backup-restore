# Proxmox VM Backup and Restore Scripts

Simple shell scripts to backup and restore Proxmox VMs.
Typically useful for backup to external storage.

## Scripts

- `backup-vm.sh` - Creates VM backups
- `restore-vm.sh` - Restores VM from backups

## Usage

### Backup

```bash
./backup-vm.sh <vmid> <path_to_backups>
```

This will create a backup of the specified VM in the default Proxmox backup location.
VM id could be all or a list of specified id comma separated
Example:

    - all (this backup all vm retrieving list automatically)

    - 101 (this backup vm with id 101)

    - 101,102,103 (this backup vm 101, 102 and 103)

### Restore 

```bash
./restore-vm.sh <path_to_backups> <storage>
```

Restores VM from the backup path with specific storage destination.

## Requirements

- Proxmox VE installation
- Root/sudo access
- Sufficient storage space for backups

## Notes

- Backup files are stored in the default Proxmox backup location
- Make sure to have enough free space before running backups
- Original VM IDs and names are preserved in backup files