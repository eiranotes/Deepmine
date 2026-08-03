# DeepMine 캐릭터 굴착감 Pro 리뷰 컨텍스트

## 결론과 반영 결과

- 별도 ChatGPT 프로젝트: `DeepMine — 굴착감 개선`
- Pro 채팅: <https://chatgpt.com/c/6a6fe3ff-b194-83ee-b85c-bf985e321150>
- ChatGPT Pro와 독립 코드 감사의 공통 판정은 새 에셋 부족이 아니라 고정 작업선·혼합 좌표계와
  320px modulo 배경 위상이 P0라는 것이다.
- `web/app/miningCamera.ts`에 상태를 소유하지 않는 파생 카메라 수식을 추가했다. 첫 65%에는
  광부·립·균열이 최대 72.8px 하강하고, 후반에는 카메라가 헤드를 앞서지 않으며 따라잡는다.
- 암반 위상은 `-(cameraDepth × 28px)` 원시 좌표를 사용해 `-284→-24px` 역보간을 제거했다.
- 기존 `MinerMiningStrip`, `ShaftFrontierLip`, 세로 균열로 목표를 충족해 새 이미지는 만들지
  않았다. 1280×720과 390×844의 54% 진행에서 광부가 각각 약 62px·61px 내려갔다.
- 웹 20/20, lint, Vinext production, Pages build와 모바일 가로 overflow 0을 확인했다.

## 요청과 현재 증상

- 공개 빌드: <https://eiranotes.github.io/Deepmine/>
- 사용자 판정: 캐릭터가 직접 파고 내려가는 느낌이 없고, 정적 에셋을 연결해 반복하는 것처럼 보인다.
- 검토 범위: 웹 `MinePrototype`의 공간 좌표, 캐릭터 타임라인, 지층/통로/카메라 합성, 기존 생성 에셋의 역할 적합성.
- 보존할 것: React/CSS Modules, 네 안료 픽셀 광산 장비판 정체성, Core 경제 공식, 직접 타격→광석→장비→자동화 루프, 접근성 및 Reduce Motion.

## 현재 좌표와 상태 로직

```ts
const METERS_PER_LAYER = METERS_PER_SEGMENT; // 4m
const PIXELS_PER_METER = 28;

const progress = Math.min(1, mine.damage / integrity);
const headDepth = mine.depth + progress * METERS_PER_LAYER;

const sceneStyle = {
  "--break-progress": progress.toFixed(3),
  "--rock-phase": `${-((headDepth * PIXELS_PER_METER) % 320)}px`,
  "--surface-y": `${16 - headDepth * PIXELS_PER_METER}px`,
  "--fracture-reveal": `${progress <= 0 ? 0 : 18 + progress * 142}px`,
  "--kerf-depth": `${progress <= 0 ? 0 : 10 + progress * 116}px`,
};
```

```css
.shaft { --workline: 36%; }

.rockWorld {
  background-image: var(--rock-image);
  background-position: center var(--rock-phase);
  background-repeat: repeat-y;
  background-size: 100% 320px;
}

.openShaft {
  top: 0;
  height: calc(var(--workline) + 26px);
}

.workLine {
  top: var(--workline);
}

.miningActor {
  top: -123px;
  left: calc(50% - 128px);
  width: 152px;
  height: 152px;
  background-image: url("/assets/shaft/MinerMiningStrip.png");
  animation: miner-quick-strike var(--strike-duration) linear both;
}
```

타격은 quick/heavy/critical 접촉 시점에 데미지를 적용한다. 암반이 끝나면 560ms 좌우 붕괴 밴드를 재생하고 `mine.depth += 4` 한다. 하지만 화면 좌표에서 광부·막장·파쇄 경계는 항상 `--workline: 36%`에 고정되어 있다.

## 에셋 감사

### 이미 있는 것

- `MinerMiningStrip.png`: 준비→예비동작→전신 접촉→반동 4프레임, 원본 384×96을 CSS에서
  608×152로 표시하는 스프라이트 스트립.
