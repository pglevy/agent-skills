# Appian SAIL browser interaction

Appian-specific layer on top of the base `browser-harness` skill. Read `SKILL.md` first for the tool API (`new_tab`, `js`, `click_at_xy`, `cdp`, `page_info`, etc.). This file only covers what is different when the page is a SAIL interface.

Origin: adapted from the `appian-browser-interaction` skill in `skill-exp3-gen`. That skill names tools like `browser_click`, `browser_type`, `browser_js`, and `browser_switch_tab`. In browser-harness, use `click_at_xy`, real keystrokes via `cdp("Input.dispatchKeyEvent", ...)` or `cdp("Input.insertText", text=...)`, `js(...)`, and `switch_tab()`.

When driving a live SAIL/Appian interface with browser-harness, the biggest source of wasted time and
wrong verdicts usually isn't understanding SAIL — it's false negatives from the browser tooling itself:
a click that silently misses, a typed value that never reaches React state, a screenshot that's stale.
These failure modes recur across different Appian apps, environments, and grading/testing passes
because they come from how SAIL renders (React-controlled, re-render-on-every-interaction) and how CDP
reports coordinates, not from any one app's bugs. This skill collects the recovery methods so you start
with them instead of rediscovering them mid-task.

This is an interaction/verification-side skill. It doesn't change how interfaces are built, and it
doesn't replace the base `browser-harness` skill's tool reference — it's the Appian-specific layer on
top.

## 1. There are three different coordinate spaces — don't mix them

- **Screenshot pixels**: whatever a screenshot call scaled/sized the image to (many environments cap
  screenshot dimensions — check for a project-specific limit before taking one).
- **CSS pixels**: what `page_info()`'s `w`/`h` report, and what `getBoundingClientRect()` returns.
- **Click coordinates**: `click_at_xy`/`browser_click` expect CSS pixels, not screenshot pixels.

Mixing these up produces clicks that land on the wrong element entirely — including, in one case, a
page logo instead of the intended button, which reloaded the page and looked exactly like the
application-level bug under investigation. Eyeballing a position from a screenshot instead of resolving
it has also produced near-misses on small targets.

**Don't eyeball a position from a screenshot.** Resolve the element's real position with
`cdp("Accessibility.getFullAXTree")` + `DOM.getBoxModel` (per the base skill), or
`element.getBoundingClientRect()` via `js(...)`, and click that CSS-pixel center. Cross-check once at
the start of a session whether the two spaces happen to align 1:1 on the current display — sometimes
they do — but don't assume it going in.

## 2. Never reuse a coordinate across more than one click

A rect you resolved for one click is only valid for that click. SAIL re-renders based on what's shown
or hidden — a card appearing above a button shifts everything below it. A button's position has been
observed to move across three different states purely from an unrelated section toggling visibility
above it; reusing a coordinate captured before that shift produces a false "nothing happened" reading.

**Re-query the element's rect fresh, immediately before every single click.** This matters most right
after a state-changing action (a previous click, a reload, a step transition) — exactly when it's
tempting to batch coordinates to save a round trip.

## 3. Typing into SAIL/React fields: use real input, then verify what landed

SAIL interfaces are React-controlled underneath. Setting an input's `.value` directly (e.g. via
`Object.getOwnPropertyDescriptor(...).set`) and dispatching a synthetic `input` event can make the field
*look* filled on screen while React's internal state stays empty — a subsequent action (e.g. clicking
"Next" on a disabled-until-filled button) then reads the stale state, because the framework never saw
a real change.

- Use `element.focus()` + the base skill's real-keystroke typing (`browser_type`), not direct DOM
  property assignment.
- After typing, read `.value` back from the DOM to confirm the framework actually captured it — don't
  infer from the screenshot alone.
- Same principle for dropdowns/radios/checkboxes: drive them with a real click or keyboard interaction,
  then confirm via `.checked`/`.textContent`/`.value`, not just a visual read.
- For very long text, see the base skill's note on avoiding slow per-character typing — but still
  verify the exact value landed, since a faster input method is more likely to get truncated or garbled
  silently.

## 4. When a click appears to do nothing, escalate in this order before calling it a defect

A click that produces no visible change could mean: your coordinates are wrong, the click didn't land
on the right element, or the app genuinely ignored it. Work through these in order — each step rules
out one explanation before you move to the next:

1. **Re-resolve and retry.** Don't trust a handle or rect from even one step earlier. Re-query the
   element fresh and issue a real mouse `browser_click` at the newly computed center.
