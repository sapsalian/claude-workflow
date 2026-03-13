---
description: Q&A + 설계 + 구현 전 과정. Codex 없이 Claude Code 단독으로 전체 개발 수행. (dev-full)
user-invocable: true
---

# /dev-full 워크플로우

## 요구사항
$ARGUMENTS

## Step 1: 기존 Plan 확인

Glob 도구로 `.claude/plans/*.md` 파일 목록 확인:

**인수가 없는 경우 (`/dev-full` 단독 호출)**:
- plan 파일이 있으면: 목록을 보여주고 재개할 파일 선택 요청
- plan 파일이 없으면: 요구사항을 입력해달라고 안내

**인수가 있는 경우**:
- plan 파일이 있으면: 목록 + "재개 or 새 계획" 선택 요청
- plan 파일이 없으면: Step 2로 바로 진행

**재개 시**: plan 파일 전체 정독 후 현재 상태 판단:
- 세부 설계가 비어있는 Phase가 있으면 → Step 3(세부 설계)에서 해당 Phase부터 재개
- 모든 Phase 세부 설계 완료 + 미완료 구현 Phase 있으면 → Step 4(구현)에서 해당 Phase부터 재개

## Step 2: 전체 계획 수립

**EnterPlanMode 도구를 호출**하여 plan 모드로 전환 후 아래 진행:

1. Explore agent로 코드베이스 현재 상태 파악

2. **Q&A 라운드 전 고려사항 출력** (매 라운드 시작 전 필수):
   - CLAUDE.md의 "전체 설계 시 검토 체크리스트" 전체 항목 검토
   ```
   ## 고려 사항 정리 (라운드 N/3)

   ### 검토한 사항
   - [사항]: [판단 내용]

   ### 자동 결정한 사항
   - [사항]: [결정] — 이유: [근거]

   ### 사용자에게 질문할 사항
   - [질문들]
   ```

3. **Q&A 라운드** (최소 3회): AskUserQuestion으로 결정/고려 사항 확인

4. Phase 단위 전체 계획 설계 (각 Phase = 독립 동작 체크포인트)
   - 복잡한 Phase는 sub-step으로 분해

5. 프로젝트 plan 파일 생성:
   - 경로: `.claude/plans/YYYY-MM-DD-<slug>.md`
   - 아래 Plan 파일 표준 템플릿 사용

6. ExitPlanMode 호출

ExitPlanMode 호출 후 **MANDATORY** — AskUserQuestion 도구를 호출하여 "Phase 1 세부 설계 Q&A를 시작할까요?" 확인:
- Yes → Step 3으로 진행
- No → 중단. 다음번 `/dev-full` 재개 시 Step 3(세부 설계)부터.

## Step 3: 전체 Phase 세부 설계

**각 Phase마다 아래 순서 반복:**

### 3-1. Phase 세부 설계

**EnterPlanMode 도구를 호출**하여 plan 모드로 전환 후:

1. **Q&A 라운드 전 고려사항 출력** (Step 2와 동일한 형식):
   - CLAUDE.md의 "Phase 세부 설계 시 검토 체크리스트" 전체 항목 검토

2. **Q&A 라운드** (최소 3회)

3. plan 파일 해당 Phase의 `세부 설계` + `Sub-steps` 섹션 채우기

4. ExitPlanMode 호출

ExitPlanMode 호출 후 **MANDATORY** — AskUserQuestion 도구를 호출:

- **마지막 Phase가 아닌 경우**: "Phase N+1 세부 설계를 시작할까요?"
  - Yes → 다음 Phase 세부 설계로 계속
  - No → 중단. 다음번 재개 시 남은 Phase 세부 설계부터.

- **마지막 Phase인 경우**: "모든 Phase 세부 설계 완료. Phase 1 구현을 시작할까요?"
  - Yes → Step 4로 진행
  - No → 중단. 다음번 재개 시 Step 4(구현)부터.

## Step 4: 전체 Phase 구현

**각 Phase마다 아래 순서 반복:**

### 4-1. Phase 구현 시작

plan 파일에서 Phase N의 sub-steps 읽어 TodoWrite 호출 (이전 todo 목록 전체 교체):
```
[in_progress] Step 1: ...
[pending]     Step 2: ...
...
```

plan 파일 해당 Phase 상태를 `[🔄 진행 중]`으로 업데이트.

### 4-2. Phase 구현

sub-step이 있으면 각 step마다:
1. 테스트 먼저 작성 (인프라 없으면 먼저 구축)
2. 기능 구현
3. 테스트 실행 → 통과해야만 다음 step 진행
4. 중간 커밋
5. plan 파일 sub-step 카운터 업데이트: `(N/M)`
6. TodoWrite로 해당 step 완료 표시

sub-step이 없으면:
1. 테스트 먼저 작성
2. 기능 구현
3. 테스트 + 빌드 실행
4. 중간 커밋

### 4-3. Phase 완료 처리

1. 빌드 실행 → 성공해야만 완료 처리
2. plan 파일 해당 Phase 상태를 `[✅ 완료]`로 업데이트
3. **Phase 완료 커밋 수행** (반드시)

이후 **MANDATORY** — AskUserQuestion 도구를 호출:

- **마지막 Phase가 아닌 경우**: "Phase N+1 구현을 시작할까요?"
  - Yes → Phase N+1 구현(4-1)으로
  - No → 중단. 다음번 재개 시 Phase N+1 구현부터.

- **마지막 Phase인 경우**: 전체 완료 처리로 진행.

## 전체 완료

- 모든 Phase `[✅]` 확인
- 최종 빌드 + 테스트 통과 확인
- 필요 시 최종 커밋
- plan 파일 상단 Status를 `complete`로 변경 + 완료 날짜 기록

---

## Plan 파일 표준 템플릿

새 계획 생성 시 아래 형식 사용:

```markdown
# <task-title>
<!-- Created: YYYY-MM-DD | Status: in-progress -->

## Context
<왜 이 작업이 필요한지, 목표>

## Phases

### Phase 1: <phase-title> [⏳ 대기]
**Goal**: <한 줄 목표>

#### 사전 결정사항 / 참고
<!-- 전체 설계 Q&A에서 결정된 사항 및 세부 설계 시 참고할 사항 작성 -->

#### 세부 설계
<!-- Claude Code Phase Q&A 완료 후 채워짐 -->

#### Sub-steps
<!-- Claude Code Phase Q&A 완료 후 채워짐 -->
- [ ] Step 1: ...
- [ ] Step 2: ...

### Phase 2: <phase-title> [⏳ 대기]
**Goal**: <한 줄 목표>

#### 사전 결정사항 / 참고
<!-- 전체 설계 Q&A에서 결정된 사항 및 세부 설계 시 참고할 사항 작성 -->

#### 세부 설계
<!-- Claude Code Phase Q&A 완료 후 채워짐 -->

#### Sub-steps
<!-- Claude Code Phase Q&A 완료 후 채워짐 -->
- [ ] Step 1: ...
- [ ] Step 2: ...
```
