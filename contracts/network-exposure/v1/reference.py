"""Cerberus network exposure contract reference; stdlib-only and detection-only."""
import ipaddress

CLASSES = {"remote_control", "admin", "database", "remote_login", "web", "mail", "printing", "dns", "discovery", "vpn", "robotics", "unknown"}
FIREWALL = {"verified_allowed", "verified_denied", "unknown"}

def normalize(row):
    """Normalize a Guardian record without guessing actual network reachability."""
    required = {"platform", "protocol", "bind_address", "port", "service_class", "owner_visibility", "firewall_verdict"}
    if not isinstance(row, dict) or required - row.keys():
        raise ValueError("missing required fields")
    if row["platform"] not in {"linux", "macos", "windows"} or row["protocol"] not in {"tcp", "udp"}:
        raise ValueError("unsupported platform or protocol")
    if type(row["port"]) is not int or not 1 <= row["port"] <= 65535:
        raise ValueError("invalid port")
    if row["service_class"] not in CLASSES or row["owner_visibility"] not in {"visible", "unavailable", "unknown"}:
        raise ValueError("invalid service class or owner visibility")
    if row["firewall_verdict"] not in FIREWALL:
        raise ValueError("invalid firewall verdict")
    try:
        address = ipaddress.ip_address(row["bind_address"].split("%", 1)[0])
    except (ValueError, AttributeError) as exc:
        raise ValueError("invalid bind address") from exc
    result = dict(row)
    result["reachability"] = "loopback" if address.is_loopback else "non_loopback"
    result["enforcement"] = "observed_only"
    return result
