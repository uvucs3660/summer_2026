---
track: game
week: 9
title: Space
subtitle: Four Matrices, Two Stages, and the Three Rules of Transparency
runtime: 22
---

NOTES:
Week nine, game track. The 3D pipeline.

Here is what happens to nearly everyone the first time they go to three dimensions. The scene comes up, and it is wrong. Surfaces flicker against each other. Glass vanishes behind other glass. The lighting is fine everywhere except on the one object you stretched. So you go looking for the bug in your code, because that is where bugs live.

There is no bug in your code. Every one of those is a setting. One number, one line of state, one matrix used where a different matrix was required. They are configuration failures dressed up as rendering failures.

So this lecture is four matrices and a small number of settings that are catastrophic when they are wrong, arranged in roughly the order they will bite you.

There is no class Thursday — fall break, the fifteenth through the eighteenth. So this one stands alone.

---

# What you'll know after this

- The **one line** that is all of 3D
- Why `near` decides your depth precision — and `far` barely matters
- The **three rules of transparency**, all of which are required
- Why moving work from the fragment shader to the vertex shader is ~80,000× cheaper

NOTES:
Four things. The middle two are the ones that each cost an afternoon if nobody tells you, so they get the most time today. The last one is the whole of shader performance intuition compressed into a single ratio. Memorise the number.

---

# One line of 3D

```glsl
gl_Position = projection * view * model * vec4(position, 1.0);
```

Right to left:

- `model` — place it in the world
- `view` — express that relative to the camera *(still an inverse — week 6)*
- `projection` — apply perspective

**Everything else in 3D is refinement on those four matrices.**

NOTES:
Here is all of it. One line.

Read it right to left, because that is the order the multiplication actually applies. You start with a vertex in the model's own space, sitting near the origin the way the artist built it. The model matrix places it in the world. The view matrix re-expresses that position relative to the camera, and it is still an inverse, exactly as in week six, because there is still no such thing as a camera object. You move the world instead. Then the projection matrix applies perspective, which is the step that makes distant things small.

That is the pipeline. Everything else you will ever read about in three dimensions — skeletal animation, instancing, shadow mapping — is a refinement of how one of those four things gets computed. Learn this line and you can open any 3D tutorial at any page and know where you are standing.

---

# `near` is the whole game

![](3d-rendering-webgl-near-plane.svg)

NOTES:
First setting, and everybody gets it wrong in the same direction, which is how you know it is the instinct and not carelessness.

The instinct is to set near very small. A thousandth. Then nothing close to the camera is ever clipped, and clipping is visible and ugly, so this feels like the cautious choice. It is the single most destructive number in your renderer.

Depth precision is not spread evenly through the view. Almost all of it sits close to the near plane. So when you set near to a thousandth, you have spent the majority of your depth buffer resolving the first few centimetres in front of the camera, and every other surface in the scene divides up whatever is left. The result is z-fighting at every distance — surfaces flickering against each other as the camera moves — and it looks exactly like a driver bug. It is not a driver bug.

Push near out as far as your nearest visible geometry allows. If the camera never gets closer than half a unit to anything, near is half a unit.

And read the bottom line, because it surprises people. Far barely matters. Precision is set by the ratio, and near sits in the denominator. Doubling far costs you almost nothing. Halving near costs you a lot.

---

# The three rules of transparency

![](3d-rendering-webgl-transparency.svg)

NOTES:
Opaque geometry needs no sorting at all. The depth buffer handles it, and handling it is most of what a depth buffer is for.

Transparency is the exception, and it needs all three of these. Not two of them. Three.

One: transparent geometry is drawn after all the opaque geometry, so the opaque surfaces behind it are already in the buffer to blend against.

Two: transparent surfaces are sorted back to front among themselves, because blending is order-dependent in a way opaque drawing is not. Two panes blended in the wrong order give you a different colour, not a rounding error.

And three, which is the one that eats the day: depth writes off, depth testing on. A transparent pane should still be hidden by a wall in front of it, so the testing stays on. But it must not write depth. If it writes depth, the first pane of glass stamps a value into the buffer and the second pane fails the test against it. Glass occludes glass.

That symptom — transparent things disappearing behind other transparent things — is one line of state. Every person who writes a renderer loses an afternoon to it exactly once. Consider this your afternoon back.

---

# Two stages, 80,000× apart

A cube has **24 vertices** and can cover **two million pixels.**

