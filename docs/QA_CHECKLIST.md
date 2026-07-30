# QA Checklist

업데이트: 2026-07-30

표기: `자동`은 XCTest/SwiftPM, `시뮬레이터`는 iPhone 17 Pro iOS 26.5의 한국어·다크·기본 medium·표준 대비, `실기기`는 승인 entitlement와 물리 하드웨어가 필요한 항목이다.

## 게임 코어 — 자동 완료

- [x] 합법/불법 세션 상태 전이와 완료 ID 재적용 방지
- [x] 완료·포기·붕괴, 15/25/50분, 검증 등급, 피로도 경계 보상
- [x] Date/단조 시계 정상·앞/뒤 조작·재부팅 분류
- [x] 장비 가격·효과·20레벨·추천 동률
- [x] 광맥 시드/분포, 8회 보장, 다섯 종류 효과
- [x] 지역·테마·금고·수정·공명·심연 진행
- [x] 자정·시간대 변경·휴광일·스트릭 절반 감소
- [x] 프레스티지 eligibility/reset/preserve/replay
- [x] 500회/500 credits 유한성과 30일 성장 가드레일

## 저장·복구 — 자동 완료

- [x] 명시적 SwiftData v1 전체 round-trip과 재개방
- [x] 빈 저장소 기본 상태와 미지원 스키마 fail-closed
- [x] 손상 store/wal/shm 격리와 복구 notice
- [x] 세션 완료/귀환 보고서 원자적 commit과 보고서 소비
- [x] 명령 큐 동시 append, applying crash replay, 무중복 receipt
- [x] malformed 명령 격리, 256KB/최근 500개 상한
- [x] UI fixture 격리 저장소가 제품 App Group 큐를 소비하지 않음

## 앱 흐름 — 시뮬레이터 완료

- [x] 설명 2장 → 90초 연습 → 보상 → 강화 → 권한 순서
- [x] 세 권한의 거부 fixture가 개방 채굴로 계속 진행
- [x] 안전/심층/탐사, 15/25/50 선택 기억과 심층 잠금 이유
- [x] preflight → active → 명시적 포기 → 귀환 → 장비 handoff 전체 흐름
- [x] 귀환 3박자, 다섯 광맥, `마치기`/`다음 출정 준비` 동등 위계
- [x] 장비, 빈/채운 일지, 기록, 테마, 설정, 프레스티지 및 복구 상태
- [x] 한국어/영어 default-medium clipping과 플레이어 용어
- [x] 44pt target, accessibility label/identifier, Reduce Motion 대체의 코드/자동 단언

## 표시 표면 — 시뮬레이터 완료

- [x] Dynamic Island minimal/compact/expanded≤144pt fixture
- [x] 잠금화면≤160pt와 StandBy-shaped fixture
- [x] 홈 위젯 small/medium 상태와 Control Widget 상태
- [x] ContentState 크기, 큰 숫자 축약, stale/missing 복구 문구
- [x] 네 안료 스프라이트 asset 규격과 grayscale 의미 구조
- [x] 화면 19장 + contact sheet 생성 및 전부 육안 확인

## 시스템 통합 — 실기기 미검증

- [ ] FamilyControls 승인 entitlement와 실제 방해 앱 선택
- [ ] ManagedSettings shield 2초 내 적용/종료/포기 해제
- [ ] 앱 종료 상태 DeviceActivityMonitor 해제와 stale callback 방어
- [ ] AlarmKit 알람과 자체 Live Activity 동시 운용
- [ ] Live Activity staleDate, 재시작 intent, 실제 Dynamic Island
- [ ] 실제 SpringBoard 잠금화면 crop과 완료 후 수명주기
- [ ] 충전·가로 StandBy 및 Night Mode 단색 판독
- [ ] App Group을 통한 실제 extension→app 명령 왕복
- [ ] Dynamic Island 미지원 기기 잠금화면-only 흐름
- [ ] 실제 권한 거부, 재부팅, 시간대 변경, 자정 경과 복원
- [ ] VoiceOver 초점, Increase Contrast, Reduce Motion, 햅틱·사운드

사용자 지시에 따라 oversized Dynamic Type 시각 테스트는 이번 기본 사양 판정에 포함하지 않았다.

