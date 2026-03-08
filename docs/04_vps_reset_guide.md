# Guide: VPS Reinstallation (Factory Reset)

**Version: 6.0**

This guide provides two methods for completely reinstalling the operating system on your VPS.

> **WARNING:** Both methods are **fully destructive** and will permanently erase all data on the server, including all Docker containers, volumes, and configurations. Back up the `/docker_apps` directory if you need to preserve any data.

---

### Method 1: SSH-Based Reinstall (Recommended)

This method is faster and can be performed entirely from an active SSH session without needing to log into the ServerOptima control panel (except to retrieve the new root password at the end).

**How it Works:**
The `04_reinstall_os.sh` script downloads the Ubuntu 24.04.4 netboot installer, customizes it with your server's static IP configuration, creates a temporary GRUB boot entry for it, and reboots. The server then boots into the fully automated installer and rebuilds itself.

**Steps:**

1.  **Connect to the VPS** via SSH.

2.  **Run the Reinstall Script:**

    ```bash
    sudo /home/ubuntu/xinle-infra/scripts/04_reinstall_os.sh
    ```

3.  **Confirm the Action:** The script will perform several safety checks and requires you to type `ERASE MY SERVER` to proceed.

4.  **Reboot:** Once the script finishes preparing the installer, it will prompt you to reboot. Type `sudo reboot`.

5.  **Wait:** The reinstallation process will take approximately 10-20 minutes. The server will reboot automatically one final time when it's finished.

6.  **Retrieve New Password:** Log into the ServerOptima control panel (`my.serveroptima.com`) to find the new root password for the fresh installation.

7.  **Resume:** You can now SSH back into the server as `root` and run the [one-line deployment command](README.md#4-one-line-deployment) to redeploy the entire stack.

---

### Method 2: ServerOptima Control Panel

This is the traditional method using the provider's web interface.

**Steps:**

1.  **Log in** to the ServerOptima client area at `https://my.serveroptima.com/`.
2.  Navigate to **Services > My Services** and select your VPS.
3.  Find and click the **Rebuild** button on the VPS management dashboard.
4.  In the OS selection dropdown, choose **Ubuntu 24.04.4 LTS (64-bit)**.
5.  Confirm the destructive action.
6.  Wait for the process to complete. You will receive an email with the new root password.
7.  SSH into the server as `root` and run the one-line deployment command.
