# Claude Workflow Config

Claude Code 전역 설정 — `/develop` 워크플로우 자동화.

Codex와 함께 사용할 때는 [codex-workflow](https://github.com/sapsalian/codex-workflow) 설치가 필요합니다.

## 포함 파일

| 파일 | 역할 |
|------|------|
| `settings.json` | 전역 권한 규칙 + PermissionRequest 훅 |
| `CLAUDE.md` | 전역 워크플로우 행동 규칙, Codex 협업 규칙 |
| `hooks/auto-approve-exit-plan.sh` | ExitPlanMode 자동 승인 훅 |
| `skills/develop/SKILL.md` | `/develop` — dev-full (Q&A + 설계 + 구현 전 과정) |
| `skills/dev-design/SKILL.md` | `/dev-design` — Q&A + plan 생성 전담 |
| `skills/dev-impl/SKILL.md` | `/dev-impl` — plan 픽업 + 설계 검토 + 구현 |
| `skills/cothink/SKILL.md` | `/cothink` — plan 없이 Q&A 반복 후 요청 수행 |

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

## 스킬 가이드

| 스킬 | 언제 쓰나 |
|------|----------|
| `/develop` (dev-full) | Claude Code 단독으로 설계부터 구현까지 전 과정 |
| `/dev-design` | 설계만 먼저 완료. 구현은 나중에 dev-impl로 |
| `/dev-impl` | 완성된 plan 픽업 후 설계 검토 + 구현 |
| `/cothink` | plan 없이 Q&A 반복 후 단일 요청 수행 |

### 워크플로우 흐름 (dev-full)

1. **Step 1**: 기존 plan 파일 탐색 (재개 or 새 계획)
2. **Step 2**: 전체 계획 수립 (plan mode + Q&A 최소 3라운드) → plan 파일 생성
3. **Step 3**: Phase별 반복
   - 세부 설계 (plan mode + Q&A 최소 3라운드) → plan 파일 `세부 설계` 섹션 채우기
   - TDD 구현 (테스트 먼저 → 구현 → 통과 → 커밋)
   - Phase 완료 커밋

### Codex와 협업할 때

- `/dev-design`: Claude Code에서 설계 완료 → plan 파일에 세부 설계 채우기
- Codex `/dev-impl`: plan 픽업 → 처방 검토 → 구현
- 복귀 조건: 복잡한 디버깅, 구조 변경, 새 Phase 세부 설계

### 자동화 범위

- Bash 명령어 자동 승인 (아래 위험 명령 제외)
- ExitPlanMode 자동 승인 (PermissionRequest 훅)

### 차단된 명령어

`rm -rf`, `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D`, `git commit --no-verify`, `sudo rm`
