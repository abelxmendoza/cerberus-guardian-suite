"""Read-only LinuxGuardian JSONL -> Cerberus network-exposure v1 adapter."""
import json
import sys
from reference import normalize

def convert(meta, services):
    if not isinstance(meta, dict) or meta.get("type") != "meta" or meta.get("ss_ok") is not True:
        raise ValueError("listener collection unavailable; cannot report success")
    if not isinstance(services, list):
        raise ValueError("services must be list")
    output = []
    for service in services:
        if not isinstance(service, dict) or service.get("type") != "service":
            raise ValueError("invalid service")
        binds = service.get("binds")
        if not isinstance(binds, list) or not binds:
            raise ValueError("missing binds")
        for bind in binds:
            if not isinstance(bind, dict) or not isinstance(bind.get("host"), str):
                raise ValueError("invalid bind")
            if bind["host"] == "*":
                raise ValueError("ambiguous wildcard address family")
            row = normalize({
                "platform": "linux", "protocol": service.get("proto"),
                "bind_address": bind["host"], "port": service.get("port"),
                "service_class": service.get("class"),
                "owner_visibility": "visible" if service.get("owner_known") is True else "unavailable",
                "firewall_verdict": "unknown",
            })
            row["source_id"] = service.get("id")
            row["source_severity"] = service.get("severity")
            output.append(row)
    return output

def parse_jsonl(lines):
    records = [json.loads(line) for line in lines if line.strip()]
    if not records or not isinstance(records[0], dict) or records[0].get("type") != "meta":
        raise ValueError("missing first meta record")
    return convert(records[0], records[1:])

def main():
    try:
        rows = parse_jsonl(sys.stdin)
        print(json.dumps({"contract": "network-exposure/v1", "status": "ok", "records": rows}))
    except (ValueError, TypeError, KeyError) as exc:
        print("adapter error: " + str(exc), file=sys.stderr)
        return 2
    return 0

if __name__ == "__main__":
    sys.exit(main())
