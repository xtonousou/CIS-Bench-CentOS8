#! /usr/bin/env bash
# Author: Sotirios Roussis - sroussis@space.gr
# Description: Make Centos 8.X CIS compliant

RESET=$'\e[0m'
BOLD=$'\e[1m'
BLINK=$'\e[5m'
RED=$'\e[91m'
GREEN=$'\e[92m'
PURPLE=$'\e[95m'
BLUE=$'\e[94m'

function banner() {
	echo -e "${BOLD}${BLUE}	 _____ _____ _____            _____            _              _____ 
	/  __ \\_   _/  ___|          /  __ \\          | |            |  _  |
	| /  \\/ | | \\ \`--.   ______  | /  \\/ ___ _ __ | |_ ___  ___   \\ V / 
	| |     | |  \`--. \\ |______| | |    / _ \\ '_ \\| __/ _ \\/ __|  / _ \\ 
	| \\__/\\_| |_/\\__/ /          | \\__/\\  __/ | | | || (_) \\__ \\ | |_| |
 	 \\____/\\___/\\____/            \\____/\\___|_| |_|\\__\\___/|___/ \\_____/${RESET}

                    ${BOLD}Benchmark v1.0.0 [Sotirios Roussis - sroussis@space.gr]${RESET}"

	return 0
}

function _help() {
	echo -ne "cis-benchmark-srv-lvl1-centos8.sh - CIS Benchmark v1.0.0 tool for Centos 8.x Server Level 1\\n\\n"
	echo -ne "${BOLD}Usage${RESET}\\n"
	echo -ne "  cis-benchmark-srv-lvl1-centos8.sh --dry\\n"
	echo -ne "  cis-benchmark-srv-lvl1-centos8.sh --execute\\n"
	echo -ne "  cis-benchmark-srv-lvl1-centos8.sh -d -s 1.1.1.2,1.1.15\\n"
	echo -ne "  cis-benchmark-srv-lvl1-centos8.sh -e --skip=1.1.1.2,1.1.15\\n\\n"
	echo -ne "${BOLD}Positional Arguments${RESET}\\n"
	echo -ne "  -h|--help\\tShows this help message.\\n"
	echo -ne "  -d|--dry\\tDry runs the benchmark without any actions. DEFAULT.\\n"
	echo -ne "  -e|--execute\\tRuns the benchmarks and executes the recommended remediations. DANGEROUS.\\n\\n"
	echo -ne "${BOLD}Optional${RESET}\\n"
	echo -ne "  -s|--skip|--skip=<paragraph1,paragraphN>\\tSkips the given checks. NOT IMPLEMENTED YET.\\n\\n"
	return 0
}

function _tab() {
	if [ -n "${1}" ]; then
		if [ -n "${2}" ]; then
			case "${2}" in
				1)
					if [ "${3}" == "exe" ]; then
						echo -e "\\t${1}"
						if [ "${DRY_RUN}" -eq 0 ]; then
							echo -e "$(sed 's/^/\t--> /g' <<< $(eval "${1}"))"
						fi
						return 0
					fi
					echo -e "$(sed 's/^/\t/g' <<< ${1})"
					;;
				2)
					if [ "${3}" == "exe" ]; then
						echo -e "\\t\\t${1}"
						if [ "${DRY_RUN}" -eq 0 ]; then
							echo -e "$(sed 's/^/\t\t--> /g' <<< $(eval "${1}"))"
						fi
						return 0
					fi
					echo -e "$(sed 's/^/\t\t/g' <<< ${1})"
					;;
			esac
		fi
		return 0
	fi

	echo -ne "\\t"
	return 0
}

function console() {
	_tab "${@}" | grep -Ev "\-\->\s?$|^$"
	return "${?}"
}

function benchmark() {
	banner

	echo -e "${GREEN}1.1.1.1 Ensure mounting of cramfs filesystems is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "modprobe -n -v cramfs" 2 exe
	console "lsmod | grep cramfs" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo \"install cramfs /bin/true\" >| /etc/modprobe.d/cramfs.conf" 2 exe
	console "rmmod cramfs 2>/dev/null" 2 exe
	echo

	echo -e "${GREEN}1.1.1.2 Ensure mounting of vFAT filesystems is limited (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "modprobe -n -v vfat" 2 exe
	console "lsmod | grep vfat" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	if ! [ -d /sys/firmware/efi ]; then
		console "Directory /sys/firmware/efi does not exist. System is using BIOS, therefore the vfat module will be disabled" 2
		console "echo \"install vfat /bin/true\" >| /etc/modprobe.d/vfat.conf" 2 exe
		console "rmmod vfat 2>/dev/null" 2 exe
	else
		console "Directory /sys/firmware/efi exists. System is using UEFI, therefore the vfat module will NOT be disabled. UEFI cannot boot without it." 2
	fi
	echo

	echo -e "${GREEN}1.1.1.3 Ensure mounting of squashfs filesystems is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "modprobe -n -v squashfs" 2 exe
	console "lsmod | grep squashfs" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo \"install squashfs /bin/true\" >| /etc/modprobe.d/squashfs.conf" 2 exe
	console "rmmod squashfs 2>/dev/null" 2 exe
	echo

	echo -e "${GREEN}1.1.1.4 Ensure mounting of udf filesystems is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "modprobe -n -v udf" 2 exe
	console "lsmod | grep udf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo \"install udf /bin/true\" >| /etc/modprobe.d/udf.conf" 2 exe
	console "rmmod udf 2>/dev/null" 2 exe
	echo

	echo -e "${GREEN}1.1.2 Ensure /tmp is configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "mount | grep -E '\s/tmp\s'" 2 exe
	console "grep -E '\s/tmp\s' /etc/fstab | grep -E -v '^\s*#'" 2 exe
	console "systemctl is-enabled tmp.mount" 2 exe
	console "systemctl status tmp.mount" 2 exe
	if grep -q tmpfs /etc/fstab; then
		console "${BOLD}[REMEDIATION]${RESET}" 1
		console "Seems that tmpfs is configured in /etc/fstab $(grep tmpfs /etc/fstab)" 2
		console "sed -i '/^tmpfs\s/d' /etc/fstab" 2 exe
		console "echo \"tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0\" >> /etc/fstab" 2 exe
		console "systemctl daemon-reload" 2 exe
		console "Check this URL for bug: https://bugzilla.redhat.com/show_bug.cgi?id=1667065" 2
	fi
	echo

	echo -e "${GREEN}1.1.3 Ensure nodev option set on /tmp partition (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "mount | grep -E '\s/tmp\s' | grep -v nodev" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "nodev option has already been added, see previous remediation 1.1.2" 2
	echo

	echo -e "${GREEN}1.1.4 Ensure nosuid option set on /tmp partition (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "mount | grep -E '\s/tmp\s' | grep -v nosuid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "nosuid option has already been added, see previous remediation 1.1.2" 2
	echo

	echo -e "${GREEN}1.1.5 Ensure noexec option set on /tmp partition (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "mount | grep -E '\s/tmp\s' | grep -v noexec" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "noexec option has already been added, see previous remediation 1.1.2" 2
	echo

	echo -e "${GREEN}1.1.6 Ensure separate partition exists for /var (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.7 Ensure separate partition exists for /var/tmp (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.8 Ensure nodev option set on /var/tmp partition (Scored)${RESET}"
	if df | grep -q /var/tmp; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "mount | grep -E '\s/var/tmp\s' | grep -v nodev" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit the /etc/fstab file and add nodev to the fourth field (mounting options) for the /var/tmp partition. Run the following command to remount /var/tmp" 2
		console "mount -o remount,nodev /var/tmp" 2
	else
		console "/var/tmp is not a seperate partition, therefore no checks or remediations exist" 1
	fi
	echo

	echo -e "${GREEN}1.1.9 Ensure nosuid option set on /var/tmp partition (Scored)${RESET}"
	if df | grep -q /var/tmp; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "mount | grep -E '\s/var/tmp\s' | grep -v nosuid" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit the /etc/fstab file and add nosuid to the fourth field (mounting options) for the /var/tmp partition. Run the following command to remount /var/tmp" 2
		console "mount -o remount,nosuid /var/tmp" 2
	else
		console "/var/tmp is not a seperate partition, therefore no checks or remediations exist" 1
	fi
	echo

	echo -e "${GREEN}1.1.10 Ensure noexec option set on /var/tmp partition (Scored)${RESET}"
	if df | grep -q /var/tmp; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "mount | grep -E '\s/var/tmp\s' | grep -v noexec" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit the /etc/fstab file and add noexec to the fourth field (mounting options) for the /var/tmp partition. Run the following command to remount /var/tmp" 2
		console "mount -o remount,noexec /var/tmp" 2
	else
		console "/var/tmp is not a seperate partition, therefore no checks or remediations exist" 1
	fi
	echo

	echo -e "${GREEN}1.1.11 Ensure separate partition exists for /var/log (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.12 Ensure separate partition exists for /var/log/audit (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.13 Ensure separate partition exists for /home (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.14 Ensure nodev option set on /home partition (Scored)${RESET}"
	if df | grep -q /home; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "mount | grep -E '\s/home\s' | grep -v nodev" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit the /etc/fstab file and add nodev to the fourth field (mounting options) for the /home partition. Run the following command to remount /home" 2
		console "mount -o remount,nodev /home" 2
	else
		console "/home is not a seperate partition, therefore no checks or remediations exist" 1
	fi
	echo

	echo -e "${GREEN}1.1.15 Ensure nodev option set on /dev/shm partition (Scored)${RESET}"
	if df | grep -q /dev/shm; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "mount | grep -E '\s/dev/shm\s' | grep -v nodev" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit the /etc/fstab file and add nodev to the fourth field (mounting options) for the /dev/shm partition. Run the following command to remount /dev/shm" 2
		console "mount -o remount,nodev /dev/shm" 2
	else
		console "/dev/shm is not a seperate partition, therefore no checks or remediations exist" 1
	fi
	echo

	echo -e "${GREEN}1.1.16 Ensure nosuid option set on /dev/shm partition (Scored)${RESET}"
	if df | grep -q /dev/shm; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "mount | grep -E '\s/dev/shm\s' | grep -v nosuid" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit the /etc/fstab file and add nosuid to the fourth field (mounting options) for the /dev/shm partition. Run the following command to remount /dev/shm" 2
		console "mount -o remount,nosuid /dev/shm" 2
	else
		console "/dev/shm is not a seperate partition, therefore no checks or remediations exist" 1
	fi
	echo

	echo -e "${GREEN}1.1.17 Ensure noexec option set on /dev/shm partition (Scored)${RESET}"
	if df | grep -q /dev/shm; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "mount | grep -E '\s/dev/shm\s' | grep -v noexec" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit the /etc/fstab file and add noexec to the fourth field (mounting options) for the /dev/shm partition. Run the following command to remount /dev/shm" 2
		console "mount -o remount,noexec /dev/shm" 2
	else
		console "/dev/shm is not a seperate partition, therefore no checks or remediations exist" 1
	fi
	echo

	echo -e "${GREEN}1.1.18 Ensure nodev option set on removable media partitions (Not Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.19 Ensure nosuid option set on removable media partitions (Not Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.20 Ensure noexec option set on removable media partitions (Not Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.1.21 Ensure sticky bit is set on all world-writable directories (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | xargs -I '{}' chmod a+t '{}'" 2 exe
	echo

	echo -e "${GREEN}1.1.22 Disable Automounting (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "systemctl is-enabled autofs" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable autofs" 2 exe
	echo

	echo -e "${GREEN}1.1.23 Disable USB Storage (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "modprobe -n -v usb-storage" 2 exe
	console "lsmod | grep usb-storage" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo \"install usb-storage /bin/true\" >| /etc/modprobe.d/usb-storage.conf" 2 exe
	console "rmmod usb-storage 2>/dev/null" 2 exe
	echo

	echo -e "${GREEN}1.2.1 Ensure GPG keys are configured (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Update your package manager GPG keys in accordance with site policy" 2
	echo

	echo -e "${GREEN}1.2.2 Ensure gpgcheck is globally activated (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep ^gpgcheck /etc/yum.conf" 2 exe
	console "grep ^gpgcheck /etc/yum.repos.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "for r in \$(grep ^gpgcheck /etc/yum.repos.d/* /etc/yum.conf); do sed -i 's/^gpgcheck=0/gpgcheck=1/g' \$(awk -F':' '{print \$1}' <<< \$r) | grep ^gpgcheck; done" 2 exe
	echo

	echo -e "${GREEN}1.2.3 Ensure package manager repositories are configured (Not Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.3.1 Ensure sudo is installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "rpm -q sudo" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "hash sudo || dnf install -y sudo" 2 exe
	echo

	echo -e "${GREEN}1.3.2 Ensure sudo commands use pty (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -Ei '^\s*Defaults\s+(\[^#]+,\s*)?use_pty' /etc/sudoers /etc/sudoers.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit the file /etc/sudoers or the files in /etc/sudoers.d/:" 2
	console "visudo -f /etc/sudoers" 2
	console "Defaults use_pty" 2
	console "for f in /etc/sudoers.d/*; do visudo -f \$f; done" 2
	console "Defaults use_pty" 2
	echo

	echo -e "${GREEN}1.3.3 Ensure sudo log file exists (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -Ei '^\s*Defaults\s+([^#]+,\s*)?logfile=' /etc/sudoers /etc/sudoers.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit the file /etc/sudoers or the files in /etc/sudoers.d/:" 2
	console "visudo -f /etc/sudoers" 2
	console "Defaults logfile=\"/var/log/sudo.log\"" 2
	console "for f in /etc/sudoers.d/*; do visudo -f \$f; done" 2
	console "Defaults logfile=\"/var/log/sudo.log\"" 2
	echo

	echo -e "${GREEN}1.4.1 Ensure AIDE is installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "rpm -q aide" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "hash aide || dnf install -y aide" 2 exe
	console "aide --init" 2 exe
	console "yes | mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz" 2 exe
	console "hash prelink && prelink -ua" 2 exe
	echo

	echo -e "${GREEN}1.4.2 Ensure filesystem integrity is regularly checked (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "systemctl is-enabled aidecheck.service" 2 exe
	console "systemctl status aidecheck.service" 2 exe
	console "systemctl is-enabled aidecheck.timer" 2 exe
	console "systemctl status aidecheck.timer" 2 exe
	console "crontab -u root -l | grep aide" 2 exe
	console "grep -r aide /etc/cron.* /etc/crontab" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "crontab -l > /root/crontab.bak" 2 exe
	console "echo -e '$(crontab -l | grep -Ev '^#|^$')\\n0 5 * * * /usr/sbin/aide --check' | crontab -u root -" 2 exe
	echo

	echo -e "${GREEN}1.5.1 Ensure permissions on bootloader config are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /boot/grub2/grub.cfg | grep Uid" 2 exe
	console "stat /boot/grub2/grubenv | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /boot/grub2/grub.cfg" 2 exe
	console "chmod og-rwx /boot/grub2/grub.cfg" 2 exe
	console "chown root:root /boot/grub2/grubenv" 2 exe
	console "chmod og-rwx /boot/grub2/grubenv" 2 exe
	console "grub2-mkconfig -o /boot/grub2/grub.cfg" 2 exe
	echo

	echo -e "${GREEN}1.5.2 Ensure bootloader password is set (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^\s*GRUB2_PASSWORD' /boot/grub2/user.cfg" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Create an encrypted password with grub2-setpassword:" 2
	console "grub2-setpassword" 2
	console "Run the following command to update the grub2 configuration:" 2
	console "grub2-mkconfig -o /boot/grub2/grub.cfg" 2
	echo

	echo -e "${GREEN}1.5.3 Ensure authentication required for single user mode (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep /systemd-sulogin-shell /usr/lib/systemd/system/rescue.service" 2 exe
	console "grep /systemd-sulogin-shell /usr/lib/systemd/system/emergency.service" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i 's/ExecStart=-.*$/ExecStart=-\/usr\/lib\/systemd\/systemd-sulogin-shell rescue/g' /usr/lib/systemd/system/rescue.service" 2 exe
	console "sed -i 's/ExecStart=-.*$/ExecStart=-\/usr\/lib\/systemd\/systemd-sulogin-shell emergency/g' /usr/lib/systemd/system/emergency.service" 2 exe
	console "systemctl daemon-reload" 2 exe
	echo

	echo -e "${GREEN}1.6.1 Ensure core dumps are restricted (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -E '^\s*\*\s+hard\s+core' /etc/security/limits.conf /etc/security/limits.d/*" 2 exe
	console "sysctl fs.suid_dumpable" 2 exe
	console "grep 'fs\.suid_dumpable' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "systemctl is-enabled coredump.service" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "echo '* hard core 0' >> /etc/security/limits.conf" 2 exe
	console "echo 'fs.suid_dumpable = 0' >| /etc/sysctl.d/cis_1_6_1_restricted_core_dumps.conf" 2 exe
	console "sysctl -w fs.suid_dumpable=0" 2 exe
	console "If systemd-coredump is installed:" 2
	console "vim /etc/systemd/coredump.conf" 2
	console "Storage=none" 2
	console "ProcessSizeMax=0" 2
	console "systemctl daemon-reload" 2 exe
	echo

	echo -e "${GREEN}1.6.2 Ensure address space layout randomization (ASLR) is enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl kernel.randomize_va_space" 2 exe
	console "grep 'kernel\.randomize_va_space' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'kernel.randomize_va_space = 2' >| /etc/sysctl.d/cis_1_6_2_aslr.conf" 2 exe
	console "sysctl -w kernel.randomize_va_space=2" 2 exe
	echo

	echo -e "${GREEN}1.7.1.1 Ensure SELinux is installed (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.7.1.2 Ensure SELinux is not disabled in bootloader configuration (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.7.1.3 Ensure SELinux policy is configured (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.7.1.4 Ensure the SELinux state is enforcing (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.7.1.5 Ensure no unconfined services exist (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.7.1.6 Ensure SETroubleshoot is not installed (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.7.1.7 Ensure the MCS Translation Service (mcstrans) is not installed (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}1.8.1.1 Ensure message of the day is configured properly (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "cat /etc/motd" 2 exe
	console "grep -E -i '(\\\v|\\\r|\\\m|\\\s|$(grep ^ID= /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))' /etc/motd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "rm -f /etc/motd" 2 exe
	echo

	echo -e "${GREEN}1.8.1.2 Ensure local login warning banner is configured properly (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "cat /etc/issue" 2 exe
	console "grep -E -i '(\\\v|\\\r|\\\m|\\\s|$(grep ^ID= /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))' /etc/issue" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'Authorized uses only. All activity may be monitored and reported.' > /etc/issue" 2 exe
	echo

	echo -e "${GREEN}1.8.1.3 Ensure remote login warning banner is configured properly (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/motd | grep Uid 2>/dev/null" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/motd 2>/dev/null" 2 exe
	console "chmod u-x,go-wx /etc/motd 2>/dev/null" 2 exe
	echo

	echo -e "${GREEN}1.8.1.5 Ensure permissions on /etc/issue are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/issue | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/issue" 2 exe
	console "chmod u-x,go-wx /etc/issue" 2 exe
	echo

	echo -e "${GREEN}1.8.1.6 Ensure permissions on /etc/issue.net are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/issue.net | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/issue.net" 2 exe
	console "chmod u-x,go-wx /etc/issue.net"
	echo

	echo -e "${GREEN}1.8.2 Ensure GDM login banner is configured (Scored)${RESET}"
	if grep -q '/usr/s\?bin' /etc/systemd/system/display-manager.service 2>/dev/null; then
		console "${BOLD}[AUDIT]${RESET}" 1
		console "cat /etc/gdm3/greeter.dconf-defaults" 2 exe
		console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
		console "Edit or create the file /etc/gdm3/greeter.dconf-defaults and add the following:" 2
		console "[org/gnome/login-screen]" 2
		console "banner-message-enable=true" 2
		console "banner-message-text='Authorized uses only. All activity may be monitored and reported.'" 2
	else
		console "Skipped" 1
	fi
	echo

	echo -e "${GREEN}1.9 Ensure updates, patches, and additional security software are installed (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "dnf check-update" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf update -y" 2 exe
	echo

	echo -e "${GREEN}1.10 Ensure system-wide crypto policy is not legacy (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify that the system-wide crypto policy is not LEGACY" 2
	console "grep -E -i '^\s*LEGACY\s*(\s+#.*)?$' /etc/crypto-policies/config" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "update-crypto-policies --set DEFAULT" 2 exe
	console "update-crypto-policies" 2 exe
	console "To switch the system to FIPS mode, run the following command:" 2
	console "fips-mode-setup --enable" 2
	echo

	echo -e "${GREEN}1.11 Ensure system-wide crypto policy is FUTURE or FIPS (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo -e "${GREEN}2.1.1 Ensure xinetd is not installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify xinetd is not installed:" 2
	console "rpm -q xinetd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf remove -y xinetd 2>/dev/null" 2 exe
	echo

	echo -e "${GREEN}2.2.1.1 Ensure time synchronization is in use (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "On physical systems or virtual systems where host based time synchronization is not available verify that chrony is installed. Run the following command to verify that chrony is installed:" 2
	console "rpm -q chrony" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf install -y chrony" 2 exe
	echo

	echo -e "${GREEN}2.2.1.2 Ensure chrony is configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command and verify remote server is configured properly:" 2
	console "grep -E '^(server|pool)' /etc/chrony.conf" 2 exe
	console "Run the following command and verify the first field for the chronyd process is chrony:" 2
	console "ps -ef | grep chronyd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "Add or edit server or pool lines to /etc/chrony.conf as appropriate:" 2
	console "vim /etc/chrony.conf" 2
	console "server <remote-server>" 2
	console "systemctl restart chronyd" 2
	echo

	echo -e "${GREEN}2.2.2 Ensure X Window System is not installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "rpm -qa xorg-x11*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf remove -y xorg-x11*" 2 exe
	echo

	echo -e "${GREEN}2.2.3 Ensure rsync service is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify rsyncd is not enabled:" 2
	console "systemctl is-enabled rsyncd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable rsyncd" 2 exe
	echo

	echo -e "${GREEN}2.2.4 Ensure Avahi Server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify the avahi-daemon is not enabled:" 2
	console "systemctl is-enabled avahi-daemon" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable avahi-daemon" 2 exe
	echo

	echo -e "${GREEN}2.2.5 Ensure SNMP Server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify snmpd is not enabled:" 2
	console "systemctl is-enabled snmpd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable snmpd" 2 exe
	echo

	echo -e "${GREEN}2.2.6 Ensure HTTP Proxy Server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify squid is not enabled:" 2
	console "systemctl is-enabled squid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable squid" 2 exe
	echo

	echo -e "${GREEN}2.2.7 Ensure Samba is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify smb is not enabled:" 2
	console "systemctl is-enabled smb" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable smb" 2 exe
	echo

	echo -e "${GREEN}2.2.8 Ensure IMAP and POP3 server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify dovecot is not enabled:" 2
	console "systemctl is-enabled dovecot" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable dovecot" 2 exe
	echo

	echo -e "${GREEN}2.2.9 Ensure HTTP server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify httpd is not enabled:" 2
	console "systemctl is-enabled httpd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable httpd" 2 exe
	echo

	echo -e "${GREEN}2.2.10 Ensure FTP Server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify vsftpd is not enabled:" 2
	console "systemctl is-enabled vsftpd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable vsftpd" 2 exe
	echo

	echo -e "${GREEN}2.2.11 Ensure DNS Server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify named is not enabled:" 2
	console "systemctl is-enabled named" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable named" 2 exe
	echo

	echo -e "${GREEN}2.2.12 Ensure NFS is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify nfs is not enabled:" 2
	console "systemctl is-enabled nfs" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable nfs" 2 exe
	echo

	echo -e "${GREEN}2.2.13 Ensure RPC is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify rpcbind is not enabled:" 2
	console "systemctl is-enabled rpcbind" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable rpcbind" 2 exe
	echo

	echo -e "${GREEN}2.2.14 Ensure LDAP server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following commands to verify slapd is not enabled:" 2
	console "systemctl is-enabled slapd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable slapd" 2 exe
	echo

	echo -e "${GREEN}2.2.15 Ensure DHCP Server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify dhcpd is not enabled:" 2
	console "systemctl is-enabled dhcpd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable dhcpd" 2
	echo

	echo -e "${GREEN}2.2.16 Ensure CUPS is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify cups is not enabled:" 2
	console "systemctl is-enabled cups" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable cups" 2 exe
	echo

	echo -e "${GREEN}2.2.17 Ensure NIS Server is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify ypserv is not enabled:" 2
	console "systemctl is-enabled ypserv" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now disable ypserv" 2 exe
	echo

	echo -e "${GREEN}2.2.18 Ensure mail transfer agent is configured for local-only mode (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command to verify that the MTA is not listening on any non-loopback address ( 127.0.0.1 or ::1 ). Nothing should be returned" 2
	console "ss -lntu | grep -E ':25\s' | grep -E -v '\s(127.0.0.1|::1):25\s'" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit /etc/postfix/main.cf and add the following line to the RECEIVING MAIL section. If the line already exists, change it to look like the line below:" 2
	console "inet_interfaces = loopback-only" 2
	console "systemctl restart postfix" 2
	echo

	echo "${GREEN}2.3.1 Ensure NIS Client is not installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Verify ypbind is not installed. Run the following command:" 2
	console "rpm -q ypbind" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf remove -y ypbind" 2 exe
	echo

	echo "${GREEN}2.3.2 Ensure telnet client is not installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Verify telnet is not installed. Run the following command:" 2
	console "rpm -q telnet" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf remove -y telnet" 2 exe
	echo

	echo "${GREEN}2.3.3 Ensure LDAP client is not installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Verify openldap-clients is not installed. Run the following command:" 2
	console "rpm -q openldap-clients" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf remove -y openldap-clients" 2 exe
	echo

	echo "${GREEN}3.1.1 Ensure IP forwarding is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.ip_forward" 2 exe
	console "grep -E -s '^\s*net\.ipv4\.ip_forward\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf" 2 exe
	console "sysctl net.ipv6.conf.all.forwarding" 2 exe
	console "grep -E -s '^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "grep -Els '^\s*net\.ipv4\.ip_forward\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri 's/^\s*(net\.ipv4\.ip_forward\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/' \$filename; done; sysctl -w net.ipv4.ip_forward=0; sysctl -w net.ipv4.route.flush=1" 2 exe
	console "grep -Els '^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri 's/^\s*(net\.ipv6\.conf\.all\.forwarding\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/' \$filename; done; sysctl -w net.ipv6.conf.all.forwarding=0; sysctl -w net.ipv6.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.1.2 Ensure packet redirect sending is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.conf.all.send_redirects" 2 exe
	console "sysctl net.ipv4.conf.default.send_redirects" 2 exe
	console "grep 'net\.ipv4\.conf\.all\.send_redirects' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv4\.conf\.default\.send_redirects' /etc/sysctl.conf /etc/sysctl.d/*"
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'net.ipv4.conf.all.send_redirects = 0' >| /etc/sysctl.d/cis_3_1_2_packet_redirect_signal.conf" 2 exe
	console "echo 'net.ipv4.conf.default.send_redirects = 0' >> /etc/sysctl.d/cis_3_1_2_packet_redirect_signal.conf" 2 exe
	console "sysctl -w net.ipv4.conf.all.send_redirects=0" 2 exe
	console "sysctl -w net.ipv4.conf.default.send_redirects=0" 2 exe
	console "sysctl -w net.ipv4.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.1 Ensure source routed packets are not accepted (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.conf.all.accept_source_route" 2 exe
	console "sysctl net.ipv4.conf.default.accept_source_route" 2 exe
	console "grep 'net\.ipv4\.conf\.all\.accept_source_route' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv4\.conf\.default\.accept_source_route' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "sysctl net.ipv6.conf.all.accept_source_route" 2 exe
	console "sysctl net.ipv6.conf.default.accept_source_route" 2 exe
	console "grep 'net\.ipv6\.conf\.all\.accept_source_route' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv6\.conf\.default\.accept_source_route' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'net.ipv4.conf.all.accept_source_route = 0' >| /etc/sysctl.d/cis_3_2_1_source_routed_packets.conf" 2 exe
	console "echo 'net.ipv4.conf.default.accept_source_route = 0' >> /etc/sysctl.d/cis_3_2_1_source_routed_packets.conf" 2 exe
	console "echo 'net.ipv6.conf.all.accept_source_route = 0' >> /etc/sysctl.d/cis_3_2_1_source_routed_packets.conf" 2 exe
	console "echo 'net.ipv6.conf.default.accept_source_route = 0' >> /etc/sysctl.d/cis_3_2_1_source_routed_packets.conf" 2 exe
	console "sysctl -w net.ipv4.conf.all.accept_source_route=0" 2 exe
	console "sysctl -w net.ipv4.conf.default.accept_source_route=0" 2 exe
	console "sysctl -w net.ipv6.conf.all.accept_source_route=0" 2 exe
	console "sysctl -w net.ipv6.conf.default.accept_source_route=0" 2 exe
	console "sysctl -w net.ipv4.route.flush=1" 2 exe
	console "sysctl -w net.ipv6.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.2 Ensure ICMP redirects are not accepted (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.conf.all.accept_redirects" 2 exe
	console "sysctl net.ipv4.conf.default.accept_redirects" 2 exe
	console "grep 'net\.ipv4\.conf\.all\.accept_redirects' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv4\.conf\.default\.accept_redirects' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "sysctl net.ipv6.conf.all.accept_redirects" 2 exe
	console "sysctl net.ipv6.conf.default.accept_redirects" 2 exe
	console "grep 'net\.ipv6\.conf\.all\.accept_redirects' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv6\.conf\.default\.accept_redirects' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'net.ipv4.conf.all.accept_redirects = 0' >| /etc/sysctl.d/cis_3_2_2_icmp.conf" 2 exe
	console "echo 'net.ipv4.conf.default.accept_redirects = 0' >> /etc/sysctl.d/cis_3_2_2_icmp.conf" 2 exe
	console "echo 'net.ipv6.conf.all.accept_redirects = 0' >> /etc/sysctl.d/cis_3_2_2_icmp.conf" 2 exe
	console "echo 'net.ipv6.conf.default.accept_redirects = 0' >> /etc/sysctl.d/cis_3_2_2_icmp.conf" 2 exe
	console "sysctl -w net.ipv4.conf.all.accept_redirects=0" 2 exe
	console "sysctl -w net.ipv4.conf.default.accept_redirects=0" 2 exe
	console "sysctl -w net.ipv6.conf.all.accept_redirects=0" 2 exe
	console "sysctl -w net.ipv6.conf.default.accept_redirects=0" 2 exe
	console "sysctl -w net.ipv4.route.flush=1" 2 exe
	console "sysctl -w net.ipv6.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.3 Ensure secure ICMP redirects are not accepted (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.conf.all.secure_redirects" 2 exe
	console "sysctl net.ipv4.conf.default.secure_redirects" 2 exe
	console "grep 'net\.ipv4\.conf\.all\.secure_redirects' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv4\.conf\.default\.secure_redirects' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'net.ipv4.conf.all.secure_redirects = 0' >| /etc/sysctl.d/cis_3_2_3_secure_icmp.conf" 2 exe
	console "echo 'net.ipv4.conf.default.secure_redirects = 0' >> /etc/sysctl.d/cis_3_2_3_secure_icmp.conf" 2 exe
	console "sysctl -w net.ipv4.conf.all.secure_redirects=0" 2 exe
	console "sysctl -w net.ipv4.conf.default.secure_redirects=0" 2 exe
	console "sysctl -w net.ipv4.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.4 Ensure suspicious packets are logged (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.conf.all.log_martians" 2 exe
	console "sysctl net.ipv4.conf.default.log_martians" 2 exe
	console "grep 'net\.ipv4\.conf\.all\.log_martians' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv4\.conf\.default\.log_martians' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'net.ipv4.conf.all.log_martians = 1' >| /etc/sysctl.d/cis_3_2_3_martians.conf" 2 exe
	console "echo 'net.ipv4.conf.default.log_martians = 1' >> /etc/sysctl.d/cis_3_2_3_martians.conf" 2 exe
	console "sysctl -w net.ipv4.conf.all.log_martians=1" 2 exe
	console "sysctl -w net.ipv4.conf.default.log_martians=1" 2 exe
	console "sysctl -w net.ipv4.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.5 Ensure broadcast ICMP requests are ignored (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.icmp_echo_ignore_broadcasts" 2 exe
	console "grep -E -s '^\s*net\.ipv4\.icmp_echo_ignore_broadcasts\s*=\s*0' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "grep -Els '^\s*net\.ipv4\.icmp_echo_ignore_broadcasts\s*=\s*0' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri 's/^\s*(net\.ipv4\.icmp_echo_ignore_broadcasts\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/' \$filename; done; sysctl -w net.icmp_echo_ignore_broadcasts=1; sysctl -w net.ipv4.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.6 Ensure bogus ICMP responses are ignored (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.icmp_ignore_bogus_error_responses" 2 exe
	console "grep -E -s '^\s*net\.ipv4\.icmp_ignore_bogus_error_responses\s*=\s*0' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "grep -Els '^\s*net\.ipv4\.icmp_ignore_bogus_error_responses\s*=\s*0' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri 's/^\s*(net\.ipv4\.icmp_ignore_bogus_error_responses\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/' \$filename; done; sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1; sysctl -w net.ipv4.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.7 Ensure Reverse Path Filtering is enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.conf.all.rp_filter" 2 exe
	console "sysctl net.ipv4.conf.default.rp_filter" 2 exe
	console "grep -E -s '^\s*net\.ipv4\.conf\.all\.rp_filter\s*=\s*0' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf" 2 exe
	console "grep -E -s '^\s*net\.ipv4\.conf\.default\.rp_filter\s*=\s*1' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "grep -Els '^\s*net\.ipv4\.conf\.all\.rp_filter\s*=\s*0' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri 's/^\s*(net\.ipv4\.net.ipv4.conf\.all\.rp_filter\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/' \$filename; done; sysctl -w net.ipv4.conf.all.rp_filter=1; sysctl -w net.ipv4.route.flush=1" 2 exe
	console "echo 'net.ipv4.conf.default.rp_filter=1' >| /etc/sysctl.d/cis_3_2_7_reverse_path_filtering.conf" 2 exe
	console "sysctl -w net.ipv4.conf.default.rp_filter=1" 2 exe
	console "sysctl -w net.ipv4.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.8 Ensure TCP SYN Cookies is enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv4.tcp_syncookies" 2 exe
	console "grep -E -r '^\s*net\.ipv4\.tcp_syncookies\s*=\s*[02]' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "grep -Els '^\s*net\.ipv4\.tcp_syncookies\s*=\s*[02]*' /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | while read filename; do sed -ri 's/^\s*(net\.ipv4\.tcp_syncookies\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/' \$filename; done; sysctl -w net.ipv4.tcp_syncookies=1; sysctl -w net.ipv4.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.2.9 Ensure IPv6 router advertisements are not accepted (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sysctl net.ipv6.conf.all.accept_ra" 2 exe
	console "grep 'net\.ipv6\.conf\.all\.accept_ra' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "grep 'net\.ipv6\.conf\.default\.accept_ra' /etc/sysctl.conf /etc/sysctl.d/*" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "echo 'net.ipv6.conf.all.accept_ra = 0' >| /etc/sysctl.d/cis_3_2_9_ipv6_router_advertisements.conf" 2 exe
	console "echo 'net.ipv6.conf.default.accept_ra = 0' >> /etc/sysctl.d/cis_3_2_9_ipv6_router_advertisements.conf" 2 exe
	console "sysctl -w net.ipv6.conf.all.accept_ra=0" 2 exe
	console "sysctl -w net.ipv6.conf.default.accept_ra=0" 2 exe
	console "sysctl -w net.ipv6.route.flush=1" 2 exe
	echo

	echo "${GREEN}3.3.1 Ensure DCCP is disabled (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}3.3.2 Ensure SCTP is disabled (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}3.3.3 Ensure RDS is disabled (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}3.3.4 Ensure TIPC is disabled (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}3.4.1.1 Ensure a Firewall package is installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "rpm -q firewalld nftables iptables" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf install -y firewalld nftables iptables" 2 exe
	echo

	echo "${GREEN}3.4.2.1 Ensure firewalld service is enabled and running (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "systemctl is-enabled firewalld" 2 exe
	console "firewall-cmd --state" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now enable firewalld" 2 exe
	echo

	echo "${GREEN}3.4.2.2 Ensure nftables is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "systemctl is-enabled nftables" 2 exe
	console "systemctl status nftables" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now mask nftables" 2 exe
	echo

	echo "${GREEN}3.4.2.3 Ensure default zone is set (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "firewall-cmd --get-default-zone" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "firewall-cmd --set-default-zone=public" 2 exe
	echo

	echo "${GREEN}3.4.2.4 Ensure network interfaces are assigned to appropriate zone (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "nmcli -t connection show | awk -F: '{if(\$4){print \$4}}' | while read INT; do firewall-cmd --get-active-zones | grep -B1 \$INT; done" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "firewall-cmd --zone=public --change-interface=eth0" 2
	echo

	echo "${GREEN}3.4.2.5 Ensure unnecessary services and ports are not accepted (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "firewall-cmd --get-active-zones | awk '!/:/ {print \$1}' | while read ZN; do firewall-cmd --list-all --zone=\$ZN; done" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "firewall-cmd --remove-service=<service>" 2
	console "firewall-cmd --remove-port=<port-number>/<port-type>" 2
	console "firewall-cmd --runtime-to-permanent" 2
	echo

	echo "${GREEN}3.4.2.6 Ensure iptables is not enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "systemctl status iptables 2>&1" 2 exe
	console "systemctl is-enabled iptables 2>&1" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now mask iptables" 2 exe
	echo

	echo "${GREEN}3.4.3 Configure nftables${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}3.4.4 Configure iptables${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}3.5 Ensure wireless interfaces are disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "nmcli radio all" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "nmcli radio all off" 2 exe
	echo

	echo "${GREEN}3.6 Disable IPv6 (Not Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1 Configure System Accounting (auditd)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "awk '/^\s*UID_MIN/{print \$2}' /etc/login.defs" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "If your systems' UID_MIN is not 1000, replace audit>=1000 with audit>=<UID_MIN for your system> in the Audit and Remediation procedures." 2
	console "vim /etc/audit/rules.d/audit.rules" 2
	console "service auditd reload" 2
	echo

	echo "${GREEN}4.1.1.1 Ensure auditd is installed (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.1.2 Ensure auditd service is enabled (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.1.3 Ensure auditing for processes that start prior to auditd is enabled (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.1.4 Ensure audit_backlog_limit is sufficient (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.2.1 Ensure audit log storage size is configured (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.2.2 Ensure audit logs are not automatically deleted (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.2.3 Ensure system is disabled when audit logs are full (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.3 Ensure changes to system administration scope (sudoers) is collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.4 Ensure login and logout events are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.5 Ensure session initiation information is collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.6 Ensure events that modify date and time information are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.7 Ensure events that modify the system's Mandatory Access Controls are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.8 Ensure events that modify the system's network environment are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.9 Ensure discretionary access control permission modification events are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.10 Ensure unsuccessful unauthorized file access attempts are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.11 Ensure events that modify user/group information are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.12 Ensure successful file system mounts are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.13 Ensure use of privileged commands is collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.14 Ensure file deletion events by users are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.15 Ensure kernel module loading and unloading is collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.16 Ensure system administrator actions (sudolog) are collected (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.1.17 Ensure the audit configuration is immutable (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}4.2.1.1 Ensure rsyslog is installed (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "rpm -q rsyslog" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "dnf install -y rsyslog" 2 exe
	echo

	echo "${GREEN}4.2.1.2 Ensure rsyslog Service is enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "systemctl is-enabled rsyslog" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now enable rsyslog" 2 exe
	echo

	echo "${GREEN}4.2.1.3 Ensure rsyslog default file permissions configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Run the following command and verify that \$FileCreateMode is 0640 or more restrictive:" 2
	console "grep ^\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit the /etc/rsyslog.conf and /etc/rsyslog.d/*.conf files and set \$FileCreateMode to 0640 or more restrictive:" 2
	console "\$FileCreateMode 0640" 2
	echo

	echo "${GREEN}4.2.1.4 Ensure logging is configured (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Review the contents of the /etc/rsyslog.conf and /etc/rsyslog.d/*.conf files to ensure appropriate logging is set. In addition, run the following command and verify that the log files are logging information:" 2
	console "ls -l /var/log/" 2 exe
 	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "*.emerg :omusrmsg:*" 2
	console "auth,authpriv.* /var/log/secure" 2
	console "mail.* -/var/log/mail" 2
	console "mail.info -/var/log/mail.info" 2
	console "mail.warning -/var/log/mail.warn" 2
	console "mail.err /var/log/mail.err" 2
	console "news.crit -/var/log/news/news.crit" 2
	console "news.err -/var/log/news/news.err" 2
	console "news.notice -/var/log/news/news.notice" 2
	console "*.=warning;*.=err -/var/log/warn" 2
	console "*.crit /var/log/warn" 2
	console "*.*;mail.none;news.none -/var/log/messages" 2
	console "local0,local1.* -/var/log/localmessages" 2
	console "local2,local3.* -/var/log/localmessages" 2
	console "local4,local5.* -/var/log/localmessages" 2
	console "local6,local7.* -/var/log/localmessages" 2
	console "systemctl restart rsyslog" 2
	echo

	echo "${GREEN}4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^*.*[^I][^I]*@' /etc/rsyslog.conf /etc/rsyslog.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit the /etc/rsyslog.conf and /etc/rsyslog.d/*.conf files and add the following line (where loghost.example.com is the name of your central log host)." 2
	console "*.* @@loghost.example.com" 2
	console "systemctl restart rsyslog" 2
	echo

	echo "${GREEN}4.2.1.6 Ensure remote rsyslog messages are only accepted on designated log hosts. (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '\$ModLoad imtcp' /etc/rsyslog.conf /etc/rsyslog.d/*.conf" 2 exe
	console "grep '\$InputTCPServerRun' /etc/rsyslog.conf /etc/rsyslog.d/*.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "For hosts that are designated as log hosts, UNCOMMENT the following in the /etc/rsyslog.conf file" 2
	console "vim /etc/rsyslog.conf" 2
	console "\$ModLoad imtcp" 2
	console "\$InputTCPServerRun 514" 2
	console "For hosts that are NOT designated as log hosts, COMMENT the following in the /etc/rsyslog.conf file" 2
	console "# \$ModLoad imtcp" 2
	console "# \$InputTCPServerRun 514" 2
	console "systemctl restart rsyslog" 2
	echo

	echo "${GREEN}4.2.2.1 Ensure journald is configured to send logs to rsyslog (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -e ^\s*ForwardToSyslog /etc/systemd/journald.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^#ForwardToSyslog=.*/ForwardToSyslog=yes/g' -e 's/^ForwardToSyslog=.*/ForwardToSyslog=yes/g' /etc/systemd/journald.conf" 2 exe
	echo

	echo "${GREEN}4.2.2.2 Ensure journald is configured to compress large log files (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -e ^\s*Compress /etc/systemd/journald.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^#Compress=.*/Compress=yes/g' -e 's/^Compress=.*/Compress=yes/g' /etc/systemd/journald.conf" 2 exe
	echo

	echo "${GREEN}4.2.2.3 Ensure journald is configured to write logfiles to persistent disk (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -e ^\s*Storage /etc/systemd/journald.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^#Storage=.*/Storage=persistent/g' -e 's/^Storage=.*/Storage=persistent/g' /etc/systemd/journald.conf" 2 exe
	echo

	echo "${GREEN}4.2.3 Ensure permissions on all logfiles are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "find /var/log -type f -perm /037 -ls -o -type d -perm /026 -ls" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "find /var/log -type f -exec chmod g-wx,o-rwx \"{}\" + -o -type d -exec chmod g-w,o-rwx \"{}\" +" 2 exe
	echo

	echo "${GREEN}4.3 Ensure logrotate is configured (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "Review /etc/logrotate.conf and /etc/logrotate.d/* and verify logs are rotated according to site policy." 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit /etc/logrotate.conf and /etc/logrotate.d/* to ensure logs are rotated according to site policy." 2
	console "If no maxage setting is set for logrotate a situation can occur where logrotate is interrupted and fails to delete rotated logfiles. It is recommended to set this to a value greater than the longest any log file should exist on your system to ensure that any such logfile is removed but standard rotation settings are not overridden." 2
	echo

	echo "${GREEN}5.1.1 Ensure cron daemon is enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "systemctl is-enabled crond" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "systemctl --now enable crond" 2 exe
	echo

	echo "${GREEN}5.1.2 Ensure permissions on /etc/crontab are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/crontab | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/crontab" 2 exe
	console "chmod og-rwx /etc/crontab" 2 exe
	echo

	echo "${GREEN}5.1.3 Ensure permissions on /etc/cron.hourly are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/cron.hourly | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/cron.hourly" 2 exe
	console "chmod og-rwx /etc/cron.hourly" 2 exe
	echo

	echo "${GREEN}5.1.4 Ensure permissions on /etc/cron.daily are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/cron.daily | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/cron.daily" 2 exe
	console "chmod og-rwx /etc/cron.daily" 2 exe
	echo

	echo "${GREEN}5.1.5 Ensure permissions on /etc/cron.weekly are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/cron.weekly | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/cron.weekly" 2 exe
	console "chmod og-rwx /etc/cron.weekly" 2 exe
	echo

	echo "${GREEN}5.1.6 Ensure permissions on /etc/cron.monthly are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/cron.monthly | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/cron.monthly" 2 exe
	console "chmod og-rwx /etc/cron.monthly" 2 exe
	echo

	echo "${GREEN}5.1.7 Ensure permissions on /etc/cron.d are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/cron.d | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/cron.d" 2 exe
	console "chmod og-rwx /etc/cron.d" 2 exe
	echo

	echo "${GREEN}5.1.8 Ensure at/cron is restricted to authorized users (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/cron.deny | grep Uid" 2 exe
	console "stat /etc/at.deny | grep Uid" 2 exe
	console "stat /etc/cron.allow | grep Uid" 2 exe
	console "stat /etc/at.allow | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "rm -f /etc/cron.deny" 2 exe
	console "rm -f /etc/at.deny" 2 exe
	console "touch /etc/cron.allow" 2 exe
	console "touch /etc/at.allow" 2 exe
	console "chmod og-rwx /etc/cron.allow" 2 exe
	console "chmod og-rwx /etc/at.allow" 2 exe
	console "chown root:root /etc/cron.allow" 2 exe
	console "chown root:root /etc/at.allow" 2 exe
	echo

	echo "${GREEN}5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/ssh/sshd_config | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/ssh/sshd_config" 2 exe
	console "chmod og-rwx /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.2 Ensure SSH access is limited (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep -E '^\s*(allow|deny)(users|groups)\s+\S+'" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit the /etc/ssh/sshd_config file to set one or more of the parameter as follows:" 2
	console "AllowUsers <userlist>" 2
	console "AllowGroups <grouplist>" 2
	console "DenyUsers <userlist>" 2
	console "DenyGroups <grouplist>" 2
	echo

	echo "${GREEN}5.2.3 Ensure permissions on SSH private host key files are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec stat {} \;" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chown root:root {} \;" 2 exe
	console "find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chmod 0600 {} \;" 2 exe
	echo

	echo "${GREEN}5.2.4 Ensure permissions on SSH public host key files are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec stat {} \;" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chmod 0644 {} \;" 2 exe
	console "find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chown root:root {} \;" 2 exe
	echo

	echo "${GREEN}5.2.5 Ensure SSH LogLevel is appropriate (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep loglevel" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^LogLevel .*/LogLevel INFO/g' -e 's/^#LogLevel .*/LogLevel INFO/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'LogLevel INFO' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.6 Ensure SSH X11 forwarding is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep x11forwarding" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^X11Forwarding .*/X11Forwarding no/g' -e 's/^#X11Forwarding .*/X11Forwarding no/g' -e 's/^x11Forwarding .*/X11Forwarding no/g' -e 's/^#x11Forwarding .*/X11Forwarding no/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'X11Forwarding no' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.7 Ensure SSH MaxAuthTries is set to 4 or less (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep maxauthtries" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^MaxAuthTries .*/MaxAuthTries 4/g' -e 's/^#MaxAuthTries .*/MaxAuthTries 4/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'MaxAuthTries 4' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.8 Ensure SSH IgnoreRhosts is enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep ignorerhosts" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^IgnoreRhosts .*/IgnoreRhosts yes/g' -e 's/^#IgnoreRhosts .*/IgnoreRhosts yes/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'IgnoreRhosts yes' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.9 Ensure SSH HostbasedAuthentication is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep hostbasedauthentication" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^HostbasedAuthentication .*/HostbasedAuthentication no/g' -e 's/^#HostbasedAuthentication .*/HostbasedAuthentication no/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'HostbasedAuthentication no' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.10 Ensure SSH root login is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep permitrootlogin" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^PermitRootLogin .*/PermitRootLogin no/g' -e 's/^#PermitRootLogin .*/PermitRootLogin no/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'PermitRootLogin no' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.11 Ensure SSH PermitEmptyPasswords is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep permitemptypasswords" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^PermitEmptyPasswords .*/PermitEmptyPasswords no/g' -e 's/^#PermitEmptyPasswords .*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'PermitEmptyPasswords no' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.12 Ensure SSH PermitUserEnvironment is disabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep permituserenvironment" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^PermitUserEnvironment .*/PermitUserEnvironment no/g' -e 's/^#PermitUserEnvironment .*/PermitUserEnvironment no/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'PermitUserEnvironment no' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.13 Ensure SSH Idle Timeout Interval is configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep clientaliveinterval" 2 exe
	console "sshd -T | grep clientalivecountmax" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^ClientAliveInterval .*/ClientAliveInterval 300/g' -e 's/^#ClientAliveInterval .*/ClientAliveInterval 300/g' /etc/ssh/sshd_config" 2 exe
	console "sed -i -e 's/^ClientAliveCountMax .*/ClientAliveCountMax 0/g' -e 's/^#ClientAliveCountMax .*/ClientAliveCountMax 0/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'ClientAliveInterval 300' >> /etc/ssh/sshd_config" 2 exe
	console "echo 'ClientAliveCountMax 0' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.14 Ensure SSH LoginGraceTime is set to one minute or less (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep logingracetime" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^LoginGraceTime .*/LoginGraceTime 60/g' -e 's/^#LoginGraceTime .*/LoginGraceTime 60/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'LoginGraceTime 60' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.15 Ensure SSH warning banner is configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep banner" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^Banner .*/Banner \/etc\/issue.net/g' -e 's/^#Banner .*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'Banner /etc/issue.net' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.16 Ensure SSH PAM is enabled (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep -i usepam" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^UsePAM .*/UsePAM yes/g' -e 's/^#UsePAM .*/UsePAM yes/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'UsePAM yes' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.17 Ensure SSH AllowTcpForwarding is disabled (Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}5.2.18 Ensure SSH MaxStartups is configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep -i maxstartups" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^maxstartups .*/maxstartups 10:30:60/g' -e 's/^#maxstartups .*/maxstartups 10:30:60/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'maxstartups 10:30:60' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.19 Ensure SSH MaxSessions is set to 4 or less (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "sshd -T | grep -i maxsessions" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^MaxSessions .*/MaxSessions 4/g' -e 's/^#MaxSessions .*/MaxSessions 4/g' /etc/ssh/sshd_config" 2 exe
	console "echo 'MaxSessions 4' >> /etc/ssh/sshd_config" 2 exe
	echo

	echo "${GREEN}5.2.20 Ensure system-wide crypto policy is not over-ridden (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^/s*CRYPTO_POLICY=' /etc/sysconfig/sshd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -ri 's/^\s*(CRYPTO_POLICY\s*=.*)$/# \1/' /etc/sysconfig/sshd" 2 exe
	console "systemctl reload sshd" 2 exe
	echo

	echo "${GREEN}5.3.1 Create custom authselect profile (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "authselect current | grep 'Profile ID: custom'" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "authselect create-profile custom-profile -b sssd --symlink-meta" 2 exe
	echo

	echo "${GREEN}5.3.2 Select authselect profile (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "authselect current" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "authselect select custom/custom-profile with-sudo with-faillock without-nullok --force" 2 exe
	echo

	echo "${GREEN}5.3.3 Ensure authselect includes with-faillock (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "authselect current | grep with-faillock" 2 exe
	console "grep with-faillock /etc/authselect/authselect.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "authselect select custom/custom-profile with-sudo with-faillock without-nullok --force" 2 exe
	echo

	echo "${GREEN}5.4.1 Ensure password creation requirements are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep pam_pwquality.so /etc/pam.d/system-auth /etc/pam.d/password-auth" 2 exe
	console "grep ^minlen /etc/security/pwquality.conf" 2 exe
	console "grep ^minclass /etc/security/pwquality.conf" 2 exe
	console "grep -E '^\s*\Scredit\s*=' /etc/security/pwquality.conf" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i -e 's/^minlen .*/minlen = 14/g' -e 's/^#minlen .*/minlen = 14/g' -e 's/^# minlen .*/minlen = 14/g' -e 's/^minclass .*/minclass = 4/g' -e 's/^#minclass .*/minclass = 4/g' -e 's/^# minclass .*/minclass = 4/g' /etc/security/pwquality.conf" 2 exe
	console "CP=\$(authselect current | awk 'NR == 1 {print \$3}' | grep custom/); for FN in system-auth password-auth; do [[ -n \$CP ]] && PTF=/etc/authselect/\$CP/\$FN || PTF=/etc/authselect/\$FN; [[ -z \$(grep -E '^\s*password\s+requisite\s+pam_pwquality.so\s+.*enforce-for-root\s*.*\$' \$PTF) ]] && sed -ri 's/^\s*(password\s+requisite\s+pam_pwquality.so\s+)(.*)\$/\1\2 enforce-forroot/' \$PTF; [[ -n \$(grep -E '^\s*password\s+requisite\s+pam_pwquality.so\s+.*\s+retry=\S+\s*.*\$' \$PTF) ]] && sed -ri '/pwquality/s/retry=\S+/retry=3/' \$PTF || sed -ri 's/^\s*(password\s+requisite\s+pam_pwquality.so\s+)(.*)\$/\1\2 retry=3/' \$PTF; done; authselect apply-changes" 2 exe
	echo

	echo "${GREEN}5.4.2 Ensure lockout for failed password attempts is configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -E '^\s*auth\s+required\s+pam_faillock.so\s+' /etc/pam.d/password-auth /etc/pam.d/system-auth" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "CP=\$(authselect current | awk 'NR == 1 {print \$3}' | grep custom/); for FN in system-auth password-auth; do [[ -n \$CP ]] && PTF=/etc/authselect/\$CP/\$FN || PTF=/etc/authselect/\$FN; [[ -n \$(grep -E '^\s*auth\s+required\s+pam_faillock.so\s+.*deny=\S+\s*.*$' \$PTF) ]] && sed -ri '/pam_faillock.so/s/deny=\S+/deny=5/g' \$PTF || sed -ri 's/^\^\s*(auth\s+required\s+pam_faillock\.so\s+)(.*[^{}])(\{.*\}|)\$/\1\2 deny=5 \3/' \$PTF; [[ -n \$(grep -E '^\s*auth\s+required\s+pam_faillock.so\s+.*unlock_time=\S+\s*.*\$' \$PTF) ]] && sed -ri '/pam_faillock.so/s/unlock_time=\S+/unlock_time=900/g' \$PTF || sed -ri 's/^\s*(auth\s+required\s+pam_faillock\.so\s+)(.*[^{}])(\{.*\}|)\$/\1\2 unlock_time=900 \3/' \$PTF; done; authselect apply-changes" 2 exe 
	echo

	echo "${GREEN}5.4.3 Ensure password reuse is limited (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -E '^\s*password\s+(requisite|sufficient)\s+(pam_pwquality\.so|pam_unix\.so)\s+.*remember=([5-9]|[1-4][0-9])[0-9]*\s*.*\$' /etc/pam.d/system-auth" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "CP=\$(authselect current | awk 'NR == 1 {print \$3}' | grep custom/); [[ -n \$CP ]] && PTF=/etc/authselect/\$CP/system-auth || PTF=/etc/authselect/system-auth; [[ -n \$(grep -E '^\s*password\s+(sufficient\s+pam_unix|requi(red|site)\s+pam_pwhistory).so\s+([^#]+\s+)*remember=\S+\s*.*\$' \$PTF) ]] && sed -ri 's/^\s*(password\s+(requisite|sufficient)\s+(pam_pwquality\.so|pam_unix\.so)\s+)(.*)(remember=\S+\s*)(.*)\$/\1\4 remember=5 \6/' \$PTF || sed -ri 's/^\s*(password\s+(requisite|sufficient)\s+(pam_pwquality\.so|pam_unix\.so)\s+)(.*)\$/\1\4 remember=5/' \$PTF; authselect apply-changes" 2 exe
	echo

	echo "${GREEN}5.4.4 Ensure password hashing algorithm is SHA-512 (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep -E '^\s*password\s+sufficient\s+pam_unix.so\s+.*sha512\s*.*\$' /etc/pam.d/password-auth /etc/pam.d/system-auth" 2 exe
	console "If the password algorithm is NOT SHA-512, change the policy and force users to change their passwords on next successful login:" 2
	console "awk -F: '( \$3<'\"\$(awk '/^\s*UID_MIN/{print \$2}' /etc/login.defs)\"' && \$1 != \"nfsnobody\" ) { print \$1 }' /etc/passwd | xargs -n 1 chage -d 0" 2
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "CP=\$(authselect current | awk 'NR == 1 {print \$3}' | grep custom/); for FN in system-auth password-auth; do [[ -z \$(grep -E '^\s*password\s+sufficient\s+pam_unix.so\s+.*sha512\s*.*\$' \$PTF) ]] && sed -ri 's/^\s*(password\s+sufficient\s+pam_unix.so\s+)(.*)\$/\1\2 sha512/' \$PTF; done; authselect apply-changes" 2 exe
	echo

	echo "${GREEN}5.5.1.1 Ensure password expiration is 365 days or less (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep PASS_MAX_DAYS /etc/login.defs" 2 exe
	console "grep -E '^[^:]+:[^!*]' /etc/shadow | cut -d: -f1,5" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i 's/PASS_MAX_DAYS.*/PASS_MAX_DAYS 365/g' /etc/login.defs" 2 exe
	console "for u in \$(grep -E '^[^:]+:[^!*]' /etc/shadow | cut -d: -f1); do chage --maxdays 365 \$u; done" 2 exe
	echo

	echo "${GREEN}5.5.1.2 Ensure minimum days between password changes is 7 or more (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep PASS_MIN_DAYS /etc/login.defs" 2 exe
	console "grep -E ^[^:]+:[^\!*] /etc/shadow | cut -d: -f1,4" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i 's/PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/g' /etc/login.defs" 2 exe
	console "for u in \$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1); do chage --mindays 7 \$u; done" 2 exe
	echo

	echo "${GREEN}5.5.1.3 Ensure password expiration warning days is 7 or more (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep PASS_WARN_AGE /etc/login.defs" 2 exe
	console "grep -E ^[^:]+:[^\!*] /etc/shadow | cut -d: -f1,6" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i 's/PASS_WARN_AGE.*/PASS_WARN_AGE 7/g' /etc/login.defs" 2 exe
	console "for u in \$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1); do chage --warndays 7 \$u; done" 2 exe
	echo

	echo "${GREEN}5.5.1.4 Ensure inactive password lock is 30 days or less (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "useradd -D | grep INACTIVE" 2 exe
	console "grep -E ^[^:]+:[^\!*] /etc/shadow | cut -d: -f1,7" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "useradd -D -f 30" 2 exe
	console "for u in \$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1); do chage --inactive 30 \$u; done" 2 exe
	echo

	echo "${GREEN}5.5.1.5 Ensure all users last password change date is in the past (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "for usr in \$(cut -d: -f1 /etc/shadow); do [[ \$(chage --list \$usr | grep '^Last password change' | cut -d: -f2) > \$(date) ]] && echo \"\$usr :\$(chage --list \$usr | grep '^Last password change' | cut -d: -f2)\"; done" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Investigate any users with a password change date in the future and correct them. Locking the account, expiring the password, or resetting the password manually may be appropriate" 2
	echo

	echo "${GREEN}5.5.2 Ensure system accounts are secured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 406" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 407" 2
	echo

	echo "${GREEN}5.5.3 Ensure default user shell timeout is 900 seconds or less (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^TMOUT' /etc/bashrc" 2 exe
	console "grep '^TMOUT' /etc/profile /etc/profile.d/*.sh" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Edit the /etc/bashrc, /etc/profile and /etc/profile.d/*.sh files. Add the following line." 2
	console "readonly TMOUT=900 ; export TMOUT" 2
	echo

	echo "${GREEN}5.5.4 Ensure default group for the root account is GID 0 (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^root:' /etc/passwd | cut -f4 -d:" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "usermod -g 0 root" 2 exe
	echo

	echo "${GREEN}5.5.5 Ensure default user umask is 027 or more restrictive (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep umask /etc/bashrc" 2 exe
	console "grep umask /etc/profile /etc/profile.d/*.sh" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "sed -i 's/umask [0-9][0-9][0-9]/umask 027/g' /etc/profile /etc/profile.d/*.sh" 2 exe
	echo

	echo "${GREEN}5.6 Ensure root login is restricted to system console (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "cat /etc/securetty" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Remove entries for any consoles that are not in a physically secure location." 2
	echo

	echo "${GREEN}5.7 Ensure access to the su command is restricted (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep pam_wheel.so /etc/pam.d/su" 2 exe
	console "grep wheel /etc/group" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Add the following line to the /etc/pam.d/su file (or uncomment it):" 2
	console "auth required pam_wheel.so use_uid" 2
	console "Create a comma separated list of users in the wheel statement in the /etc/group file:" 2
	console "For example: wheel:x:10:root,user1,user2,user3" 2
	echo

	echo "${GREEN}6.1.1 Audit system file permissions (Not Scored)${RESET}"
	console "Skipped" 1
	echo

	echo "${GREEN}6.1.2 Ensure permissions on /etc/passwd are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/passwd | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/passwd" 2 exe
	console "chmod 644 /etc/passwd" 2 exe
	echo

	echo "${GREEN}6.1.3 Ensure permissions on /etc/shadow are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/shadow | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/shadow" 2 exe
	#console "chown root:shadow /etc/shadow" 2 exe
	console "chmod o-rwx,g-wx /etc/shadow" 2 exe
	echo

	echo "${GREEN}6.1.4 Ensure permissions on /etc/group are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/group | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/group" 2 exe
	console "chmod 644 /etc/group" 2 exe
	echo

	echo "${GREEN}6.1.5 Ensure permissions on /etc/gshadow are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/gshadow | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/gshadow" 2 exe
	#console "chown root:shadow /etc/gshadow" 2 exe
	console "chmod o-rwx,g-rw /etc/gshadow" 2 exe
	echo

	echo "${GREEN}6.1.6 Ensure permissions on /etc/passwd- are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/passwd- | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/passwd-" 2 exe
	console "chmod u-x,go-rwx /etc/passwd-" 2 exe
	echo

	echo "${GREEN}6.1.7 Ensure permissions on /etc/shadow- are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/shadow- | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/shadow-" 2 exe
	echo

	echo "${GREEN}6.1.8 Ensure permissions on /etc/group- are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/group- | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/group-" 2 exe
	console "chmod u-x,go-wx /etc/group-" 2 exe
	echo

	echo "${GREEN}6.1.9 Ensure permissions on /etc/gshadow- are configured (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "stat /etc/gshadow- | grep Uid" 2 exe
	console "${BOLD}[REMEDIATION]${RESET}" 1
	console "chown root:root /etc/gshadow-" 2 exe
	console "chmod o-rwx,g-rw /etc/gshadow-" 2 exe
	echo

	echo "${GREEN}6.1.10 Ensure no world writable files exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -type f -perm -0002" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Removing write access for the \"other\" category ( chmod o-w <filename> ) is advisable, but always consult relevant vendor documentation to avoid breaking any application dependencies on a given file." 2
	echo

	echo "${GREEN}6.1.11 Ensure no unowned files or directories exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "df --local -P | awk {'if (NR!=1) print \$6'} | xargs -I '{}' find '{}' -xdev -nouser" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Locate files that are owned by users or groups not listed in the system configuration files, and reset the ownership of these files to some active user on the system as appropriate." 2
	echo

	echo "${GREEN}6.1.12 Ensure no ungrouped files or directories exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -nogroup" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Locate files that are owned by users or groups not listed in the system configuration files, and reset the ownership of these files to some active user on the system as appropriate." 2
	echo

	echo "${GREEN}6.1.13 Audit SUID executables (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -type f -perm -4000" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Ensure that no rogue SUID programs have been introduced into the system. Review the files returned by the action in the Audit section and confirm the integrity of these binaries." 2
	echo

	echo "${GREEN}6.1.14 Audit SGID executables (Not Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -type f -perm -2000" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Ensure that no rogue SGID programs have been introduced into the system. Review the files returned by the action in the Audit section and confirm the integrity of these binaries." 2
	echo

	echo "${GREEN}6.2.1 Ensure password fields are not empty (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "awk -F: '(\$2 == \"\" ) { print \$1 \" does not have a password \"}' /etc/shadow" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "If any accounts in the /etc/shadow file do not have a password, run the following command to lock the account until it can be determined why it does not have a password:" 2
	console "passwd -l <username>" 2
	echo

	echo "${GREEN}6.2.2 Ensure no legacy \"+\" entries exist in /etc/passwd (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^\+:' /etc/passwd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Remove any legacy '+' entries from /etc/passwd if they exist." 2
	echo

	echo "${GREEN}6.2.3 Ensure root PATH Integrity (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 443" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 443" 2
	echo

	echo "${GREEN}6.2.4 Ensure no legacy \"+\" entries exist in /etc/shadow (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^\+:' /etc/shadow" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Remove any legacy '+' entries from /etc/shadow if they exist." 2
	echo

	echo "${GREEN}6.2.5 Ensure no legacy \"+\" entries exist in /etc/group (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep '^\+:' /etc/group" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Remove any legacy '+' entries from /etc/group if they exist." 2
	echo

	echo "${GREEN}6.2.6 Ensure root is the only UID 0 account (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "awk -F: '(\$3 == 0) { print \$1 }' /etc/passwd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Remove any users other than root with UID 0 or assign them a new UID if appropriate." 2
	echo

	echo "${GREEN}6.2.7 Ensure users' home directories permissions are 750 or more restrictive (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 447" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 448" 2
	echo

	echo "${GREEN}6.2.8 Ensure users own their home directories (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 449" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 449" 2
	echo

	echo "${GREEN}6.2.9 Ensure users' dot files are not group or world writable (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 451" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 452" 2
	echo

	echo "${GREEN}6.2.10 Ensure no users have .forward files (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 453" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 454" 2
	echo

	echo "${GREEN}6.2.11 Ensure no users have .netrc files (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 455" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 456" 2
	echo

	echo "${GREEN}6.2.12 Ensure users' .netrc Files are not group or world accessible (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 458" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 459" 2
	echo

	echo "${GREEN}6.2.13 Ensure no users have .rhosts files (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 460" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 461" 2
	echo

	echo "${GREEN}6.2.14 Ensure all groups in /etc/passwd exist in /etc/group (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "for i in \$(cut -s -d: -f4 /etc/passwd | sort -u ); do grep -q -P \"^.*?:[^:]*:\$i:\" /etc/group; if [ \$? -ne 0 ]; then echo \"Group \$i is referenced by /etc/passwd but does not exist in /etc/group\"; fi; done" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Analyze the output of the Audit step above and perform the appropriate action to correct any discrepancies found." 2
	echo

	echo "${GREEN}6.2.15 Ensure no duplicate UIDs exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 463" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 463" 2
	echo

	echo "${GREEN}6.2.16 Ensure no duplicate GIDs exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "cut -d: -f3 /etc/group | sort | uniq -d | while read x ; do echo \"Duplicate GID (\$x) in /etc/group\"; done" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Based on the results of the audit script, establish unique GIDs and review all files owned by the shared GID to determine which group they are supposed to belong to." 2
	echo

	echo "${GREEN}6.2.17 Ensure no duplicate user names exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "cut -d: -f1 /etc/passwd | sort | uniq -d | while read x; do echo \"Duplicate login name \${x} in /etc/passwd\"; done" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Based on the results of the audit script, establish unique user names for the users. File ownerships will automatically reflect the change as long as the users have unique UIDs." 2
	echo

	echo "${GREEN}6.2.18 Ensure no duplicate group names exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "cut -d: -f1 /etc/group | sort | uniq -d | while read x; do echo \"Duplicate group name \${x} in /etc/group\"; done" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Based on the results of the audit script, establish unique names for the user groups. File group ownerships will automatically reflect the change as long as the groups have unique GIDs." 2
	echo

	echo "${GREEN}6.2.19 Ensure shadow group is empty (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET}" 1
	console "grep ^shadow:[^:]*:[^:]*:[^:]+ /etc/group" 2 exe
	console "awk -F: '(\$4 == \"<shadow-gid>\") { print }' /etc/passwd" 2 exe
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Remove all users from the shadow group, and change the primary group of any users with shadow as their primary group." 2
	echo

	echo "${GREEN}6.2.20 Ensure all users' home directories exist (Scored)${RESET}"
	console "${BOLD}[AUDIT]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 468" 2
	console "${BOLD}[REMEDIATION]${RESET} ${BLINK}${BOLD}${PURPLE}Needs manual intervention${RESET}" 1
	console "Refer to the PDF. Page 469" 2
	echo
}

function main() {
	trap "echo -ne \"${RESET}\"" EXIT SIGTERM SIGQUIT SIGINT SIGSTOP SIGUSR1

	if [ -z "${1}" ]; then
		_help
		exit 1
	fi

	case "${2}" in
		-s|--skip|--skip=*)
			if grep -q "=" <<< "${2}"; then
				export SKIP=$(sed 's/--skip=//g' 2>/dev/null <<< "${2}")
			else
				export SKIP="${3}"
			fi
			export SKIP=$(sed -e 's/^,//g' -e 's/,$//g' <<< "${SKIP}")
			;;
	esac

	case "${1}" in
		-h|--help)
			_help
			exit 0
			;;
		-d|--dry)
			export DRY_RUN=1
			benchmark
			exit 0
			;;
		-e|--execute)
			export DRY_RUN=0
			benchmark
			exit 0
			;;
		*)
			_help
			exit 2
			;;
	esac

	return 0
}

main ${@}