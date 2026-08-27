---
track: game
week: 9
title: Space
subtitle: Four Matrices, Two Stages, and the Three Rules of Transparency
runtime: 22
---

NOTES:
Week nine, game track. The 3D pipeline.

This lecture is mostly four matrices and a small number of settings that are catastrophic if wrong. It is unusually dense in "things that look like a rendering bug and are actually a configuration bug," and I have arranged it in roughly the order those will bite you.

There is no class Thursday — fall break, the fifteenth through the eighteenth. So this one stands alone.

---

# What you'll know after this

- The **one line** that is all of 3D
- Why `near` decides your depth precision — and `far` barely matters
- The **three rules of transparency**, all of which are required
- Why moving work from the fragment shader to the vertex shader is ~80,000× cheaper

NOTES:
Four things. The last one is the whole of shader performance intuition in a single ratio, and it is worth memorising the number.

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
Here is all of it.

Read right to left, the way the multiplication actually applies. Start with a vertex in the model's own space. The model matrix places it in the world. The view matrix re-expresses that relative to the camera — and it is still an inverse, exactly as in week six, because there is still no camera object. The projection matrix applies perspective.

That is the pipeline. Every technique you will read about — skeletal animation, instancing, shadow mapping — is a refinement of how one of those four things gets computed. If you understand this line you can read any 3D tutorial and know where you are.

---

# `near` is the whole game

![](3d-rendering-webgl-near-plane.svg)

NOTES:
First setting, and it is the one everybody gets wrong in the same direction.

The instinct is to set `near` very small — a thousandth — so nothing ever gets clipped. It feels safe. It is the single most destructive number in your renderer.

Depth precision is distributed non-linearly. Almost all of it sits close to the near plane. Set near to a thousandth and you have spent most of your depth buffer on the first few centimetres in front of the camera, and everything beyond that shares whatever is left. You get z-fighting everywhere — surfaces flickering against each other at all distances — and it looks like a driver bug.

Push near out as far as your nearest visible geometry allows. If the camera never gets closer than half a unit to anything, near is half a unit.

And read the bottom line: `far` barely matters. It is the ratio that sets precision, and near is in the denominator. Doubling far costs you almost nothing. Halving near costs you a lot.

---

# The three rules of transparency

![](3d-rendering-webgl-transparency.svg)

NOTES:
Opaque geometry needs no sorting at all — the depth buffer handles it, and that is most of what a depth buffer is for.

Transparency is the exception, and it needs all three of these. Not two.

One: drawn after all opaque geometry. Two: sorted back to front among themselves, because blending is order-dependent in a way opaque drawing is not.

And three, which is the one that eats the day: depth writes off, depth testing on. Transparent surfaces should still be *hidden by* things in front of them — so testing stays on. But they must not *write* depth, because if they do, the first pane of glass writes a depth value and the second pane fails the test against it. Glass occludes glass.

That symptom — transparent things disappearing behind other transparent things — is one line of state, and every person who writes a renderer loses an afternoon to it exactly once. Consider this your afternoon back.

---

# Two stages, 80,000× apart

A cube has **24 vertices** and can cover **two million pixels.**

- Vertex shader runs once per vertex
- Fragment shader runs once per **pixel**

Move work from the fragment shader to the vertex shader and it gets roughly **80,000× cheaper.**

That ratio is the whole of shader performance intuition.

NOTES:
The cost model, and it is very simple once you see the numbers side by side.

A cube has twenty-four vertices. Fullscreen at a decent resolution is around two million pixels. Both shaders look like ordinary code and one of them runs eighty thousand times more often.

So the optimisation strategy for shaders is almost always the same move: compute it in the vertex shader, pass it as a varying, and let the hardware interpolate. Lighting terms, texture coordinate maths, anything that varies smoothly across a surface.

The exception is anything that must be evaluated per pixel to look right — sharp specular highlights, normal mapping. Those genuinely need the fragment shader, and that is what your budget is for.

But if you are ever unsure why something is slow and the geometry is simple, the answer is almost always that you are doing arithmetic two million times that you could have done twenty-four times.

---

# Two more, quickly

**Normals need their own matrix.** Under non-uniform scale, transforming a normal by the model matrix leaves it no longer perpendicular. Use the **inverse transpose of the upper-left 3×3.**
*Symptom: lighting subtly wrong, but only on stretched objects.*

**Culling.** Back-face culling is free and removes half your triangles. **Frustum culling is the one that scales.**

NOTES:
Two smaller things that each cost an afternoon if nobody tells you.

Normals. If you scale an object non-uniformly — stretch it on one axis — and transform its normals by the model matrix, they come out no longer perpendicular to the surface. The lighting is then subtly wrong, and only on stretched objects, which makes it maddening to track down because most of your scene looks fine. The fix is the inverse transpose of the upper-left three-by-three. Do not derive it; just use it.

Culling. Back-face culling is one line and removes roughly half your triangles for free, because you cannot see the back of a closed solid. Turn it on.

Frustum culling — not drawing what is outside the camera's view — is the one that actually scales, because it is the difference between drawing your level and drawing the part of your level anyone can see.

---

# The ramp shifts here

From this week: you write the **spec and the vectors** for your section, not just an implementation.

- Everything before now was scaffolding for this
- **Spec Section · Conformance Vectors** — due **Sun Oct 12**
- **Game Technique Talks** begin, weeks 9–16

> Fall break: no class Thu Oct 15. Nothing is due over the break.

NOTES:
And a change of gear, which is the real reason this slide exists.

Up to now you have mostly been implementing against specifications other people wrote — mine, for the core sections. From this week the balance flips: you write the specification and the vectors that prove it, and something else implements it.

That is the actual skill this course is about, and everything before now — the loop, determinism, patterns, transforms — was scaffolding so you would have something worth specifying.

Your conformance vectors are due October twelfth. And the Game Technique Talks start now and run to the end of term, each of you teaching the section you own.

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

Fix your near plane and look at the difference. If you have z-fighting today, this will likely remove it entirely, and it is a one-character change.

Check your transparency against all three rules — I will bet on the third being missing.

And ship the vectors by the twelfth. That is the deliverable that turns your section from prose into something checkable, and it is the half that most people underestimate. Writing a claim takes ten minutes. Writing the vector that proves the claim takes an hour, and it is the hour where you discover what your claim actually said.
