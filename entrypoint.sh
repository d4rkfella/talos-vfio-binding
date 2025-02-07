#!/bin/bash
set -e

export_zpool() {
  if [ -z "$ZPOOL_NAME" ]; then
    echo "ZPOOL_NAME is not set. Skipping zpool export."
    return 0
  fi

  # Check if the zpool is currently imported
  if ! zpool list "$ZPOOL_NAME" >/dev/null 2>&1; then
    echo "Zpool $ZPOOL_NAME is already exported or does not exist. Skipping export."
    return 0
  fi

  echo "Attempting to export zpool $ZPOOL_NAME..."
  if zpool export "$ZPOOL_NAME"; then
    echo "Zpool $ZPOOL_NAME exported successfully."
  else
    echo "Error: Failed to export zpool $ZPOOL_NAME."
    return 1
  fi
}

check_and_bind() {
  DEVICE=$1
  EXPECTED_DRIVER="vfio-pci"
  CURRENT_DRIVER=$(basename $(readlink /sys/bus/pci/devices/$DEVICE/driver) 2>/dev/null || echo "none")

  if [ "$CURRENT_DRIVER" != "$EXPECTED_DRIVER" ]; then
    if [ "$CURRENT_DRIVER" != "none" ]; then
      echo "Unbinding device $DEVICE from driver $CURRENT_DRIVER"
      echo $DEVICE > /sys/bus/pci/devices/$DEVICE/driver/unbind
    fi

    # Set driver_override
    echo "Setting driver_override for device $DEVICE to $EXPECTED_DRIVER"
    echo "$EXPECTED_DRIVER" > /sys/bus/pci/devices/$DEVICE/driver_override

    # Bind the device to the new driver
    echo "Binding device $DEVICE to $EXPECTED_DRIVER"
    echo $DEVICE > /sys/bus/pci/drivers/$EXPECTED_DRIVER/bind
  else
    echo "Device $DEVICE is already bound to $EXPECTED_DRIVER"
  fi
}

export_zpool

IFS=',' read -r -a PCI_DEVICES <<< "$PCI_IDS"
for DEVICE in "${PCI_DEVICES[@]}"; do
  check_and_bind "$DEVICE"
done
