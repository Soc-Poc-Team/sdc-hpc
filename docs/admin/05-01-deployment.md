# Deployment

At this stage, you are ready to deploy your cluster. The first part of this
chapter covers writing the generated images to USB drives. The following
sections will then explain how to prepare and operate the physical cluster
hardware.

Alternatively, you can test the cluster virtually before deploying it to
physical machines. The `vms` window in the prepared `tmux` session contains two
panes with commands for starting a virtual headnode and a virtual worker node.

Run the prepared commands to start the virtual machines. Performance in this
environment may be significantly lower than on physical hardware and should not
be considered representative of a real deployment. You may interact with the
virtual machines through the terminals provided in the `tmux` panes or detach
from the session while they continue running.

## Flash the images

The `small-data-cluster` includes a flashing utility that can write the worker
image to multiple USB drives concurrently. Its configuration and safety
mechanisms were described earlier in the section on configuring the flash tool.
Ensure that the authorization file has been prepared and that all listed devices
have been carefully verified before continuing.

### Flash the worker images

To write the worker image to the authorized USB drives:

1. Insert the intended USB drives into the build machine.
2. Attach to the `small-data-cluster` `tmux` session.
3. Open the `flash` window.
4. Review and execute the prepared flashing command. The operation requires
   `sudo` privileges.
5. Wait until all flashing processes have completed and the command prompt
   returns.

The flash tool writes to all connected devices listed in the authorization file.
Each drive is processed independently, and a short summary is displayed when its
write operation completes.

If `dd` encounters a read or write error, flashing for the affected drive will
stop. Do not disconnect, move, or physically disturb a USB drive while it is
being written. An interrupted connection can cause the operation to fail and may
leave the drive with an incomplete or corrupted image.

Flashing may take several minutes, depending on the performance of the USB
drives, the USB ports, and the build machine’s USB controller. This is expected.

After the command has completed successfully and returned to the prompt, the USB
drives can be removed from the build machine. Each successfully written drive
now contains the worker image.

### Flash the headnode image

The headnode image is not written by the multi-device flash tool. It must
currently be written manually using `dd`.

First, identify the complete target device under `/dev` or `/dev/disk/by-id/`.
Then run:

```console
sudo dd \
  if=results/head/iso/headnode.iso \
  of=/dev/disk/by-id/<HEADNODE_USB_DEVICE> \
  status=progress \
  conv=fsync
```

Replace `<HEADNODE_USB_DEVICE>` with the verified identifier of the USB drive
intended for the headnode.

> **Warning:** The target specified by `of` will be overwritten completely.
> Selecting the wrong device may destroy data on an internal disk or another
> connected storage device. Use the identifier of the complete drive, not one of
> its partitions.

You may write the headnode image in a separate terminal while the flash tool is
writing the worker images. Ensure that the headnode drive is not included in the
worker authorization file.

> **Important:** Do not rebuild the cluster images while any flashing operation
> is in progress. Rebuilding may update the `results/` links while another
> process is still reading from them, potentially causing different drives to
> receive images from different builds.
>
> After changing the cluster configuration, rebuild and reflash the headnode and
> **all** worker drives. Do not operate a cluster whose nodes were created from
> different configurations or build revisions, as this may result in
> incompatible services, credentials, or cluster behavior.
