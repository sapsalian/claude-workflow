#!/bin/bash
# PermissionRequest 훅: ExitPlanMode 자동 승인 시도
# /develop 워크플로우에서 Q&A 완료 후 계획 승인을 자동화
# 입력 파싱 실패 시 exit 0으로 안전하게 pass-through

python3 - <<'EOF'
import sys, json

try:
    data = json.load(sys.stdin)
    tool = data.get('tool_name', data.get('tool', ''))
    if tool == 'ExitPlanMode':
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PermissionRequest",
                "permissionDecision": "allow",
                "permissionDecisionReason": "Auto-approved: /develop workflow plan complete"
            }
        }))
except Exception:
    pass  # 파싱 실패 시 아무것도 출력하지 않고 exit 0
EOF
