---
track: game
week: 6
title: Pixels
subtitle: Local Space, Multiplication Order, and Why Draw Calls Cost More Than Pixels
runtime: 22
---

NOTES:
Week six, game track. This is the week things appear on screen.

Everything so far has been a simulation you could only inspect through a hash. Today it becomes visible, and I want to be careful about that, because the moment you can see things the temptation is to start fixing them by looking. A sprite is in the wrong place, so you nudge the sprite. It looks right. You move on. What you have actually done is write a lie into the renderer to cover a bug in the simulation, and those two will disagree with each other forever after, quietly, somewhere nobody thinks to check.

The simulation is still the truth. The renderer is still downstream. Nothing you learn today is allowed to reach back across that line.

---

# What you'll know after this

- Why a child stores **local** position, never world
- Why `Translate × Rotate × Scale` and `Rotate × Translate × Scale` are different games
- Why the cost is **draw calls**, not pixels
- Why the camera is an **inverse**, and draw order is your z-index

NOTES:
Four things. Two of them are choices your spec section has to pin down, and I will flag those as we pass them, because you will want to write them into your section the same evening.

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

A child stores where it is relative to its parent. The turret is twelve units in front of the ship. That is the whole record. There is no world position stored anywhere on the turret, and there is nowhere to put one.

Now rotate the ship ninety degrees. The turret's stored data does not change at all. It is still twelve units in front. And it lands in the right place on screen, because in front is defined by the parent, and the parent is what moved.

The failure here is the tempting one, and I have watched people write it. You compute the turret's world position once, you store it, and now it is correct. It is correct for exactly one frame. The moment the ship moves, that number is stale, and somebody has to recompute it, and remember to recompute it, and so does everyone else who ever touches that code. You have replaced a rule with a chore.

---

# Multiplication order

![](scene-graph-transforms-multiplication-order.svg)

NOTES:
Second thing, and this is one of the pinned choices.

Transforms compose by matrix multiplication, and matrix multiplication does not commute. Translate times rotate times scale, applied right to left, scales the object, spins it about its own origin, and then moves it. The thing spins in place.

Swap the rotate and the translate and you get the right-hand picture. The object is moved out first, and the rotation then applies to the whole composed transform, so it sweeps the moved object around the origin. It orbits.

Same three operations. Same numbers. Completely different behavior, and both are legitimate matrix maths. Nothing is broken in either picture, which is exactly why nothing will show up as an error anywhere.

So if your section says apply the transform without saying in what order, two builds will pick differently, and one of them will have everything in the game orbiting the world origin. Write the order down. That is the third pinned choice this term, after rounding and after iteration order, and by now I hope you can feel them coming before I say them.

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

The instinct is that drawing costs per pixel, that a big sprite costs more than a small one. On any GPU built this century, at the scales you are working at, filling pixels is very nearly free.

What costs is changing state. Every time you switch texture the pipeline flushes: work already in flight has to finish before the new state can take effect. Six sprites with six textures is six flushes and nobody notices. Six thousand sprites with six thousand textures is six thousand flushes and you have a slideshow, while the GPU itself sits mostly idle, which is why profiling this by watching GPU utilisation will tell you nothing is wrong.

The fix is an atlas. Put the sprites into one texture, sort your draws by texture, submit once.

And pad the atlas. If two sprites touch inside it, bilinear filtering samples across the boundary and you get a one-pixel fringe of the neighbour along the edge. It looks exactly like a rendering bug and it is a packing bug, and you will lose an hour to it if nobody warns you first. Consider yourself warned.

---

# The camera is an inverse

There is no camera object.

**Moving the camera right means moving the world left.**

```js
view = inverse(cameraTransform);   // composed backwards
```

This is the source of most "why is my camera doing that."

NOTES:
Short one, and it removes an entire category of confusion.

There is no camera. The GPU draws what is in front of it at a fixed place. You do not move the viewer, you move everything else in the opposite direction.

So the view transform is the inverse of where you think the camera is. Move the camera right by ten and the world shifts left by ten. Rotate the camera clockwise and the world rotates counter-clockwise.

Almost every camera bug is a missing inverse or a doubled one, and the symptom is that everything moves the wrong way, or the right way at twice the speed. If your camera feels haunted, that is the first place to look.

---

# Draw order is your z-index

![](2d-rendering-draw-order.svg)

NOTES:
Last piece, and it is the tie-break argument again in a fourth costume.

Canvas two-D has no depth buffer. Whatever you draw last is on top. So you sort, usually by layer.

But two sprites on the same layer are tied, and a tie resolved by iteration order is a tie resolved by nothing at all. On screen that shows up as flicker: the two swap places between frames, and which one wins depends on the order the entities happened to get inserted. Across builds it is worse. Two renderers disagree about what the frame even looks like, and your output is now implementation-defined.

Break the tie by id and both problems disappear at the same moment. Read the line at the bottom. The same tie-break that keeps the hash stable is what stops the flicker. That is not a coincidence and it is not two rules. It is one defect, visible in a number in one place and visible to a player in the other.

---

# Before Thursday

- **Find the transform order in your engine.** Is it written down anywhere, or only in code?
- Count your **draw calls** for one frame. Guess first, then measure.
- Read `spec/S04` and `spec/S09` — scene graph and the 2D backend
- `cheatsheet-scene-graph-transforms`, `cheatsheet-2d-rendering`

Thursday, AI: **Hooks** — the only deterministic pillar, and we write the conformance guard live.

NOTES:
Two things, and the first one is the discussion.

Find your transform order and tell me where it is written down. For most of you the honest answer is going to be nowhere, it is just the order the code happens to do it in. That is exactly the condition a specification exists to end, and if you own S04 this is not an exercise, it is your homework.

Then count your draw calls for one frame, and guess first. Write the guess down before you look at the number. Being wrong is the point of it — the size of the gap between what you assumed the machine was doing and what it is actually doing is what Thursday of next week is about.

Thursday is hooks, and it is the one lecture in the AI track that is not about talking to a model at all.