- Vertex shader runs once per vertex
- Fragment shader runs once per **pixel**

Move work from the fragment shader to the vertex shader and it gets roughly **80,000× cheaper.**

That ratio is the whole of shader performance intuition.

NOTES:
The cost model. Very simple, once the two numbers are next to each other.

A cube has twenty-four vertices. That same cube, filling the screen at a decent resolution, covers around two million pixels. The vertex shader runs once per vertex. The fragment shader runs once per pixel. Both of them are ordinary-looking code in the same language, and one of them runs eighty thousand times more often than the other.

So the optimisation move for shaders is nearly always the same move. Compute it in the vertex shader, hand it across as a varying, and let the hardware interpolate it on the way. Lighting terms, texture coordinate arithmetic, anything that varies smoothly across a surface.

The exception is anything that has to be evaluated per pixel to look right. A sharp specular highlight. Normal mapping. Those genuinely belong in the fragment shader, and that is what the budget is for.

But when something is slow and the geometry is simple, you already know the answer. You are doing arithmetic two million times that you could have done twenty-four times.

---

# Two more, quickly

**Normals need their own matrix.** Under non-uniform scale, transforming a normal by the model matrix leaves it no longer perpendicular. Use the **inverse transpose of the upper-left 3×3.**
*Symptom: lighting subtly wrong, but only on stretched objects.*

**Culling.** Back-face culling is free and removes half your triangles. **Frustum culling is the one that scales.**

NOTES:
Two smaller things, and each one costs an afternoon if nobody tells you.

Normals. Scale an object non-uniformly — stretch it along one axis — then transform its normals by the model matrix, and they come out no longer perpendicular to the surface they belong to. The lighting is then subtly wrong, and only on the stretched objects, which is what makes it maddening. Most of the scene looks correct, so you go hunting in the lighting code, and the lighting code is fine. The fix is the inverse transpose of the upper-left three-by-three. You do not need to derive it today. You need to use it.

Culling. Back-face culling is one line and it removes roughly half your triangles for nothing, because you cannot see the back faces of a closed solid. Turn it on and stop thinking about it.

Frustum culling — not drawing what is outside the camera's view at all — is the one that actually scales. It is the difference between drawing your level and drawing the part of your level anybody can see, and those two numbers stop resembling each other the moment the level gets big.

---

# The ramp shifts here

From this week: you write the **spec and the vectors** for your section, not just an implementation.

- Everything before now was scaffolding for this
- **Spec Section · Conformance Vectors** — due **Sun Oct 12**
- **Game Technique Talks** begin, weeks 9–16

> Fall break: no class Thu Oct 15. Nothing is due over the break.

NOTES:
And a change of gear, which is the real reason this slide exists.

Up to now you have mostly been implementing against specifications somebody else wrote. Mine, for the core sections. From this week the balance flips. You write the specification, you write the vectors that prove it, and something else does the implementing.

That is the actual skill this course is about. Everything before now — the loop, determinism, the patterns, the transforms — was scaffolding, so that when you arrived here you would have something worth specifying. It is very hard to write a good spec for a system you have never had to debug.

Your conformance vectors are due October twelfth.

And the Game Technique Talks start now and run to the end of term, each of you teaching the section you own. That is the same idea from the other side: if you cannot teach the section, you do not own it yet.

Fall break is the fifteenth to the eighteenth. Nothing is due over it.

---

# Before we come back

- **Set `near` correctly** in whatever 3D you have. Measure the z-fighting before and after.
- If you have transparency, check all **three** rules. You are probably missing the third.
- **Ship your conformance vectors** by Sun Oct 12
- `cheatsheet-3d-rendering-webgl`, `cheatsheet-shaders-and-materials`

Back Tuesday Oct 20: **Minds** — pathfinding and game AI. Then **Spec → Plan → Execution.**

NOTES:
Three things.

Fix your near plane and look at the difference. If you have z-fighting today, this will very likely remove all of it, and it is a one-character change. Measure it before and after, because otherwise you will not believe how much of the problem was one number.

Check your transparency against all three rules. I will bet on the third one being the one you are missing, because it is the only one that is a piece of state rather than a piece of ordering, and state is easy to not notice.

And ship the vectors by the twelfth. That is the deliverable that turns your section from prose into something a machine can check, and it is the half almost everyone underestimates. Writing a claim takes ten minutes. Writing the vector that proves the claim takes an hour — and it is that hour where you find out what your claim actually said.
