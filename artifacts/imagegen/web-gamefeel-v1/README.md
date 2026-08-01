# DeepMine Web Game-Feel Assets v1

- 생성 경로: Codex 내장 ImageGen
- 범위: 웹 기준안 전용. 앱 Asset Catalog에는 아직 편입하지 않는다.
- `MinerMiningStrip`: 준비 → 예비동작 → 전신 접촉 → 반동의 4프레임 일체형 광부·곡괭이 스트립
- `ShaftFrontierLip`: 열린 갱도와 현재 암반을 하나의 U자형 파쇄 경계로 연결하는 오버레이
- 원본: `raw/`
- 크로마 제거: `extracted/`
- 4색·이진 알파 산출물: `processed/`
- 웹 복사본: `web/public/assets/shaft/`
- 실제 최종 생성 프롬프트: `PROMPTS.md`

```sh
uv run --with pillow python scripts/process_web_gamefeel_assets.py
```

`manifest.json`은 정규화한 프롬프트 요약, ImageGen 원본 SHA-256, 추출본·처리본·웹 경로를
보존하며 실제 도구 호출의 전체 프롬프트는 `PROMPTS.md`에 둔다.
