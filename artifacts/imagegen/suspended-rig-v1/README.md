# DeepMine Suspended Rig Assets v1

- 생성 경로: Codex 내장 ImageGen
- 목적: 기존 제자리 광부 연출을 현수식 채굴 리그로 대체하고, 장비·분기 구매가 실제 설비 교체로 보이게 한다.
- 원본: `raw/`
- 크로마 제거: `extracted/`
- 네 안료·이진 알파 처리본: `processed/`
- 앱: `DeepMineProbe/Shared/SharedAssets.xcassets/`
- 웹: `web/public/assets/rig/`
- 구성: 리그 본체 1, 드릴 3티어, 장비 분기 모듈 6종, 세대 하우징 실루엣 4종

```sh
uv run --with pillow python scripts/process_suspended_rig_assets.py
uv run --with pillow python scripts/process_suspended_rig_assets.py --validate-only
```

전체 생성 프롬프트와 실제 원본 SHA-256은 `PROMPTS.md`와 `manifest.json`에 보존한다.
