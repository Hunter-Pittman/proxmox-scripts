#!/bin/bash

# Check if the user provided the required number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <ova_url> <vmid>"
    exit 1
fi

ova_url="$1"
ova_filename=$(basename "$ova_url")
vmid="$2"
node="$3"

# Function to clean up temporary directories
cleanup() {
    echo "Cleaning up temporary directories..."
    rm -rf "$ova_dir"
    rm $ova_filename
}

# Register the cleanup function to be called when the script exits
trap cleanup EXIT

# Download the .ova file from the provided URL
if ! wget "$ova_url" -O "$ova_filename"; then
    echo "Error: Failed to download the .ova file from the provided URL."
    exit 1
fi

# Check if the downloaded file has a .ova extension
if [[ "$ova_filename" != *.ova ]]; then
    echo "Error: The downloaded file is not a .ova file."
    exit 1
fi

# Extract the .ova file
ova_dir="${ova_filename%.ova}"
mkdir -p "$ova_dir"
tar -xvf "$ova_filename" -C "$ova_dir"

# Inform the user about the extraction
echo "Extracted '$ova_filename' to '$ova_dir'."

# Enter the newly created directory
cd "$ova_dir" || exit 1

# Unzip any .vmdk.gz files
gzip -d *.vmdk.gz


# Create a new virtual machine on Proxmox
qm create "$vmid" -name "$ova_filename" -ostype l26 -sockets 1 -cores 4 -memory 4192 -net0 virtio,bridge=vmbr1

# Save the name of the OVA file without the ".ova" extension
disk1_vmdk_name="${ova_filename%.ova}-disk1.vmdk"

# Import the disk to the new virtual machine
qm importdisk "$vmid" "$disk1_vmdk_name" CBT -format qcow2

# You can add more processing or error handling as needed
cd ..