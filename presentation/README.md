# Presentation package

- `../presentation.pptx` — final editable 18-slide deck.
- `slides.json` — single source for slide content, timing, and narration.
- `rendered/` — 1280×720 frames used by the video renderer.
- `voiceover_script.md` — timed 17:50 narration.
- `live_demo_runbook.md` — deterministic PostgreSQL and UI demonstration.
- `defense_questions.md` — likely questions, answers, and live SQL changes.
- `BioVault_Presentation_Video.mp4` — generated rehearsal video.

Regenerate slides:

```powershell
python scripts/generate_presentation.py
```

Regenerate the rehearsal video:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/render_video.ps1
```

The rehearsal video uses a synthetic Windows voice. Replace it with the
submitting student's own narration if required by the instructor.
