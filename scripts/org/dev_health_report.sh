#!/usr/bin/env bash
# Weekly development-health report per active repo (.github#60).
# Logic lives in dev_health_report.py (tested by dev_health_report_test.py);
# repos and thresholds live in dev_health_config.json.
set -euo pipefail
exec python3 "$(dirname "$0")/dev_health_report.py" "$@"
