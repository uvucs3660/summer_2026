---
slug: lecture-w06-pixels
week: 6
youtube_id: null
companion_sheets:
  - cheatsheet-scene-graph-transforms
  - cheatsheet-2d-rendering
  - cheatsheet-cc-hooks
reflection_assignment: devlog-w06
vernacular_tags:
  - "local vs world transform"
  - "texture atlas · draw call batching"
  - "frustum culling"
  - "Claude Code: hook · exit 2 blocks"
---

# Week 6 — Pixels: Transforms and 2D Rendering

## What you'll know after this

After this lecture you will be able to (a) explain why a child stores its offset rather than its position, (b) say what a draw call costs and how to reduce them, (c) implement a camera as an inverse transform, and (d) write a `PreToolUse` hook and watch it block.

## Outline

1. **Local, not world** *(10 min)*
   A turret is "12 units in front of the ship," never "at (340, 122)." Rotate the ship and the turret follows, because its stored position never described the world. The moment you assign a world position to a child, the hierarchy stops working and you are updating every part by hand.

2. **Multiplication order** *(8 min)*
   `Translate × Rotate × Scale`, applied right to left. Swap rotate and translate and the object **orbits the origin** instead of spinning in place. Same numbers, completely different picture — and exactly the kind of unpinned choice two builds will differ on. Write it into your section.

3. **The cost is draw calls, not pixels** *(10 min)*
   Each texture swap flushes the GPU pipeline. Six sprites is fine; six thousand unbatched is a slideshow. One atlas, sorted by texture, one submission. Pad the atlas — bilinear filtering samples the neighbour and gives you a one-pixel fringe otherwise.

4. **The camera is an inverse** *(6 min)*
   There is no camera object. Moving it right means moving the world left. Composed backwards, which is the source of most "why is my camera doing that."

5. **Draw order is your z-index** *(6 min)*
   Canvas 2D has no depth buffer, so sort. And break ties by id — without it two sprites on the same layer can swap between frames and flicker, and two implementations can disagree.

6. **Hooks: the only deterministic pillar** *(14 min)*
   Everything else in Claude Code is a request to a model. A hook is a shell script with an exit code, and exit `2` **cancels the tool call** and hands your stderr back as the reason. We will write the conformance guard live and watch it block — because a guard you have only ever seen allow has not been shown to guard.

## Discuss in class

- **Bring a hook you wrote.** We will try to get around it. If we can, it was a request, not a guard.
- **Where should the interpolation alpha live?** Your sim runs at 20Hz and you draw at 144. Trace exactly where alpha enters and confirm it never returns.
- **Batching is an optimization that changes your architecture.** Sorting by texture means draw order is no longer submission order. What does that break, and how do you specify around it?

## Further reading

- `spec/S04-transform-hierarchy.md` and `spec/S09-renderer-2d.md`
- [MDN Canvas API](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API)
- `cheatsheet-cc-hooks` — including the guard we build in §6
