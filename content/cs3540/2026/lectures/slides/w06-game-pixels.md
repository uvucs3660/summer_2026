---
track: game
week: 6
title: Pixels
subtitle: Local Space, Multiplication Order, and Why Draw Calls Cost More Than Pixels
runtime: 22
---

NOTES:
Week six, game track. This is the week things appear on screen.

Everything so far has been a simulation you could only inspect through a hash. Today it becomes visible — and I want to be careful about that, because the temptation once you can see things is to start fixing them by looking. The simulation is still the truth. The renderer is still downstream. Nothing you learn today is allowed to reach back across that line.

---

# What you'll know after this

- Why a child stores **local** position, never world
- Why `Translate × Rotate × Scale` and `Rotate × Translate × Scale` are different games
- Why the cost is **draw calls**, not pixels
- Why the camera is an **inverse**, and draw order is your z-index

NOTES:
Four things. Two of them are choices your spec section has to pin, and I will flag them as we pass.

---

# Local, not world

A turret is **"12 units in front of the ship."**

It is never **"at (340, 122)."**

- Rotate the ship and the turret follows — for free
- Its stored position never described the world in the first place
- Assign a world position to a child and the hierarchy **stops working**

You are now updating every part by hand, forever.

NOTES:
Start with the rule, because everything about scene graphs follows from it.

A child stores where it is relative to its parent. The turret is twelve units in front of the ship. That is the whole record. There is no world position stored anywhere on the turret.

Now rotate the ship ninety degrees. The turret's stored data does not change at all — it is still twelve units in front — and it ends up in the right place on screen because "in front" is defined by the parent.

The failure is seductive and I have watched people write it: you compute the turret's world position once, store it, and now it is correct. It is correct for exactly one frame. The moment the ship moves you have to recompute it, and you have to remember to, and so does everyone else touching that code. You have replaced a rule with a chore.

---

# Multiplication order

![](scene-graph-transforms-multiplication-order.svg)

NOTES:
Second thing, and this is one of the pinned choices.

Transforms compose by matrix multiplication, and matrix multiplication does not commute. Translate times rotate times scale, applied right to left, scales the object, spins it about its own origin, then moves it. The thing spins in place.

Swap the rotate and the translate and you get the right-hand picture. The object is moved out first and *then* the rotation applies to the whole composed transform — so it sweeps around the origin. It orbits.

Same three operations. Same numbers. Completely different behavior, and both are legitimate matrix maths. Nothing is broken in either picture.

Which means if your section says "apply the transform" without saying the order, two builds will pick differently, and one of them will have everything orbiting the world origin. Write the order down. This is the third pinned choice this term after rounding and iteration order, and by now I hope you can feel them coming.

---

# The cost is draw calls

```
6 sprites, unbatched      → fine
6,000 sprites, unbatched  → a slideshow
6,000 sprites, one atlas  → fine
```

Each **texture swap flushes the pipeline.** The pixels were never the problem.

- One atlas, sorted by texture, one submission
- **Pad the atlas** — bilinear filtering samples the neighbour and gives you a one-pixel fringe

NOTES:
Now performance, and the mental model most people arrive with is wrong.

The instinct is that drawing is expensive per pixel — that a big sprite costs more than a small one. On any GPU made this century, filling pixels is nearly free at the scales you are working at.

What costs is changing state. Every time you switch texture, the pipeline flushes: work in flight has to finish before the new state takes effect. Six sprites with six textures is six flushes and nobody notices. Six thousand is six thousand flushes and you have a slideshow — while the GPU sits mostly idle, which is why profiling this by watching GPU utilisation is so misleading.

The fix is an atlas. Put the sprites in one texture, sort your draws by texture, submit once.

And pad it. If two sprites touch in the atlas, bilinear filtering samples across the boundary and you get a one-pixel fringe of the neighbour along the edge. It looks like a rendering bug and it is a packing bug, and you will spend an hour on it if nobody warns you. Consider yourself warned.

---

# The camera is an inverse

There is no camera object.

**Moving the camera right means moving the world left.**

```js
view = inverse(cameraTransform);   // composed backwards
```

This is the source of most "why is my camera doing that."

NOTES:
Short one, and it removes a whole category of confusion.

There is no camera. The GPU draws what is in front of it at a fixed place; you do not move the viewer, you move everything else in the opposite direction.

So the view transform is the inverse of where you think the camera is. Move the camera right by ten, the world shifts left by ten. Rotate the camera clockwise, the world rotates counter-clockwise.

Almost every camera bug is a missing or doubled inverse, and the symptom is that everything moves the wrong way or twice as fast. If your camera feels haunted, that is where to look first.

---

# Draw order is your z-index

![](2d-rendering-draw-order.svg)

NOTES:
Last piece, and it is the tie-break argument again in a fourth costume.

Canvas 2D has no depth buffer. Whatever you draw last is on top. So you sort — by layer, usually.

But two sprites on the same layer are tied, and a tie resolved by iteration order is a tie resolved by nothing. On screen, they can swap between frames, and you get flicker that appears and disappears depending on how the entities happened to be inserted. Across builds, they can disagree, and now your renderer output is implementation-defined.

Break by id and both problems go away at once. Read the line at the bottom: the same tie-break that keeps the hash stable also stops the flicker. That is not a coincidence — they are the same underlying defect, one visible in a number and one visible to a player.

---

# Before Thursday

- **Find the transform order in your engine.** Is it written down anywhere, or only in code?
- Count your **draw calls** for one frame. Guess first, then measure.
- Read `spec/S04` and `spec/S09` — scene graph and the 2D backend
- `cheatsheet-scene-graph-transforms`, `cheatsheet-2d-rendering`

Thursday, AI: **Hooks** — the only deterministic pillar, and we write the conformance guard live.

NOTES:
Two things, and the first one is the discussion.

Find your transform order and tell me where it is written down. For most of you the honest answer will be "nowhere, it is just the order the code does it in." That is exactly the state a specification exists to fix, and if you own S04 this is your homework rather than an exercise.

And count draw calls — guess first, then measure. Write the guess down before you look. Being wrong about it is the point; that gap is the thing Thursday of next week is about.

Thursday is hooks, and it is the one lecture in the AI track that is not about talking to a model at all.
