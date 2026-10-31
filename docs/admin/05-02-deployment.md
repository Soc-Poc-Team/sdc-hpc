## Cluster hardware

The `small-data-cluster` is designed to run on standard `x86_64` hardware. This
includes most modern desktop computers, workstations, servers, and mini-PCs.

The provided images include a broad selection of Linux kernel modules, device
drivers, and commonly required firmware in order to support a wide range of
hardware. Nevertheless, hardware compatibility cannot be guaranteed for every
device.

Older, unusual, or highly specialized hardware may require additional drivers or
firmware that are not included in the standard images.

### Physical security

Physical access to cluster hardware must be treated as a security-sensitive
privilege.

You should assume that a person with unrestricted physical access to a cluster
node or its bootable USB drive may be able to access, modify, copy, or destroy
data stored on the cluster.

Depending on the machine and its firmware configuration, a person with physical
access may also be able to:

- Boot another operating system
- Remove or replace the cluster USB drive
- Copy the contents of the USB drive
- Modify firmware settings
- Access local TTYs
- Connect additional storage or network devices

For this reason, machines used as part of a `small-data-cluster` should be
located in an environment where physical access is restricted to authorized
personnel.

This is especially important when the cluster processes confidential, internal,
personal, or otherwise sensitive data.

> **Security warning:** Operating-system permissions alone cannot reliably
> protect a machine against an attacker with unrestricted physical access.
> Physical security is therefore an important part of the cluster's overall
> security model.

### Disable Secure Boot before deployment

The current `small-data-cluster` images do not support Secure Boot.

Secure Boot must therefore be disabled on every machine that will boot a
physical `small-data-cluster` image.

If Secure Boot remains enabled, the machine's firmware may refuse to start the
image or may display an error indicating that the bootloader, operating system,
or signature is not trusted.

