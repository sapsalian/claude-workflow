---
description: plan 픽업 + 설계 검토 + 구현. dev-design으로 설계 완료된 plan을 이어받아 구현.
user-invocable: true
---

# /dev-impl 워크플로우

## 요구사항
$ARGUMENTS

## Step 1: Plan 선택

Glob 도구로 `.claude/plans/*.md` 파일 목록 확인.

- plan이 1개: 자동 선택
- plan이 여러 개: 목록 보여주고 선택 요청
- plan이 없음: "/dev-design 또는 /dev-full로 먼저 설계를 진행하세요" 안내

선택한 plan 전체 정독 (Context + 모든 Phase 세부 설계 + Sub-steps).

**재개 시**: 첫 번째 미완료(`[🔄]` 또는 `[⏳]`) Phase부터 Step 3 시작.

## Step 2: 설계 검토

구현자 관점에서 능동적으로 검토 후 아래 형식으로 보고:

```
## 설계 검토 결과

### 구현 관점 우려 사항
- [구현 시 문제가 될 수 있는 설계 결정, 실현 가능성, 누락된 엣지 케이스 등]
- 없으면: 없음

### 보완 제안 (선택적)
- [구현하면 더 나은 부분이 있다면]
- 없으면: 없음

### 구현 전 확인 필요 사항
- [결정되지 않아 구현 시작 전 확인이 필요한 항목]
- 없으면: 없음
```

우려/보완/확인 사항이 있으면 사용자 확인 후 해소.

검토 결과를 반영한 **최종 실행 계획 요약** 출력:

```
## 최종 실행 계획

| Phase | 주요 작업 | 비고 |
|-------|-----------|------|
| Phase 1: <title> | <핵심 Sub-steps 요약> | <설계 검토 반영 사항> |
| Phase 2: <title> | ... | ... |
```

이후 **MANDATORY** — AskUserQuestion 도구를 호출하여 "Phase 1 구현을 시작할까요?" 확인:
- Yes → Step 3으로 진행
- No → 중단.

## Step 3: Phase-by-phase 구현

각 Phase마다:

### Phase 시작 전 설계 확인

plan 파일의 해당 Phase `세부 설계` + `사전 결정사항 / 참고` 섹션을 읽고 아래 확인:

- **세부 설계가 비어있는 경우**: "이 Phase는 세부 설계가 필요합니다. /dev-design을 먼저 실행하거나 여기서 Q&A를 진행하시겠습니까?" 안내

- **세부 설계가 채워진 경우**: 아래 형식으로 검토 후 출력:
  ```
  ## Phase N 시작 전 확인

  ### 모호하거나 미결인 설계 사항
  - [사항] — 영향: [구현에 미치는 영향]
  ※ 없으면 생략

  ### 추가 결정 필요 사항
  - [사항] — 이유: [왜 지금 결정해야 하는지]
  ※ 없으면 생략
  ```
  - 모호/미결 사항이 **있으면**: AskUserQuestion으로 Q&A 진행 → 결정사항을 plan 파일 해당 Phase `세부 설계` 섹션에 추가 기록
  - **없으면**: 바로 구현 시작

### Phase 구현 시작

plan 파일에서 Phase N의 sub-steps 읽어 TodoWrite 호출 (이전 todo 목록 전체 교체):
```
[in_progress] Step 1: ...
[pending]     Step 2: ...
...
```

plan 파일 해당 Phase 상태를 `[🔄 진행 중]`으로 업데이트.

### Phase 구현

sub-step이 있으면 각 step마다:
1. 테스트 먼저 작성 (인프라 없으면 먼저 구축)
2. 기능 구현
3. 테스트 실행 → 통과해야만 다음 step 진행
4. **즉시 커밋 수행** (다음 step 진행 전 필수)
5. plan 파일 sub-step 카운터 업데이트: `(N/M)`
6. TodoWrite로 해당 step 완료 표시

sub-step이 없으면:
1. 테스트 먼저 작성
2. 기능 구현
3. 테스트 + 빌드 실행
4. **즉시 커밋 수행** (Phase 완료 처리 전 필수)

### Phase 완료 처리

1. 빌드 실행 → 성공해야만 완료 처리
2. plan 파일 해당 Phase 상태를 `[✅ 완료]`로 업데이트
3. **Phase 완료 커밋 수행** (반드시)

이후 **MANDATORY** — AskUserQuestion 도구를 호출:

- **마지막 Phase가 아닌 경우**: "Phase N+1 구현을 시작할까요?"
  - Yes → Phase N+1 구현으로 (세부 설계 확인 → TodoWrite → 구현)
  - No → 중단. 다음번 재개 시 Phase N+1부터.

- **마지막 Phase인 경우**: 전체 완료 처리로 진행.

## 전체 완료

- 모든 Phase `[✅]` 확인
- 최종 빌드 + 테스트 통과 확인
- 최종 커밋 (필요 시)
- plan 파일 상단 Status를 `complete`로 변경 + 완료 날짜 기록