2. **Bypass coordinates entirely.** Resolve the element via DOM query (`document.querySelectorAll` +
   text/attribute match) and call `.click()` on it directly through `js(...)`. This isolates "my
   coordinate math is wrong" from "the control itself doesn't respond." On more than one occasion,
   coordinate clicks were silently missing their targets (likely a screenshot/viewport scale mismatch),
   and switching to a direct DOM `.click()` resolved it immediately — before that, *no* reading on the
   page could be trusted.
3. **Only once a direct DOM `.click()` also produces nothing, treat it as a real finding** — and back
   it with more than a before/after screenshot comparison, which can look identical even when something
   subtle changed (or miss that nothing actually changed). Use the verification toolkit in the next
   section.

## 5. Verifying a negative result needs more rigor than verifying a positive one

"It worked" is easy to confirm — a visible banner, a changed value. "Nothing happened" is the harder,
more consequential claim, because it's usually the finding (a button that should do something but
doesn't). Earning real confidence in a genuine defect takes stacking several independent checks, not
relying on any single one:

- **`MutationObserver`** on `document.body` (`childList`, `subtree`, `characterData`, `attributes`),
  attached *before* the click. Compare the mutation count to a click on the same page that's known to
  work (e.g. an earlier step in the same flow, if it reveals something) — a real response should
  produce a comparable number of mutations; zero mutations on a click that should do something is
  strong evidence.
- **`document.body.innerText` diff** before/after — catches text-level changes a mutation count alone
  doesn't explain.
- **Network check**: patch `window.fetch` and `XMLHttpRequest.prototype.open` before the click (or use
  `cdp("Network.enable")`), then check whether any call fired at all. This tells you whether the
  interaction's `saveInto` ran server-side and the result failed to render, versus never firing in the
  first place — two very different root causes for the same symptom.
- **`performance.getEntriesByType('resource')` growth** as a cheaper proxy for the network check when
  patching fetch/XHR isn't convenient.
- For dialogs/errors specifically: diff the specific error container's `outerHTML` (not just
  `innerText`), and check `aria-live` regions for an injected announcement — a styling-only change (e.g.
  a border-color toggle) can slip past a text-only diff.

Reproduce the negative result at least twice, ideally with varied input, before writing it up — a
single occurrence is more likely to be a coordinate or timing mistake than a genuine finding.

## 6. Screenshots: avoid stale images and CDP timeouts

- **Unique filename per screenshot.** A fixed/reused path can silently return a cached image from an
  earlier state — the tool has been observed to flag this explicitly ("unchanged since you read it
  earlier"). Give every screenshot in a sequence its own path.
- **CDP screenshot timeout on the first attempt**: don't just retry on the same tab. Open a **new tab**
  to the same URL — this has reliably resolved first-attempt timeouts, consistent with known CDP
  flakiness on this kind of connection.
- Respect whatever screenshot size limit the current project/environment documents (e.g. a `max_dim`
  cap) — oversized screenshots can corrupt a session's context, independent of anything in this skill.

## 7. Tabs can race against you — pin to a target, don't rely on "active"

`browser_switch_tab` can intermittently lose a race to an unrelated tab stealing "active" status, even
when `browser_current_tab` correctly reports the intended tab right after switching — subsequent
screenshot/click calls can still land on the wrong tab.

**Workaround:** pin `browser_js` (and other target-scoped calls) to the specific `target_id` you got
back from opening/switching the tab, rather than depending on whichever tab the daemon currently
considers active. When driving something fiddly like a modal/dialog, prefer JS-level
`.click()`/`.scrollTop` on that pinned target over coordinate-based interaction — it sidesteps the race
entirely rather than fighting it.

## 8. Reload and re-render invalidate everything you cached

Any navigation, step transition, or re-render means every previously-resolved coordinate, element
handle, and screenshot is stale. Call `wait_for_load()` after navigation (per the base skill), then
re-resolve from scratch — don't carry anything forward across a state change, even a seemingly cosmetic
offset. Section 2's "re-query immediately before every click" rule is really this rule applied to the
single most common case.

## Quick checklist before writing up a "the control is broken" finding

- [ ] Did I resolve the element's position fresh for this exact click, not reused from earlier?
- [ ] Did I confirm typed/selected values landed in the DOM (`.value`/`.checked`/`.textContent`), not
      just visually?
- [ ] Did I retry with a direct DOM `.click()` to rule out a coordinate miss?
- [ ] Did I check for *any* observable effect — mutations, text diff, network activity — not just a
      screenshot comparison?
- [ ] Did I reproduce it more than once, ideally with different input?
- [ ] Is my screenshot path unique for this capture, and is the tab I'm reading the one I think it is?

If all of these check out and there's still no observable effect, you likely have a real finding —
write it up with the specific evidence (mutation count, network trace, DOM diff), not just "I clicked
and nothing happened."
