# Shaft Scene Art Prompts

- 목적: 세로 갱도의 작업 지점·지역별 지질·장기 심도·지상 입구·고보상 암맥·직접 타격을 읽히게 하는 갱도 자산 16종과 진행 표식 4종
- 생성: OpenAI ImageGen 기반 시안 후 네 안료 픽셀 양자화
- 출력: PNG 원본, 투명 자산 RGBA, 역할별 논리 PNG와 Asset Catalog imageset
- 팔레트: coal, shale, limestone, brass의 DeepMine 네 안료
- 후처리 원칙: 최근접 축소, 이진 알파, lossless, original rendering

## 공통 규칙

모든 자산은 와이드 구도, 정면 2D 픽셀 아트, 단단한 계단형 모서리와 DeepMine 네 안료만
사용한다. 오버레이는 투명 배경, 암벽은 불투명한 화면 끝-끝 구도다. 텍스트, 글로우,
그라데이션, 부드러운 그림자, 원근, UI 프레임은 금지한다.

## `shaft-gantry` → `ShaftGantry`

작업 중인 암반 위에 합성되는 갱도 설비 프레임. 좌우 끝의 두꺼운 석재·철제 지지대, 짧은
상부 크로스빔, 중앙의 작은 황동 램프, 한쪽의 도르래와 짧은 케이블, 아래의 가는 광차 레일을
그린다. 중앙 폭 70%, 높이 58% 이상은 비워 실제 탭 대상 암반을 가리지 않는다.

## `seam-vein` → `SeamVein`

25층마다 등장하는 고보상 암맥 오버레이. 좌우 끝까지 이어지는 좁고 불규칙한 석회질 광맥,
2–3개의 가지, 드문 황동 광석 주머니로 구성한다. 위아래를 넓게 비워 기존 암반 파괴 단계를
읽을 수 있어야 한다.

## `shaft-rock-entry` → `ShaftRock_entry`

입구 지역의 연속 퇴적암 벽. 넓게 이어지는 셰일 지층, 석탄색 균열, 드문 석회 파편으로
구성하며 중앙 바위나 둥근 암석 더미를 만들지 않는다. 좌우 가장자리는 반복 배치에 견딘다.

## `shaft-rock-crystal` → `ShaftRock_crystal`

수정 지역의 연속 각진 셰일 벽. 작은 석회 수정 군집을 지층 안에 박고 황동 끝은 드물게만
사용한다. 수정 아이콘을 흩뿌린 배경이나 분리된 바위 더미로 읽히면 안 된다.

## `shaft-rock-ruins` → `ShaftRock_ruins`

자연 셰일에 융합된 고대 가공 석벽. 큰 석재 단, 닳은 모르타르 선, 벽에 박힌 문지방 조각을
사용한다. 문·문자·룬·작은 벽돌의 과밀 반복은 금지한다.

## `shaft-rock-abyss` → `ShaftRock_abyss`

심연 지역의 거의 검은 연속 암벽. 넓고 매끈한 면, 깊은 공극, 드문 얇은 석회 테두리만으로
압박감을 만든다. 눈·생물·상징·중앙 오브젝트는 금지한다.

## `shaft-rock-pressure` → `ShaftRock_pressure`

5km부터 사용하는 압착층. 수평으로 눌린 두꺼운 암판, 짧고 반복적인 압축 균열, 드문 석회
전단선을 사용한다. 심연보다 층이 촘촘하고 압력이 읽혀야 하며, 중앙 오브젝트는 두지 않는다.

## `shaft-rock-fault` → `ShaftRock_fault`

20km부터 사용하는 대단층층. 화면을 비스듬히 가르는 한두 개의 큰 전단대와 서로 어긋난
암판을 사용한다. 황동은 단층 마찰면의 작은 노출부에만 두고, 단순 대각선 줄무늬가 되지 않게
불규칙한 파쇄대를 만든다.

## `shaft-rock-core` → `ShaftRock_core`

100km부터 사용하는 심핵층. 매우 조밀한 검은 암반 속에 굵은 석회 압력맥과 제한된 황동
용융 흔적을 둔다. 불꽃·마그마 그라데이션 없이 네 안료의 면적 대비만으로 온도와 밀도를
표현하며, 좌우 반복 이음새가 드러나지 않아야 한다.

## `shaft-surface` → `ShaftSurface`

