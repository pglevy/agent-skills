---
name: vignette
description: >
  Create animated product vignettes — short, cinematic HTML demos that showcase
  a product feature or workflow using GSAP animations. Use this skill when asked to
  build a vignette, product theater animation, animated demo, product walkthrough,
  cinematic UI demo, or GSAP-based product showcase. Also use when asked to animate
  a UI scene, create a camera-driven demo, or build a beat-scripted animation sequence.
---

# Vignette Skill

Build self-contained, single-file HTML vignettes that tell a visual story about a product
feature using GSAP-powered camera moves, typing effects, and UI state transitions.

## What a Vignette Is

A vignette is a single HTML file containing:
- A static UI scene (the "set") rendered in HTML/CSS
- A GSAP animation sequence that moves a virtual camera around the scene
- Captions that narrate what's happening
- UI state changes (typing, messages appearing, status updates) timed to the camera

The viewport is a fixed window (typically 1280×800) looking into an oversized scene.
The animation zooms and pans the scene to draw attention to different areas.

## Architecture

```
┌─────────────────────────────────────────────┐
│ viewport (1280×800, overflow: hidden)       │
│  ┌────────────────────────────────────────┐ │
│  │ scene (oversized, e.g. 1800×1100)      │ │
│  │  ┌──────┬──────────┬────────┐          │ │
│  │  │ left │  center  │ right  │          │ │
│  │  │panel │  panel   │ panel  │          │ │
│  │  └──────┴──────────┴────────┘          │ │
│  └────────────────────────────────────────┘ │
│  caption bar (overlay at bottom)            │
└─────────────────────────────────────────────┘
```

The scene uses CSS Grid for panel layout. GSAP animates `x`, `y`, and `scale` on the
scene element to create camera movements. At scale S, the viewport shows
(viewportWidth/S) × (viewportHeight/S) pixels of the scene.

## File Structure

Each vignette is a single self-contained HTML file. For complex vignettes, the animation
script can be separated:

```
my-vignette/
├── brief.md          # What the vignette shows (input from user)
├── demo.html         # The vignette (HTML + CSS + JS in one file)
└── script.js         # Optional: separated beat script (for data-driven approach)
```

## Workflow

### 1. Gather the Brief

Present the brief template from [brief-template.md](references/brief-template.md) to the user
and collaborate to fill it in. Each beat should capture:

- **FRAME**: What the camera shows (which panels, zoom level, what's in/out of view)
- **ACTION**: What changes on screen (typing, form fills, content appearing, or "None")
- **FEEL**: Camera energy (slow pan, quick snap, held shot, wide/pulled back)
- **TREATMENT** (optional): Special effects (scrims, floating overlays, glowing borders)
- **Reference image**: Attached images showing the expected UI content for that beat

The FRAME/ACTION/FEEL structure gives enough context to calculate camera positions and
timing. Without it, camera movements will be guesswork. Ask the user to provide reference
images for any beat where the visual content matters.

### 2. Design the Scene

Build the static HTML/CSS scene first. The scene should look like a realistic product UI.

Key principles:
- Use Sailwind design tokens for all colors, fonts, spacing (see Design Reference section below)
- Define only the color families actually needed as CSS custom properties
- Use Open Sans for UI text, Geist Mono for code
- The Appian header gradient is a signature element — include it when showing Appian-like UIs
- Scene dimensions should be larger than viewport to allow camera movement
- Use CSS Grid for panel layout with named grid areas

### 3. Script the Animation

Use async/await with GSAP for the animation sequence. Core helpers:

```js
// Camera move — animates scene transform
function cam(x, y, scale, dur = 1, ease = "power2.inOut") {
  return new Promise(resolve => {
    gsap.to("#scene", {
      x: -x, y: -y, scale,
      duration: dur, ease, transformOrigin: "top left",
      onComplete: resolve
    });
  });
}

// Typewriter effect
function typeText(el, text, dur = 1.4) {
  const chars = text.split("");
  let i = 0;
  el.textContent = "";
  return new Promise(resolve => {
    const interval = setInterval(() => {
      el.textContent += chars[i++];
      if (i >= chars.length) { clearInterval(interval); resolve(); }
    }, (dur * 1000) / chars.length);
  });
}

// Caption overlay
function caption(text) {
  const bar = document.querySelector("#caption-bar");
  const txt = document.querySelector("#caption-text");
  if (!text) { bar.classList.remove("visible"); return; }
  txt.textContent = text;
  bar.classList.add("visible");
}
```

### 4. Camera Math

Camera position `(x, y)` is the top-left corner of what's visible in the viewport.
At scale `S`, the viewport shows `(viewportW / S) × (viewportH / S)` of the scene.

To show a specific region:
- `x = targetX - (viewportW / S) / 2` to center horizontally on targetX
- Right-align: `x = sceneWidth - viewportW / S`
- Full scene: use a scale where `viewportW / S ≥ sceneWidth`

Document key positions as comments in the animation script.

### 5. Beat Patterns

Common animation beats:

| Beat | Pattern |
|------|---------|
| Establish | `cam(0, 0, fitScale)` — show full scene |
| Focus | `cam(panelX, panelY, 1.2-1.5)` — zoom to area of interest |
| Type input | `typeText(el, "user message", 2.0)` then clear + send |
| Agent response | Show typing dots → replace with message bubble |
| State change | Toggle CSS classes, swap visible panels |
| Highlight | `gsap.fromTo(el, { boxShadow: "0 0 0 0px rgba(...)" }, { boxShadow: "0 0 0 10px rgba(...,0)", repeat: 2 })` |
| Reveal | `gsap.to(el, { opacity: 1, duration: 0.4 })` |

### 6. Caption Guidelines

- Captions narrate for someone watching without audio
- Keep them short — one sentence, present tense
- Describe what's happening and why it matters
- Show captions during camera moves, hide during fast action
- Use `caption("")` to dismiss

## GSAP Reference

For GSAP API details, eases, timeline positioning, and ScrollTrigger:
see [gsap-cheatsheet.md](references/gsap-cheatsheet.md)

## Design Reference — Sailwind (live source of truth)

Vignettes use the Sailwind design system for all visual decisions. The tokens file is the
single source of truth — do not hardcode colors, fonts, spacing, or gradients.

### Fetching Tokens

Fetch the DTCG tokens file at the start of every vignette build:

```
https://cdn.jsdelivr.net/gh/pglevy/sailwind@v0.8.0/public/tokens.json
```

If the fetch fails, fall back to a local copy at `node_modules/@pglevy/sailwind/dist/tokens.json`
(install with `npm install --save-dev @pglevy/sailwind` if needed).

### Token Usage
Resolve all token aliases (e.g. `{color.blue.500}`) to their actual values when writing CSS. Base all design decisions on what you find in the fetched file — do not guess or infer token values.

## Technical Notes

- Load GSAP from CDN: `https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js`
- Load Google Fonts for Open Sans and Geist Mono
- Set initial camera state with `gsap.set()` before first paint to avoid flash
- Use `setTimeout(run, 400)` after window load to start the sequence
- All animations use Promises so beats can be sequenced with `await`
- Body background should be dark (`#111119`) to frame the viewport
- Viewport gets `border-radius: 8px` and a deep box-shadow for a floating screen look
