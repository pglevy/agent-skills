# GSAP Cheatsheet

Source: [gsap.com/resources/cheatsheet](https://gsap.com/resources/cheatsheet)
Full docs: [gsap.com/docs/v3](https://gsap.com/docs/v3/)

## Basics

```js
// "to" tween — animate to provided values
gsap.to(".selector", {
  x: 100,
  backgroundColor: "red",   // camelCase CSS props
  duration: 1,
  delay: 0.5,
  ease: "power2.inOut",
  stagger: 0.1,
  repeat: 2,                // -1 for infinite
  yoyo: true,
  onComplete: () => {},
  // onStart, onUpdate, onRepeat, onReverseComplete
});

gsap.from('.selector', { fromVars });
gsap.fromTo('.selector', { fromVars }, { toVars });
gsap.set('.selector', { toVars });  // immediate, no animation
```

## Timelines

```js
let tl = gsap.timeline({
  defaults: { duration: 1, ease: 'none' },
  paused: true,
  repeat: 2,
  yoyo: true,
  onComplete: () => {},
});

tl.to('.a', { x: 50 })
  .to('.b', { autoAlpha: 0 })
  .to('.c', { backgroundColor: 'red' });

// Position parameter (controls placement in timeline)
tl.to(target, { toVars }, positionParameter);
//   0.7          — absolute time (seconds)
//   '-=0.7'      — overlap previous by 0.7s
//   'myLabel'    — at label position
//   '<'          — align with start of previous child
//   '<0.2'       — 0.2s after start of previous
//   '-=50%'      — overlap half of this tween's duration
```

## Control Methods

```js
let anim = gsap.to(...); // or gsap.timeline(...)
anim.play().pause().resume().reverse().restart()
  .timeScale(2)       // 2x speed
  .seek(1.5)          // jump to time or label
  .progress(0.5)      // jump to 50%
  .kill()             // destroy
  .isActive()         // true if animating
  .then()             // Promise

// Timeline-specific
tl.add(thing, position)
  .call(func, params, position)
  .getChildren()
  .clear()
  .tweenTo(timeOrLabel, { vars })
  .tweenFromTo(from, to, { vars })
```

## Eases

```js
'none'        // linear
'power1', 'power2', 'power3', 'power4', 'circ', 'expo', 'sine'
// Each has .in, .out, .inOut — e.g. "power2.inOut"

// Expressive
'elastic', 'back', 'bounce', 'steps(n)'
```

## ScrollTrigger

```js
scrollTrigger: {
  trigger: ".selector",
  start: "top center",       // [trigger] [scroller]
  end: "20px 80%",
  scrub: true,               // or time in seconds
  pin: true,
  markers: true,             // dev only
  toggleActions: "play pause resume reset",
  snap: { snapTo: 1/10, duration: 0.5 },
  onEnter: callback,
  // onLeave, onEnterBack, onLeaveBack, onUpdate, onToggle
}
```

## Nesting Timelines

```js
function scene1() {
  let tl = gsap.timeline();
  tl.to(...).to(...);
  return tl;
}

let master = gsap.timeline()
  .add(scene1())
  .add(scene2(), "-=0.5");  // overlap
```

## Utility Methods

```js
gsap.utils.clamp(0, 100, value)
gsap.utils.mapRange(0, 100, 0, 1, 50)  // → 0.5
gsap.utils.interpolate(0, 100, 0.5)    // → 50
gsap.utils.random(0, 100)
gsap.utils.snap(10, 23)                // → 20
gsap.utils.toArray(".selector")
```

## Registered Effects

```js
gsap.registerEffect({
  name: "fade",
  effect: (targets, config) => gsap.to(targets, { duration: config.duration, opacity: 0 }),
  defaults: { duration: 2 },
  extendTimeline: true,
});

gsap.effects.fade(".box");
tl.fade(".box", { duration: 3 });
```

## CDN Installation

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/ScrollTrigger.min.js"></script>
```