0m 갱도 위 90pt를 채우는 지상 입구 오버레이. 위쪽의 얇은 흙·석재 단면, 좌우 끝의 작은
지지대, 황동 표지등 하나만 두고 중앙과 아래 중앙 75% 이상을 비운다. 기존 막장용 gantry의
도르래·레일·케이블을 반복하지 않는다.

## `mining-pickaxe` → `MiningPickaxe`

광부의 손과 분리해 회전시키는 단일 측면 곡괭이. 손잡이는 좌하단에서 우상단으로 길게 뻗고,
넓은 철제 날은 우상단에 둔다. 좌하단 끝을 어깨 회전축으로 사용할 수 있도록 여백을 확보한다.
광부·손·다른 공구·그림자는 넣지 않는다.

## `shaft-fracture-vertical-light` → `ShaftFractureVertical_light`

상단 중앙에서 시작해 하단 중앙 가까이까지 이어지는 가는 세로 균열. 짧은 가지는 하나만
허용하며 방사형 충격점, 가로 광맥, 돌 배경, 파편은 금지한다.

## `shaft-fracture-vertical-medium` → `ShaftFractureVertical_medium`

동일한 세로 경로를 유지한 중간 손상. 주 균열을 조금 넓히고 높이가 다른 짧은 가지 두 개만
추가한다. 중심 폭발이나 별 모양으로 읽히면 안 된다.

## `shaft-fracture-vertical-heavy` → `ShaftFractureVertical_heavy`

동일한 세로 경로를 유지한 붕괴 직전 손상. 위에서 아래까지 주 균열을 크게 벌리고 짧은
비대칭 가지 세 개와 결손 모서리를 둔다. 여전히 하나의 아래 방향 갈라짐으로 읽혀야 한다.

## `shaft-frontier-lip` → `ShaftFrontierLip`

열린 통로와 현재 작업면을 하나의 암반으로 잇는 U자형 어깨. 위쪽 가운데는 비우고, 좌우
어깨는 같은 지층에서 깎여 나온 것처럼 연결한다. 하단 가운데에는 절삭 홈을 두어 세로 균열이
그 접점에서 아래로 자라게 한다. 별도의 바닥선, 구조물, 광부는 넣지 않는다.

## `miner-mining-strip` → `MinerMiningStrip`

같은 광부의 준비·예비동작·전신 접촉·반동 4프레임을 같은 기준선과 배율로 가로로 이어 붙인
스트립. 곡괭이는 네 프레임 모두 양손에 있고, 어깨·몸통·무릎·부츠가 도구와 함께 움직인다.
프레임 폭은 정확히 균등해야 하며 별도의 곡괭이 단독 프레임은 넣지 않는다.

# Progression Marks

## `refinement-badge-drill` → `RefinementBadge_drill`

32×32 투명 픽셀 배지. 원형 황동 리벳 테두리 안에 드릴 비트와 압축 링을 배치한다. 작은
크기에서 드릴·광차·램프 배지가 즉시 구분되어야 하며 문자와 숫자는 넣지 않는다.

## `refinement-badge-cart` → `RefinementBadge_cart`

32×32 투명 픽셀 배지. 황동 리벳 테두리 안에 광차 호퍼와 짧은 이중 레일을 배치한다.
드릴 비트 실루엣을 반복하지 않는다.

## `refinement-badge-lamp` → `RefinementBadge_lamp`

32×32 투명 픽셀 배지. 황동 리벳 테두리 안에 작업등과 반사경을 배치한다. 광원 글로우 없이
석회 면과 황동 테두리 대비로 발광을 암시한다.

## `prestige-memory-ring` → `PrestigeMemoryRing`

48×48 투명 픽셀 표식. 여러 번의 하강을 기록한 동심 황동 링, 중앙의 검은 갱도 구멍,
석회 깊이 눈금을 사용한다. 화살표·문자·숫자 없이 영구 기억과 재시작을 읽히게 한다.

## 편입 계약

- 갱도 암반은 320×128 논리 크기, 진행 배지는 32×32, 기억 링은 48×48을 사용한다.
- iOS는 `DeepMineProbe/Shared/SharedAssets.xcassets`의 universal 1x 원본을 최근접 보간한다.
- 웹은 동일한 심도 암반 PNG를 `web/public/assets/shaft`에서 사용한다.
- 모든 PNG는 lossless이고 `template-rendering-intent`는 `original`이다.
- 장기 지질 선택 기준은 절대 심도 5km·20km·100km이며 경제 지역 계산과 분리한다.
