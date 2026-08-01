# DeepMine Rock Assets v1

- 생성 경로: Codex 내장 ImageGen (`gpt-image-2`)
- 프롬프트 기준: `docs/ROCK_ART_PROMPTS.md`
- 원본: `raw/`의 고유 PNG 24개
- 투명 추출: `extracted/`의 균열 오버레이 3개
- 논리 산출물: `processed/`의 64×64 PNG 24개
- Asset Catalog: 각 슬롯의 1x/2x/3x imageset, 총 PNG 72개
- 미리보기: `contact-sheet.png`
- 생성·검증: `scripts/process_rock_assets.py`

```sh
/Users/tofu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  scripts/process_rock_assets.py --validate-only
```

`manifest.json`은 슬롯 ID, 프롬프트 ID, 최종 정규화 프롬프트, 원본 SHA-256,
후처리 산출물과 imageset 경로를 보존한다.
