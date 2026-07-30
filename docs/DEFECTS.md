# Defects and Release Gates

업데이트: 2026-07-30

## Confirmed simulator defects

현재 자동 테스트와 19개 default-spec 이미지 read-back에서 남은 재현 가능 blocker는 없다.

수정한 주요 결함:

- 장비 경제가 레벨 상한 훨씬 전에 정체했다. 선형 `+%p` 효과와 `1.38^n` 비용이 결합해 드릴
  19레벨의 상대 이득이 +3.6%, 회수 1,094세션이었다. 복리 효과와 `1.34^n` 비용, 심도 해금
  상한 60으로 교체했다. (D-023)
- 프레스티지가 run 기준 심도를 초기화해, 하루 100분 페르소나가 하루 25분 페르소나보다 낮은
  심도와 낮은 장비를 보이는 역전이 발생했다. 심도를 lifetime 기준으로 전환했다. (D-024)
- 프레스티지가 순손실이었다. 1회차 조각 1개로 최대 ×21 복리 장비를 초기화했다. 굴착 기억
  재구매 할인 50%와 run 크레딧 비례 조각으로 교체했다. (D-025)
- Dynamic Island/위젯의 시작·포기 버튼이 App Group 큐에만 기록하고 앱이 foreground가 될
  때까지 아무 일도 하지 않았다. 차단·알람·Live Activity가 시작되지 않고, 포기 버튼은 차단을
  유지한 채 남겼다. Live Activity intent가 앱 프로세스에서 즉시 명령을 적용한다. (D-027)
- 시계 무결성이 `ProcessInfo.systemUptime`(슬립 중 정지)을 써서, 화면을 끄고 진행한 정직한
  세션이 30초 임계를 넘겨 개방 채굴로 강등될 수 있었다. `CLOCK_MONOTONIC_RAW`로 교체했다.
- 스트릭 감쇠가 결석일마다 절반씩 누적되어 2주 공백이 실질 초기화였다. Spec §7.2가 거부한
  동작이다. 결석 1회당 감쇠 1회로 바꾸고 감쇠를 보상 계산 전에 확정한다.
- 중도 귀환이 공명 광맥의 다음 세션 ×2를 소진했다. 심층 포기(광석 0)에서도 소진됐다.
  완료한 세션에서만 소진한다.
- 추천 강화가 푸른 광맥만 계산해 램프의 기대 가치를 0으로 평가했다. 공명·수정·금고·심연을
  포함한 기대 광석으로 교체했다.
- 귀환 보고서의 등급 배지가 `state.completed`("준비 완료")를 재사용해 완료 화면에서 준비
  상태 문구를 보였다. 등급별 문구로 교체했다.
- `dailyRecords`가 무제한 증가해 장기 사용자의 매 저장이 전체 배열을 인코딩했다. 730일 상한.
- 탐사 갱도의 유일한 이점인 광맥 확률 3배가 어느 화면에도 없어 항상 열등한 선택으로 보였다.
- 연속 일수와 휴광일이 앱의 어떤 화면에도 표시되지 않았다. `game.streak` 등 관련 문자열이
  정의만 되어 있었다.

- 대형 500-history fixture가 통계 캡처를 지연시키던 문제를 대표 populated fixture로 분리했다. 500-history overflow 자체는 별도 UI 회귀 테스트로 유지한다.
- 격리 UI fixture가 제품 App Group 명령 큐를 drain해 관련 없는 복구 경고를 띄울 수 있던 문제를 차단했다.
- 귀환 보고서 소비 뒤 passive snapshot이 완료 상태에 남던 문제를 clear→waiting 게시 계약으로 수정했다.
- widget의 stale/missing 상태가 가짜 0 수치를 보이던 문제를 명시적 앱 열기 복구 상태로 교체했다.

## Open physical-device release gates

아래는 확정 결함이 아니라 시뮬레이터가 증명할 수 없는 위험이며, 통과 전 출시를 막는다.

| ID | 심각도 | 상태 | 항목 |
|---|---|---|---|
| GATE-001 | Critical | 미검증 | 승인 FamilyControls/App Group entitlement와 실제 차단·공유 컨테이너 |
| GATE-002 | Critical | 미검증 | AlarmKit과 커스텀 Live Activity의 실제 Dynamic Island 동시 운용 |
| GATE-003 | High | 미검증 | 앱 종료·재부팅·stale monitor에서 shield가 남지 않는지 |
| GATE-004 | High | 미검증 | 실제 extension→app 명령 큐 왕복과 applying crash window |
| GATE-005 | High | 미검증 | 잠금화면/StandBy/Control Center의 시스템 합성·크롭·수명주기 |
| GATE-006 | Medium | 미검증 | 실제 VoiceOver, Reduce Motion, Increase Contrast, 햅틱·사운드 체감 |

## Known non-blocking development signal

Xcode 26.5 UI test 로그의 `DebuggerVersionStore`/`no debugger version` 진단은 테스트 launch마다 출력되지만 성공 여부와 무관한 Xcode 환경 메시지다. 제품 오류로 분류하지 않는다.

