import windowsLogo from "../assets/cerberus/windows-logo.webp";
import windowsMark from "../assets/cerberus/windows-mark.webp";
import linuxLogo from "../assets/cerberus/linux-logo.webp";
import linuxMark from "../assets/cerberus/linux-icon.webp";
import macosLogo from "../assets/cerberus/macos-logo.webp";
import macosMark from "../assets/cerberus/macos-mark.webp";
import type { GuardianId } from "./types";

export interface GuardianArt {
  logo: string;
  mark: string;
  logoAlt: string;
  markAlt: string;
}

export const artwork: Record<GuardianId, GuardianArt> = {
  windows: {
    logo: windowsLogo,
    mark: windowsMark,
    logoAlt:
      "WindowsGuardianWatchdog artwork: an electric-blue cybernetic wolf. The repository image includes the WindowsGuardian Watchdog wordmark.",
    markAlt: "WindowsGuardianWatchdog wolf mark in electric blue, without the wordmark.",
  },
  linux: {
    logo: linuxLogo,
    mark: linuxMark,
    logoAlt:
      "LinuxGuardianWatchdog artwork: a neon-purple cybernetic wolf with orange accents. The repository image includes the LinuxGuardian Watchdog wordmark.",
    markAlt: "LinuxGuardianWatchdog wolf mark in neon purple and orange, without the wordmark.",
  },
  macos: {
    logo: macosLogo,
    mark: macosMark,
    logoAlt:
      "MacGuardianWatchdog artwork: a magenta and crimson cybernetic wolf. The repository image includes the MacGuardian Watchdog wordmark.",
    markAlt: "MacGuardianWatchdog wolf mark in magenta and crimson.",
  },
};