Refer to the earlier [Secure Boot](#secure-boot) section before changing this
setting to learn more.

> **Important:** Disabling Secure Boot removes one layer of protection from the
> system's boot process. Ensure that this is acceptable according to your
> organization's security requirements before continuing.

### Prepare the hardware

Before starting the cluster, prepare each machine as follows:

1. Shut the machine down completely.
2. Connect the machine to the wired network that will be used by the cluster.
3. Ensure that the network provides internet access without requiring a
   browser-based login, user authentication, or manually installed client
   certificates.
4. Connect a monitor and keyboard if you want to observe the initial boot
   process or expect that firmware changes may be required.
5. Verify that Secure Boot has been disabled.
6. Insert the prepared USB drive into the machine.

> **Note:** You do not need to attach a mouse, keyboard, or monitor. All
> `small-data-cluster` nodes can run in headless mode. You can interact with the
> entire cluster, including its command-line interface, through a web browser.

When possible, connect the USB drive directly to a USB port on the machine
rather than through an external hub.

If both the drive and machine support USB 3.0 or newer, use a compatible
high-speed port. USB 3.0 ports are commonly identified by a blue connector
insert, although some manufacturers do not always follow this convention.

### Start the cluster

The recommended startup order is to start the headnode first and then start the
worker nodes.

Starting the headnode first is not strictly required, but it simplifies the
startup process.

Proceed as follows:

1. Insert the headnode USB drive into the machine selected as the headnode.
2. Power on the machine.
3. Ensure that the machine boots from the USB drive.
4. Wait until the headnode has completed its startup process.
5. Insert USB drives and start the worker nodes.
6. Allow the worker nodes to complete their startup and connect to the headnode.

The worker nodes can be configured to wait for the headnode to become reachable.
The length of this waiting period is controlled by the `headnodeTimeout`
configuration option.

If the timeout is reached before the headnode becomes available, the worker node
may stop attempting to start its cluster services. In that case, resolve the
problem and reboot the affected worker node.

### Recognize a successful headnode boot

When a monitor is connected to the headnode, the startup process produces a
significant amount of text while Linux and the cluster services are initialized.

This is normal.

The headnode is ready for initial interaction when the boot process completes
and the large:

```text
small-data-cluster
```

banner is displayed.

The presence of this banner indicates that the machine has successfully booted
the cluster image. Some services may not make their interfaces available
immediately; this is expected. Everything should be available after a few
minutes. Do not assume that a machine has failed simply because the boot process
pauses for several seconds during service initialization.

### Worker startup

Worker nodes generally require no manual interaction after they have
successfully booted. However, you can open a TTY on a worker node by pressing
`Ctrl+Alt+F2` through `Ctrl+Alt+F9` and sign in as the local user `nixos`.

If `showJournal` is enabled in the cluster configuration, worker nodes display
system log output on `tty1`. This can be useful when diagnosing startup
problems.

During startup, a worker node will attempt to:

1. Initialize its hardware.
2. Configure its network connection.
3. Establish its Tailscale connection.
4. Locate the headnode.
5. Verify compatibility with the headnode where required.
6. Start its cluster services.
7. Join the cluster.

Depending on the network and hardware, this process may take several minutes.

### Do not install the system on the internal disk

The `small-data-cluster` is intended to boot from the prepared USB drives. You
do not need to install NixOS or the cluster software onto the internal disks of
the machines.

If an installer or another operating system appears instead of the
`small-data-cluster`, stop and verify which device the machine has booted from.

> **Note:** The `small-data-cluster` does not intentionally modify the contents
> of internal storage devices during normal operation. However, software
> executed on the cluster may still detect, mount, access, or modify internal
> drives if sufficient permissions are available.
>
> Consider internal storage devices as part of your security assessment,
> particularly when reusing machines that contain organizational or personal
> data. Full-disk encryption, such as BitLocker or LUKS, can significantly
> reduce the risk of unauthorized access while the encrypted volume remains
> locked. However, encryption should not be treated as an absolute safeguard,
> especially if decryption keys, recovery keys, or already-unlocked volumes are
> accessible to the running system.

## Troubleshoot boot problems

The most common problem during initial deployment is that the machine **does not
boot** from the USB drive.

The exact configuration interface differs between manufacturers, but the general
troubleshooting procedure is similar across most desktop computers,
workstations, mini-PCs, and servers.

### The machine boots its existing operating system

If the machine starts Windows, Linux, or another operating system already
installed on its internal drive, it probably did not boot from the
`small-data-cluster` USB drive.

First, shut the machine down again.

Verify that:

- The correct USB drive is inserted.
- The USB drive is fully inserted into the port.
- The drive was flashed successfully.

Then start the machine and open its temporary boot menu.

Common keys used to open a boot menu include:

- `F12`
- `F11`
- `F10`
- `F9`
- `Esc`

The exact key depends on the manufacturer and model. Consult the manufacturer’s
documentation or use a search engine to find the correct key for the specific
model.

The appropriate key is often briefly displayed immediately after powering on the
computer, for example:

```text
F12 Boot Menu
```

or:

```text
Press ESC for Startup Menu
```

You may need to press the key repeatedly immediately after powering on the
machine.

In the boot menu, select the USB drive.

The entry may be displayed using:

- The USB drive manufacturer's name
- The USB device model
- `USB HDD`
- `USB Storage`
- `UEFI USB`
- A similar description

If both a UEFI and a legacy entry exist for the same USB drive, prefer the UEFI
entry.

### The USB drive does not appear in the boot menu

If the USB device does not appear at all, first try another USB port.

Prefer a USB port directly attached to the machine. On desktop computers, rear
motherboard ports are often more reliable for booting than front-panel ports or
external hubs.

You should also try:

1. Powering the machine off completely.
2. Removing the USB drive.
3. Reinserting it.
4. Starting the machine again.
5. Reopening the boot menu.

If the drive is still missing, test whether the same USB drive appears on
another computer.

If another machine can detect and boot from the drive, the problem is probably
related to the firmware configuration of the original machine.

If no machine can detect the drive correctly, reflash the USB drive.

### Enter the BIOS or UEFI setup

If selecting the USB device from the temporary boot menu does not solve the
problem, you may need to change the machine's firmware configuration.

The firmware configuration interface is commonly referred to as the **BIOS** or
**UEFI setup**.

Although UEFI has replaced traditional BIOS firmware on most modern systems,
manufacturers often continue to use terms such as "BIOS Setup".

Common keys for entering the firmware setup include:

- `F2`
- `Delete`
- `Esc`
- `F1`
- `F10`

Press the appropriate key immediately after powering on the machine.

If you do not know the correct key, search the manufacturer's documentation for:

```text
<Device manufacturer> <model> enter BIOS
```

or:

```text
<Device manufacturer> <model> UEFI setup key
```

For example:

```text
Dell OptiPlex 7090 enter BIOS
```

### Check the boot order

Inside the firmware settings, look for a menu named something similar to:

- `Boot`
- `Boot Options`
- `Boot Sequence`
- `Startup`
- `Boot Priority`

Ensure that USB storage devices are allowed as boot devices.

You may either place USB storage above the internal disk in the permanent boot
order or continue using the temporary boot menu each time the machine starts.

For dedicated cluster hardware, placing USB storage before the internal disk can
be convenient.

For machines that are also used for other purposes, using the temporary boot
menu may be safer because it avoids permanently changing the normal boot order.

Save the firmware configuration before exiting.

The menu item is commonly called:

```text
Save and Exit
```

or:

```text
Save Changes and Reboot
```

### Secure Boot errors

If you see messages similar to:

```text
Security Violation
```

```text
Invalid Signature
```

```text
Verification Failed
```

or:

```text
Unauthorized Operating System
```

Secure Boot is probably still enabled.

Return to the firmware configuration and disable Secure Boot.

Depending on the manufacturer, this setting may be located under menus such as:

- `Security`
- `Boot`
- `Authentication`
- `Secure Boot`
- `UEFI Settings`

After changing the option, save the configuration and restart the machine.

Some systems require an administrator or firmware password before Secure Boot
settings can be changed.

If the machine belongs to your organization and these settings are locked,
contact the person or department responsible for managing the hardware.

Do not attempt to bypass organizational firmware restrictions without
authorization.

### The machine shows a black screen

A black screen does not necessarily mean that the machine failed to boot.

First, wait for approximately one or two minutes and observe whether:

- The USB drive activity indicator flashes.
- Network-interface LEDs become active.
- The machine remains powered on.
- The monitor eventually receives a signal.

Then verify:

- The monitor is connected to the correct display output.
- The monitor is switched on.
- The correct input source is selected.
- The display cable is connected securely.

Systems with both integrated and dedicated graphics hardware may expose multiple
video outputs. Try another display connector if necessary.

If the machine appears to be running but no display is available, you may still
be able to diagnose it through the network later. For initial deployment,
however, using hardware with a working local display is strongly recommended.

### The machine reboots or returns to the boot menu

If the machine begins to boot from the USB drive but immediately restarts or
returns to the boot menu, possible causes include:

- An incomplete or corrupted USB image
- A defective USB drive
- An unsupported firmware configuration
- Hardware incompatibility
- Secure Boot still being enabled

Reflash the image first.

If the problem persists, try another USB drive and another USB port.

You can also test the image on a different computer. If the same image works on
another system, the problem is likely specific to the original hardware or
firmware configuration.

### The boot process stops with error messages

Linux displays many informational messages during startup. Messages containing
terms such as `warning`, `failed`, or `error` do not always indicate that the
complete boot process has failed.

Wait and observe whether startup continues.

A problem should generally be investigated when:

- The same error is repeated continuously.
- The machine remains at the same step for an extended period.
- An emergency shell is displayed.
- The system explicitly reports that booting failed.
- The expected `small-data-cluster` banner never appears.

Record the error message exactly as displayed.

If possible, take a photograph of the screen. The final lines shown before the
system stops are usually the most useful for troubleshooting.

### Network interface not detected

A node may boot successfully but fail later because its Ethernet adapter is not
recognized.

Typical indications include messages referring to:

- No network interface
- No carrier
- DHCP failure
- Network unreachable
- Failure to contact Tailscale
- Failure to reach the headnode

First verify the physical connection.

Check that:

- The Ethernet cable is connected securely.
- The switch or router is powered on.
- Link LEDs are visible on the Ethernet port where available.
- The same cable works with another device.

If there is no link indication at all, try another Ethernet cable and switch
port.

If the physical connection works but Linux does not detect the network adapter,
the hardware may require a driver or firmware component that is not included in
the current image.

### Network connection exists but the node cannot reach the internet

The cluster requires internet access during normal startup.

If the node obtains a network connection but cannot reach external services,
check whether the network requires:

- A captive portal
- Browser-based authentication
- IEEE 802.1X authentication
- A manually configured proxy
- Client certificates
- Static IP configuration
- Special VLAN configuration

The standard `small-data-cluster` deployment expects a wired Ethernet connection
that provides ordinary DHCP-based network access without interactive
authentication.

If your organization's network requires additional authentication or
configuration, the default image may not work without modification.

### A worker node cannot reach the headnode

If the headnode appears to start correctly but a worker node does not join the
cluster, first ensure that the headnode was given enough time to finish booting.

Then verify that both machines:

- Have working internet access.
- Are connected to the intended network.
- Have the correct Tailscale configuration.
- Were built from the same cluster configuration.
- Were built from a compatible project revision.

If the worker node was started significantly earlier than the headnode, it may
also have reached its configured `headnodeTimeout`.

Rebooting the worker node after the headnode is fully available is a simple
first troubleshooting step.

### A node was flashed with an old configuration

All nodes in one cluster should be built from the same project revision and
configuration.

If you change configuration values and rebuild the images, reflash the headnode
and all affected worker USB drives.

Do not intentionally operate a cluster containing images from different
configurations unless you fully understand the compatibility implications.

Configuration differences may result in:

- Authentication failures
- Different Tailscale credentials
- Missing or inconsistent users
- UID mismatches
- Service incompatibilities
- Different cluster software versions
- Unexpected file permissions

If you suspect that one node contains an outdated image, the safest approach is
to rebuild the complete image set and reflash the affected drive.

### USB drive errors

USB flash drives are inexpensive storage devices and can fail.

Typical symptoms of a failing drive include:

- `dd` errors during flashing
- Very slow write performance
- The drive repeatedly disconnecting
- Boot failures on different machines
- Read errors during startup
- The device disappearing from `/dev`

If a drive behaves unexpectedly, replace it rather than relying on it for
cluster operation.

Do not use a drive that reported write errors during flashing.

### Test whether the problem is the machine or the USB drive

When troubleshooting, changing one component at a time helps determine where the
problem is located.

For example:

1. Take a USB drive that fails to boot on machine A.
2. Try the same USB drive on machine B.
3. If it boots on machine B, investigate machine A.
4. If it also fails on machine B, reflash or replace the USB drive.
5. If a second known-working USB drive also fails on machine A, investigate
   machine A's firmware and hardware.

This simple process can quickly distinguish a hardware-specific problem from a
corrupted or defective USB drive.

### Last resort: reflash the image

When the cause of a boot problem is unclear, reflashing the affected USB drive
is often a useful troubleshooting step.

Before reflashing:

1. Confirm that the current cluster configuration is correct.
2. Rebuild the images if necessary.
3. Verify the USB device identifier carefully.
4. Flash the image again.
5. Wait until `dd` and `sync` have completed.
6. Safely remove the drive.
7. Attempt to boot the machine again.

If a freshly flashed image repeatedly fails on one machine but works on another,
the issue is likely related to the original machine's hardware or firmware
configuration rather than the image itself.

### Contact us

We do not provide general support for the `small-data-cluster`. However, we are
interested in learning about problems encountered during deployment or
operation, especially when you have identified a possible cause or solution.

**TODO:** Add the project contact address for deployment and operation reports.

When reporting a problem, include as much relevant information as possible:

- Manufacturer and exact model of the affected machine.
- CPU model.
- Amount of installed memory.
- Project revision or Git commit.
- Whether the affected node is the headnode or a worker node.
- The exact error message.
- Relevant system log output.
- A short description of what you expected to happen.
- A short description of what happened instead.
- The steps required to reproduce the problem, if known.

Do not include passwords, API keys, authentication keys, private SSH keys, or
other secrets in a problem report.

Providing precise information helps us distinguish configuration errors,
unsupported hardware, networking problems, and defects in the
`small-data-cluster`.
