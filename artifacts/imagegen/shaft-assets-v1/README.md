# DeepMine Shaft Assets v1

- 생성 경로: Codex 내장 ImageGen (`gpt-image-2`)
- 프롬프트 기준: `docs/SHAFT_ART_PROMPTS.md`
- 원본: `raw/`의 고유 PNG 7개
- 투명 추출: `extracted/`의 크로마 제거 RGBA 3개
- 논리 산출물: `processed/`의 320×128 PNG 6개와 320×90 PNG 1개
- Asset Catalog: 각 슬롯의 1x/2x/3x imageset, 총 PNG 21개
- 생성·검증: `scripts/process_shaft_assets.py`
- 화면 증거: `ui-captures/mine-home-final.png` (한국어·다크·medium 시뮬레이터)

```sh
python3 scripts/process_shaft_assets.py --validate-only
```

`manifest.json`은 슬롯 ID, 프롬프트 ID, 최종 프롬프트, 원본 SHA-256, 추출본과 imageset
경로를 보존한다.
