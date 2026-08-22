# Seihitsu Shirei user-guide video

This Remotion composition is both a non-technical user guide and a product demo. It is
based on the shipped SwiftUI/AppKit labels, controls, shortcut keys, settings, and capture
behaviour in `app/Sources/Seihitsu`.

The video is deliberately understandable with no sound. It covers:

1. One-time provider and permission setup.
2. Showing the HUD and asking a typed question.
3. Highlighting a question and pressing Option-C.
4. Setting a screen-reading region and pressing Option-V.
5. Asking by voice with Option-L.
6. Full, Brief, and Blitz answer modes.
7. What capture exclusion and OCR privacy do—and do not—promise.

## Commands

```bash
npm run voiceover
npm run studio
npm run typecheck
npm run still
npm run render
```

`npm run voiceover` reads `ELEVENLABS_API_KEY` from the repository-root `.env`
file and writes one narration clip per scene to `public/voiceover/`.

The final render is written to `out/seihitsu-user-guide.mp4`.
