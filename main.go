package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
)

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	if os.Geteuid() != 0 {
		log.Fatal("This program must be run as root")
	}

	pciIDs := os.Getenv("PCI_IDS")
	if pciIDs == "" {
		log.Fatal("PCI_IDS environment variable not set")
	}

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()

	processDevices(ctx, strings.Split(pciIDs, ","))
}

func processDevices(ctx context.Context, devices []string) {
	for _, rawDevice := range devices {
		device := strings.TrimSpace(rawDevice)
		if device == "" {
			continue
		}

		if err := ctx.Err(); err != nil {
			log.Printf("Aborting processing due to: %v", err)
			return
		}

		log.Printf("Processing device: %s", device)
		if err := checkAndBind(device); err != nil {
			log.Printf("Device %s error: %v", device, err)
		}
	}
}

func checkAndBind(device string) error {
	const targetDriver = "vfio-pci"

	currentDriver, err := getCurrentDriver(device)
	if err != nil {
		return fmt.Errorf("driver detection failed: %w", err)
	}

	if currentDriver == targetDriver {
		log.Printf("Device %s already bound to %s", device, targetDriver)
		return nil
	}

	if currentDriver != "none" {
		if err := unbindDevice(device); err != nil {
			return fmt.Errorf("unbind failed: %w", err)
		}
	}

	if err := setDriverOverride(device, targetDriver); err != nil {
		return err
	}

	defer func() {
		if err := clearDriverOverride(device); err != nil {
			log.Printf("Cleanup warning for %s: %v", device, err)
		}
	}()

	return bindDevice(device, targetDriver)
}

func getCurrentDriver(device string) (string, error) {
	driverLink := filepath.Join("/sys/bus/pci/devices", device, "driver")
	
	target, err := os.Readlink(driverLink)
	if err != nil {
		if os.IsNotExist(err) {
			return "none", nil
		}
		return "", fmt.Errorf("driver link read failed: %w", err)
	}
	return filepath.Base(target), nil
}

func unbindDevice(device string) error {
	unbindPath := filepath.Join("/sys/bus/pci/devices", device, "driver/unbind")
	log.Printf("Unbinding %s", device)
	return writeSysFsFile(unbindPath, device)
}

func setDriverOverride(device, driver string) error {
	overridePath := filepath.Join("/sys/bus/pci/devices", device, "driver_override")
	log.Printf("Setting driver override for %s to %q", device, driver)
	return writeSysFsFile(overridePath, driver)
}

func clearDriverOverride(device string) error {
	overridePath := filepath.Join("/sys/bus/pci/devices", device, "driver_override")
	log.Printf("Clearing driver override for %s", device)
	return writeSysFsFile(overridePath, "")
}

func bindDevice(device, driver string) error {
	bindPath := filepath.Join("/sys/bus/pci/drivers", driver, "bind")
	log.Printf("Binding %s to %s", device, driver)
	return writeSysFsFile(bindPath, device)
}

func writeSysFsFile(path, content string) error {
	file, err := os.OpenFile(path, os.O_WRONLY, 0200)
	if err != nil {
		return fmt.Errorf("failed to open %s: %w", path, err)
	}
	defer file.Close()

	if _, err := file.WriteString(content); err != nil {
		return fmt.Errorf("write failed for %s: %w", path, err)
	}

	return nil
}