- `ShaftFrontierLip.png`: 열린 통로와 현재 암반을 연결하는 U자형 파쇄 경계.
- `ShaftRock_entry/crystal/ruins/abyss.png`: 지역별 320×128 와이드 벽면.
- `ShaftFractureVertical_light/medium/heavy.png`: 진행도별 세로 균열.
- `ShaftSurface.png`, `ShaftGantry.png`, `SeamVein.png`, 장비·파편·약점·공명 결절 에셋.
- 생성 원본·후처리·네 안료·알파·provenance는 `artifacts/imagegen/*`에 보존된다.

### 관찰한 병목

1. `rockWorld`는 한 장을 320px마다 `repeat-y`하고 타격당 약 11.2px씩 배경 위치만 바뀐다. 새로운 공간에 들어가는 것보다 컨베이어 벨트가 움직이는 인상이 강하다.
2. 광부, 발판, 파쇄 경계, 충격점이 같은 고정 작업선에 남는다. `headDepth` 숫자와 지층 텍스처는 움직이지만 주체가 하강하지 않는다.
3. 첫 지표 에셋은 빠르게 화면 밖으로 사라지고, 이후에는 큰 고정 기준물이나 전경 시차가 없어 거리 변화가 약하다.
4. 4프레임 스트립은 타격 동작은 전달하지만 하강·착지·다음 막장 진입 프레임은 없다.
5. 붕괴 뒤 같은 구도의 막장이 즉시 다시 나타나므로 4m 단위 사건이 공간 변화가 아니라 루프 리셋처럼 읽힌다.

## 채택한 저위험 해법

경제와 상태 소스는 유지하고 카메라와 헤드의 화면 좌표를 분리한다.

```ts
// 초반 65%는 카메라를 고정하고 광부/막장이 실제로 아래로 내려간다.
// 후반 35%는 카메라가 따라 내려오며 광부를 기준 작업선으로 복귀시킨다.
const x = clamp((progress - 0.65) / 0.35);
const cameraProgress = Math.min(progress, smoothstep(x));
const cameraDepth = mine.depth + cameraProgress * METERS_PER_LAYER;
const headScreenOffset = (headDepth - cameraDepth) * PIXELS_PER_METER;
```

- `rockWorld`, 지표, 과거 지지대, 심도 눈금은 `cameraDepth`로 이동.
- 광부·파쇄 경계·균열·보상 표식은 `--workline + headScreenOffset`으로 실제 하강.
- 열린 통로는 현재 헤드까지 길어지고, 후반 카메라 catch-up 동안 지나온 지지대가 위로 넘어간다.
- 파괴 시 기존 붕괴 상태를 유지하고 작업선·열린 통로의 520ms 정착으로 카메라 복귀를 잇는다.
- 전경 먼지/케이블과 착지 전용 프레임은 이번 좌표 수정 후에도 부족하다는 근거가 생길 때로 미룬다.
- Reduce Motion도 파생 공간 상태를 유지하되 전환 시간을 1ms로 줄여 즉시 읽히게 한다.

## Pro에게 요청하는 판단

1. 사용자가 느낀 “정적 에셋 반복”의 가장 큰 원인을 위 코드와 공개 화면 기준으로 우선순위화해 달라.
2. 새 이미지 생성 없이 좌표·타임라인·합성만으로 해결 가능한 범위와, 정말 필요한 추가 스프라이트 프레임을 구분해 달라.
3. 캐릭터가 직접 파고 내려가는 느낌을 만드는 한 세그먼트의 화면 시퀀스를 구체적인 비율/시간으로 제안해 달라.
4. 기존 네 안료 픽셀 정체성과 Core 경제를 보존하며 적용할 P0/P1 개선안을 제시해 달라.
5. 1280×720과 390×844에서 확인할 수 있는 관찰 가능한 수용 기준을 제시해 달라.
