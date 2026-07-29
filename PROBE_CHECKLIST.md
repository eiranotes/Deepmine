# DeepMine Phase 0 Device Checklist

기기 / OS: ____________________  날짜: ____________________

| # | 검증 항목 | 통과 기준 | 결과 | 관찰 / 오류 원문 |
|---:|---|---|---|---|
| 1 | LA Expanded 재시작 | 앱이 백그라운드인 상태에서 버튼을 누르면 기존 LA가 종료된 뒤 새 60초 LA가 오류 없이 생성됨 | 미검증 | |
| 2 | staleDate 완료 전환 | 앱을 강제 종료해도 종료 시각에 완료 뷰와 READY 상태가 보임 | 미검증 | |
| 3 | AlarmKit + 자체 LA | 60초 알람과 LA를 함께 실행해도 Dynamic Island가 중복되거나 충돌하지 않음 | 미검증 | |
| 4 | FamilyControls entitlement | Individual 권한 요청이 승인되고 FamilyActivityPicker가 정상 표시됨 | 미검증 | |
| 5 | shield 적용 / 해제 지연과 fail-safe | 선택 앱 또는 카테고리에 shield가 2초 안에 적용되고 해제됨. 앱을 강제 종료해도 expiry에 monitor가 해제하며, 재실행 시 overdue/missing-monitor journal이 남은 shield를 해제함. 연속 재적용 시 이전 monitor callback이 새 세션의 shield/journal을 해제하지 않음 | 미검증 | |
| 6 | Compact 24pt 식별성 | compact leading의 광부/곡괭이 실루엣을 3개 기기 크기에서 식별 가능 | 미검증 | |
| 7 | StandBy Night Mode | 적색 단색 상태에서 명도만으로 아이콘과 진행 상태가 판독됨 | 미검증 | |
| 8 | Expanded 높이 | 진행/완료 화면 모두 144pt에서 잘리지 않음 | 미검증 | |
| 9 | 시간 조작 방어 판정 | 정상 차이는 `.valid`, 30초 초과 차이는 `.tampered`, 단조 시계 리셋은 `.rebooted`로 정확히 표시됨 | 미검증 | |
| 10 | 익스텐션 SwiftData 왕복 | 위젯 AppIntent가 App Group SwiftData에 직접 쓴 레코드를 앱 복귀 시 같은 UUID로 읽고 승인 시각을 저장함 | 미검증 | |

## Gate

- P0 통과/실패가 기록되기 전까지 P1 구현을 시작하지 않는다.
- #1 또는 #3 실패 시 `docs/SPEC_v0.2.md` §18 대응안을 먼저 사양에 반영한다.
