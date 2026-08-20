---
slug: lecture-w09-space
week: 9
youtube_id: null
companion_sheets:
  - cheatsheet-3d-rendering-webgl
  - cheatsheet-shaders-and-materials
  - cheatsheet-writing-a-spec-agents-can-build
reflection_assignment: devlog-w09
vernacular_tags:
  - "model · view · projection"
  - "depth buffer · z-fighting"
  - "vertex vs fragment stage"
  - "frustum culling"
---

# Week 9 — Space: The 3D Pipeline

## What you'll know after this

After this lecture you will be able to (a) name the four spaces a vertex passes through, (b) explain why `near` is the most consequential number in your projection, (c) state the three conditions transparency requires, and (d) decide whether work belongs in the vertex or fragment stage.

## Outline

1. **One line of 3D** *(8 min)*
   `gl_Position = projection * view * model * vec4(position, 1.0)`. Right to left: place it in the world, express it relative to the camera, apply perspective. Everything else in 3D is refinement on those four matrices.

2. **`near` decides your depth precision** *(6 min)*
   Setting it to `0.001` "just in case" destroys precision across the entire scene and gives you z-fighting everywhere. Push it out as far as your closest visible geometry allows.

3. **The depth buffer sorts for you — except once** *(10 min)*
   Opaque geometry needs no sorting. Transparency needs all three of: drawn after opaque, sorted back to front, and depth **writes off** with testing **on**. Miss the third and glass occludes glass. This is where the day goes.

4. **Two stages, enormous cost difference** *(12 min)*
   A cube has 24 vertices and can cover two million pixels. Work moved from the fragment shader to the vertex shader gets roughly 80,000× cheaper. That is the whole of shader performance intuition.

5. **Normals need their own matrix** *(8 min)*
   Under non-uniform scale, transforming a normal by the model matrix leaves it no longer perpendicular. Inverse transpose of the upper-left 3×3. Symptom: lighting subtly wrong only on stretched objects.

6. **Culling** *(6 min)*
   Back-face culling is free and removes half your triangles. Frustum culling is the one that scales.

7. **The ramp shifts here** *(8 min)*
   From this week you write the spec *and* the vectors for your section, not just the implementation. That is the real skill, and everything before now was scaffolding for it.

## Discuss in class

- **Nothing renders and there is no error.** List every cause you can think of before we go through them. This is the most common 3D experience and the least documented.
- **Where does your engine put per-object lighting work** — vertex or fragment? What would moving it cost, and what would it buy?
- **You now write your own vectors.** What stops a vector you wrote from being a snapshot of your own implementation rather than a claim about behavior?

## Further reading

- [WebGL2 Fundamentals](https://webgl2fundamentals.org/) — the best tutorial series available
- `spec/S10-renderer-3d.md`
- Spector.js — capture one frame and read the real draw calls instead of guessing
