---
description: Q&A + plan 생성 전담. 설계만 완료. 구현은 언제든 dev-impl(Claude/Codex)로 별도 진행.
user-invocable: true
---

# /dev-design 워크플로우

## 요구사항
$ARGUMENTS

## Step 1: 기존 Plan 확인

Glob 도구로 `.claude/plans/*.md` 파일 목록 확인:

**인수가 없는 경우 (`/dev-design` 단독 호출)**:
- plan 파일이 있으면: 목록을 보여주고 재개할 파일 선택 요청
- plan 파일이 없으면: 요구사항을 입력해달라고 안내

**인수가 있는 경우**:
- plan 파일이 있으면: 목록 + "재개 or 새 계획" 선택 요청
- plan 파일이 없으면: Step 2로 바로 진행

**재개 시**: plan 파일 읽어 세부 설계가 비어있는 첫 번째 Phase 파악 → Step 3으로 점프

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

4. Phase 단위 전체 계획 설계

5. 프로젝트 plan 파일 생성:
   - 경로: `.claude/plans/YYYY-MM-DD-<slug>.md`
   - 아래 Plan 파일 표준 템플릿 사용
   - **`사전 결정사항 / 참고` 섹션 작성 기준** (중요):
     - Q&A에서 결정된 사항을 **요약 없이** 충분히 상세하게 기입
     - 세부 설계 시 재질문 없이 구현 가능한 수준으로 작성
     - 포함할 내용: ① Q&A 결정사항 전체, ② 영향받는 파일/함수명+줄번호, ③ 참고할 기존 코드 패턴(코드 스니펫 포함 권장), ④ 아직 미결인 사항
     - 지나치게 요약하면 세부 설계 시 다시 물어봐야 하므로 상세하게 작성

6. ExitPlanMode 호출

ExitPlanMode 호출 후 **MANDATORY** — AskUserQuestion 도구를 호출하여 "Phase 1 세부 설계 Q&A를 시작할까요?" 확인:
- Yes → Step 3으로 진행
- No → 중단. 다음번 `/dev-design` 재개 시 Step 3(세부 설계)부터.

## Step 3: Phase 세부 설계 (설계만, 구현 없음)

**각 Phase마다 아래 순서 반복:**

TodoWrite 호출: `[{ content: "Phase N: <phase-title> 세부 설계", status: "in_progress" }]`

**EnterPlanMode 도구를 호출**하여 plan 모드로 전환 후:

1. **plan 파일 해당 Phase `사전 결정사항 / 참고` 섹션 먼저 정독**:
   - 이미 결정된 사항은 Q&A에서 재질문하지 말 것
   - 미결로 표시된 사항만 Q&A 대상

2. **Q&A 라운드 전 고려사항 출력** (동일 형식):
   - CLAUDE.md의 "Phase 세부 설계 시 검토 체크리스트" 전체 항목 검토

3. **Q&A 라운드** (최소 3회)

4. plan 파일 해당 Phase의 `세부 설계` + `Sub-steps` 섹션 채우기

5. plan 파일 해당 Phase 상태를 `[⏳ 대기]` 유지 (구현 미시작)

6. ExitPlanMode 호출

ExitPlanMode 호출 후 **MANDATORY** — AskUserQuestion 도구를 호출:

- **마지막 Phase가 아닌 경우**: "Phase N+1 세부 설계를 시작할까요?"
  - Yes → 다음 Phase 세부 설계로 계속
  - No → 중단. 다음번 재개 시 남은 Phase 세부 설계부터.

- **마지막 Phase인 경우**: "모든 Phase 세부 설계가 완료됐습니다. 지금 바로 /dev-impl로 구현을 시작하시겠습니까? (또는 나중에 별도로 진행 가능)"
  - Yes/No 모두 중단 (구현은 /dev-impl 호출로 별도 진행)

## 전체 완료

모든 Phase `세부 설계` 섹션 채우기 완료:

> "설계가 완료됐습니다. /dev-impl(Claude 또는 Codex)로 구현을 시작할 수 있습니다."

구현 시점은 사용자 판단 — 바로 시작해도 되고, 나중에 진행해도 됩니다.

---

## Plan 파일 표준 템플릿

```markdown
# <task-title>
<!-- Created: YYYY-MM-DD | Status: in-progress -->

## Context
<왜 이 작업이 필요한지, 목표>

## Phases

### Phase 1: <phase-title> [⏳ 대기]
**Goal**: <한 줄 목표>

#### 사전 결정사항 / 참고
<!--
  전체 설계 Q&A에서 결정된 사항을 요약 없이 상세하게 기입.
  세부 설계 Q&A 시 재질문 없이 구현 가능한 수준이어야 함.
  포함 항목:
  1. Q&A 결정사항 전체 (결정 이유 포함)
  2. 영향받는 파일/함수명 + 줄번호
  3. 참고할 기존 코드 패턴 (코드 스니펫 포함 권장)
  4. 아직 미결인 사항 (세부 설계 Q&A에서 결정 필요)
-->

#### 세부 설계
<!-- dev-design Phase Q&A 완료 후 채워짐 -->

#### Sub-steps
<!-- dev-design Phase Q&A 완료 후 채워짐 -->
- [ ] Step 1: ...
- [ ] Step 2: ...

### Phase 2: <phase-title> [⏳ 대기]
**Goal**: <한 줄 목표>

#### 사전 결정사항 / 참고
<!--
  전체 설계 Q&A에서 결정된 사항을 요약 없이 상세하게 기입.
  세부 설계 Q&A 시 재질문 없이 구현 가능한 수준이어야 함.
  포함 항목:
  1. Q&A 결정사항 전체 (결정 이유 포함)
  2. 영향받는 파일/함수명 + 줄번호
  3. 참고할 기존 코드 패턴 (코드 스니펫 포함 권장)
  4. 아직 미결인 사항 (세부 설계 Q&A에서 결정 필요)
-->

#### 세부 설계
<!-- dev-design Phase Q&A 완료 후 채워짐 -->

#### Sub-steps
<!-- dev-design Phase Q&A 완료 후 채워짐 -->
- [ ] Step 1: ...
- [ ] Step 2: ...
```
