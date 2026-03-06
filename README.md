# Claude Workflow Config

Claude Code 전역 설정 — `/develop` 워크플로우 자동화.

## 포함 파일

| 파일 | 역할 |
|------|------|
| `settings.json` | 전역 권한 규칙 + PermissionRequest 훅 |
| `CLAUDE.md` | 전역 워크플로우 행동 규칙 |
| `hooks/auto-approve-exit-plan.sh` | ExitPlanMode 자동 승인 훅 |
| `skills/develop/SKILL.md` | `/develop` 명령어 스킬 |

## 설치 (새 컴퓨터)

### 사전 조건

- [Claude Code](https://claude.ai/code) 설치
- Python 3 설치 (`python3 --version` 확인)
- 이 저장소 접근 가능한 SSH 키 설정

### 방법 1: ~/.claude가 없는 경우 (새 설치)

```bash
git clone git@sapsalian:sapsalian/claude-workflow.git ~/.claude
chmod +x ~/.claude/hooks/auto-approve-exit-plan.sh
```

### 방법 2: ~/.claude가 이미 있는 경우 (기존 설치에 적용)

```bash
cd ~/.claude
git init
git remote add origin git@sapsalian:sapsalian/claude-workflow.git
git fetch origin
git checkout main -- settings.json CLAUDE.md hooks/ skills/
chmod +x ~/.claude/hooks/auto-approve-exit-plan.sh
```

Claude Code 재시작 후 바로 적용됩니다.

## 업데이트

```bash
cd ~/.claude
git pull
chmod +x hooks/auto-approve-exit-plan.sh  # 권한 재확인
```

## 사용법

프로젝트 루트에서 Claude Code 세션 시작 후:

```
/develop <요구사항>
```

예시:
```
/develop 사용자 인증 기능 추가
/develop          ← 기존 plan 목록 보기 및 재개
```

### 워크플로우 흐름

1. **Step 1**: 기존 plan 파일 탐색 (재개 or 새 계획)
2. **Step 2**: 전체 계획 수립 (plan mode + Q&A 최대 3회)
3. **Step 3**: Phase별 반복 실행
   - 세부 설계 (plan mode + Q&A)
   - 구현 (TDD: 테스트 먼저 → 구현 → 테스트 통과 → 커밋)
   - Phase 완료 커밋

### 자동화 범위

- Bash 명령어 자동 승인 (아래 위험 명령 제외)
- ExitPlanMode 자동 승인 (PermissionRequest 훅)

### 차단된 명령어

`rm -rf`, `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D`, `git commit --no-verify`, `sudo rm`
