---
track: game
week: 2
title: The Loop
subtitle: Fixed Timestep, the Accumulator, and Why 20Hz
runtime: 30
---

NOTES:
Welcome to week two.

Last week we established that a complete, playable game is roughly one prompt away. This week we start on the part that is not — the part where you have to know what correct looks like, because the thing writing the code will happily hand you something that runs, looks fine, and is wrong.

We are going to spend this half hour on four lines of code. That is not an exaggeration. The game loop is four lines, and almost every one of you has already written it wrong, including in the one-prompt game you shipped last week. I want you to open that build while you watch this, because at the end I am going to ask you to find the loop in it.

---

# What you'll know after this

- Why using frame time as your timestep makes a game **unshippable**
- How to write a **fixed-timestep accumulator** with a spiral-of-death clamp
- What the **interpolation alpha** is and where it is allowed to go
- Why the class engine steps at **20Hz** — and why that is a networking decision

NOTES:
Four things. Note the shape of them: one problem, one fix, one detail people get wrong, and one decision that looks arbitrary until you know what it is for.

The third one — the interpolation alpha — is where most implementations that get the first two right still fall apart. And the fourth is the one I want you to argue with me about in class on Thursday.

---

# The obvious loop

```js
function frame(now) {
  const dt = (now - last) / 1000;
  last = now;
  update(dt);
  render();
  requestAnimationFrame(frame);
}
```

Every tutorial you have ever read. It runs. It looks correct.

NOTES:
Here it is. This is the loop in essentially every browser game tutorial written in the last fifteen years, and it is the loop your agent will write for you by default if you do not say otherwise.

Read it charitably. It is doing something reasonable — it measures how much real time passed since the last frame, and it advances the simulation by that much. That is a physically sensible idea. If a twentieth of a second went by, move everything a twentieth of a second's worth.

The problem is not the idea. The problem is that `dt` is a number the player's hardware chooses, and you just made it an input to your simulation.

---

# Same code, two machines

- A 144Hz gaming monitor hands you `dt` around **7ms**
- A laptop on battery, thermally throttled, hands you **33ms**
- A tab that was backgrounded hands you **8,000ms**

Same code. Same build. **Different game.**

NOTES:
Here is what that means in practice.

Student A has a nice monitor. Their frame callback fires every seven milliseconds. Student B is on a five-year-old laptop running on battery with sixteen Chrome tabs open, and theirs fires every thirty-three. That is a factor of nearly five.

And the third case is the one nobody plans for. Someone switches to another tab, comes back ninety seconds later, and the browser hands you one enormous delta. We will come back to that number, because it is the one that kills you.

The headline is the last line. This is the same code, the same build, the same everything — and it is not the same game. That should bother you.
---

# One build, three machines

![](game-loop-and-time-frame-variance.svg)

NOTES:
Here it is drawn to scale, and the scale is the point.

The green bar at the top is the fast machine — seven milliseconds. The orange one is the throttled laptop at thirty-three. And the red one is the backgrounded tab, which is not an exotic case; it is what happens every time somebody checks their email.

Look at the relative widths and remember that the number in that bar is what your simulation is being asked to advance by, in one go. The bottom line is the whole lecture in one sentence: the player's hardware picks that number, and the obvious loop hands it straight to your physics.


---

# What actually breaks

## Jump height depends on frame rate

Gravity applied in five big steps and gravity applied in thirty small steps do not integrate to the same curve. Your jump clears the gap on your machine and not on mine.

## Fast bodies tunnel through walls

At `dt` of 33ms a bullet moving 600 units per second travels **20 units** in one step. Your wall is 8 units thick. The bullet was in front of it, then behind it, and never once overlapped it.

NOTES:
Two failure modes, and they are qualitatively different.

The first is a smooth error. Your jump is a little different on different machines. It is easy to miss, because it looks like the game is just slightly floaty sometimes. You will tune the jump on your machine until it feels right, ship it, and get a bug report from someone whose jump does not clear the first gap in the level.

The second is a discontinuity, and it is much worse. Do the arithmetic on the slide. Six hundred units a second, thirty-three milliseconds — that is twenty units of travel in a single step. If your wall is eight units thick, then at the end of the step the bullet is on the far side, and at no point in your collision code did the bullet and the wall ever overlap. There was no collision to detect. The bullet went through a solid wall, and your collision code is not even wrong — it was never asked.

That is tunneling. It is the classic symptom, and if you have ever played a game where you occasionally fall through the floor, you have watched this exact bug from the outside.
---

# Tunneling, to scale

![](game-loop-and-time-tunneling.svg)

NOTES:
I want to show you this one properly, because there is a correction buried in it.

The bullet is at the left at the start of the step and at the right at the end. The wall is in between. At neither sample was there an overlap, so your collision code was never asked a question it could have answered wrong — it simply never saw the wall.

Now read the bottom panel, because I have been slightly sloppy up to now and this is where I fix it. **A fixed timestep does not eliminate tunneling.** Our step is fifty milliseconds, which at six hundred units a second is thirty units of travel — that is worse than the thirty-three millisecond case I just showed you.

What a fixed timestep buys you is that it tunnels *the same way every time, on every machine*. That converts an unreproducible ghost into a bug with a test case. The actual fix is swept collision — you test the path the object travelled, not the two endpoints — and that is week seven.

So: fixed timestep is not a collision fix. It is what makes a collision fix possible.


---

# The real cost

Three things this course requires, all dead on arrival:

- **Replay** — you cannot re-run what you cannot reproduce
- **Lockstep multiplayer** — two peers on different hardware diverge instantly
- **Conformance testing** — no stable hash, nothing to grade against

The simulation now depends on hardware. Everything downstream of determinism is gone.

NOTES:
Now here is why I am spending a whole lecture on this instead of one slide.

We could survive slightly wrong jump heights. Plenty of shipped games have them. What we cannot survive is the sentence at the bottom: the simulation now depends on hardware.

Every single thing this course does technically rests on being able to run the same simulation twice and get the same answer. Replays are free if you have that and impossible if you do not. Lockstep multiplayer — which is how your games will do networking in week thirteen — assumes every peer computes the identical world from the identical inputs. And your spec sections get graded by building them independently and comparing state hashes, which requires that a state hash mean something.

Frame-time-as-timestep takes all three off the table in one line of code. That is why this is the second thing we teach and not the twentieth.

---

# The fix: two clocks, not one

**Separate when the simulation advances from when you draw.**

- The simulation advances in **fixed, identical steps** — always the same size
- Rendering happens whenever the display is ready — as often as it likes

Real time drives rendering. It does **not** drive simulation.

NOTES:
Here is the whole idea, and everything else is bookkeeping.

You have been treating these as one thing: a frame happens, so advance the world and draw it. Split them. The simulation advances in steps that are always exactly the same size — fifty milliseconds, every time, no exceptions, regardless of what the hardware is doing. Rendering happens whenever the browser gives you a frame.

Those two rates have nothing to do with each other. On a fast machine you might render three times between simulation steps. On a slow one you might take two simulation steps between renders. Both are fine. Both produce the identical simulation.

Real time still exists — it decides how often you draw, and it decides when it is time to take another step. It just never gets to decide how *big* a step is.

---

# The accumulator

```js
const STEP = 0.05;          // 50ms — always
let acc = 0;

function frame(now) {
  acc += (now - last) / 1000;
  last = now;

  while (acc >= STEP) {
    tick();                 // no argument
    acc -= STEP;
  }

  render(acc / STEP);       // leftover → alpha
  requestAnimationFrame(frame);
}
```

NOTES:
This is the whole thing. Read it slowly.

You take however much real time passed and you pour it into a bucket — the accumulator. You do not use it directly. It just goes in the bucket.

Then, while the bucket holds at least one full step's worth of time, you take a step and remove that much from the bucket. If eighty milliseconds accumulated and your step is fifty, you take one step and thirty milliseconds stay in the bucket for next time. If a hundred and twenty accumulated, you take two steps and twenty milliseconds stay.

The time never gets lost. It stays in the bucket until there is enough of it to spend. That is the entire trick.

And then whatever is left over gets handed to the renderer, which we will get to in a moment.

---

# `tick()` takes no time argument

That is not an omission. **That is the point.**

- If `tick()` accepted `dt`, hardware would be back inside your simulation
- A step is always `STEP` — the function does not need to be told
- Nothing inside the simulation can ask what time it is

> Any function that can see wall-clock time can make your game non-deterministic.

NOTES:
I want to stop on this, because it is the part people undo by accident.

Look at the signature. `tick()`. No parameters. Every tutorial version of this function takes a delta, and ours does not, and that is deliberate.

If `tick` accepted a time argument, then somewhere down in your physics code someone would multiply by it, and hardware timing would be back inside the simulation, and we would have accomplished nothing. By not passing it, you make the mistake unavailable. The step size is a constant that the simulation knows at compile time. There is nothing to pass.

The quote at the bottom generalizes it, and we will hit this again next week when we do determinism properly: anything inside `tick` that can observe wall-clock time is a leak. Not just `dt` — `Date.now`, performance counters, anything. If the simulation can tell what time it is in the real world, it can behave differently on different runs.

This is also, incidentally, the single easiest thing to check in a code review. Look at the signature. If there is a parameter there, ask why.

---

# The accumulator, drawn

![](game-loop-and-time-accumulator.svg)

NOTES:
Here is the same thing as a picture. This diagram is on the cheat sheet for this week, so you do not need to copy it down.

Follow the top track: real time arrives in irregular chunks, because that is what hardware does. Follow the middle: the accumulator fills and drains. Follow the bottom: the simulation steps, and every step is exactly the same width. Always. That regularity at the bottom is the thing we are buying, and the irregularity at the top is the price the accumulator absorbs on your behalf.

Notice there are frames where the bottom track does nothing at all — not enough time accumulated, so no step. And there are frames where it steps twice. Both are normal. Neither one is a bug.

---

# The leftover is the alpha

`acc / STEP` is a number between 0 and 1 — how far you are **between** two simulation steps.

- Hand it to the renderer so it can interpolate positions and draw smoothly
- The renderer uses it to **lie about where things are**, convincingly
- It goes **one direction only** — into rendering, never back into simulation

Without it, a 20Hz simulation looks like a 20Hz simulation. With it, it looks smooth.

NOTES:
Now the leftover. This is the piece people skip, and skipping it is why some of you will implement everything above correctly and conclude that fixed timestep looks terrible.

If your simulation steps twenty times a second and you just draw whatever the last step produced, your game visually updates twenty times a second. It will look choppy, because it is.

But you know something extra: the accumulator tells you how far along you are toward the next step. If it holds half a step, you are halfway between the last state and the next one. So you draw each object halfway between where it was and where it is going. The result looks completely smooth at whatever rate your display runs, even though the simulation underneath is still plodding along at twenty steps a second.

The renderer is lying. That is allowed. That is its job. The last bullet is the rule that keeps the lie safe: alpha goes into rendering and never comes back. Nothing the renderer computes with it is ever allowed to touch simulation state. The moment interpolated positions flow back into `tick`, you have put frame timing back into the simulation through the side door, and everything we just did is undone.
---

# What the alpha actually draws

![](game-loop-and-time-alpha.svg)

NOTES:
Here is the thing itself.

The two blue circles are simulation states — real ones, the output of two consecutive ticks. Those are the only positions your simulation ever computed.

The green circle in the middle is what you put on screen. Read the caption under it: it exists in no simulation state. There is no tick where the object was there. You invented it, from the two real states and the leftover time.

That is worth sitting with, because it is the first time in this course that the thing on screen is deliberately not the thing in the simulation. It will not be the last — week eight is an entire lecture about lying to the player convincingly. The rule that makes it safe is the bold line at the bottom, and it is the same rule every time: the lie flows outward, never back.


---

# The spiral of death

A backgrounded tab hands you **8,000ms**.

```
acc = 8.0                → 160 steps
160 steps take 400ms     → next frame's dt is now huge
                         → even more steps
                         → the tab never recovers
```

The `while` loop is unbounded. That is a bug waiting for a slow machine.

NOTES:
Here is the failure case I promised you.

Someone alt-tabs. `requestAnimationFrame` stops firing while the tab is hidden. Ninety seconds later they come back, and the browser hands you one enormous delta — eight thousand milliseconds, say.

Walk the loop. Eight seconds in the bucket, fifty milliseconds a step, so a hundred and sixty steps. Those hundred and sixty steps do not happen instantly; say they take four hundred milliseconds of real time. But that four hundred milliseconds is itself real time that passed, so it goes into the accumulator on the next frame, which means more steps than a normal frame needs, which takes longer, which accumulates more time.

If your simulation is cheap you climb out of this. If it is expensive, you do not. The tab locks up and stays locked up. That is the spiral of death, and it is not a hypothetical — it is the single most common way a correct-looking accumulator implementation dies in the wild.
---

# The loop that eats itself

![](game-loop-and-time-spiral.svg)

NOTES:
Drawn as a cycle, which is what it is.

Go around it once. A stalled tab hands you eight seconds. The while loop runs a hundred and sixty ticks. Those ticks take four hundred milliseconds of real time — and that four hundred milliseconds is real time, so it lands in the accumulator on the next frame, which means more ticks, which takes longer.

There is no exit from that cycle. Each trip around makes the next trip worse. That is what makes it a spiral rather than a bad frame.

The green box is the only thing that opens the loop: a ceiling on how much time you will accept in one frame. It does not make the loop faster. It cuts the arrow.


---

# Clamping is correct

```js
acc += Math.min((now - last) / 1000, MAX_FRAME);   // e.g. 0.25
```

**Dropping simulated time is correct behavior.** Falling permanently behind is not.

- The player alt-tabbed. There was no input. Nothing happened.
- Simulating those 90 seconds faithfully serves nobody
- A game that never recovers serves nobody **worse**

NOTES:
The fix is one line, and I want to be careful about how I justify it, because "just clamp it" sounds like giving up.

You cap how much time you are willing to accept in a single frame. A quarter second is a reasonable ceiling. Anything beyond that, you throw away.

And yes — that means simulated time and wall-clock time have now diverged. The game thinks less time passed than actually did. People find that upsetting the first time they hear it, so let me defend it.

Ask what you would be simulating. The player was in another tab. They gave no input. There is nothing meaningful to compute — you would be running ninety seconds of an empty world so that a number matches a number. Meanwhile the alternative, the honest one, is a game that locks up and never comes back.

So this is a real trade and it has a clear winner. Dropping simulated time is a decision. Falling permanently behind is a failure. Choose the decision.

One caveat worth knowing: in lockstep multiplayer you cannot make this choice unilaterally, because your peers did not drop the same time you did. We will deal with that in week thirteen. For single player, clamp.

---

# Why 20Hz

The class engine steps at **50ms**. Not because it looks better.

- Lockstep multiplayer sends **20 command batches per second**, not 60
- Three times less traffic, three times fewer chances to stall a peer
- The interpolation alpha is what makes 20Hz look like 60

**A rendering decision, made for a networking reason, three months early.**

NOTES:
Last idea, and it is the one I want pushback on.

Fifty milliseconds is a slow step. Most engines you have used run their fixed step at sixty hertz or a hundred and twenty. We picked twenty. Twenty is unusual.

The reason has nothing to do with rendering. In week thirteen your games get multiplayer, and the model is lockstep — every peer sends its inputs for a step, everyone waits until they have everyone's, then everyone steps. The step rate is therefore also the network rate. At sixty hertz you are sending sixty batches a second to every peer and waiting on sixty round trips. At twenty, you are sending twenty. That is three times less traffic and, more importantly, three times fewer opportunities for one slow peer to stall everybody.

And we can afford it visually precisely because of the alpha. Twenty steps a second with interpolation looks smooth. Without interpolation it would look like a slideshow, which is why those two decisions are locked together.

Now — the sentence at the bottom is the actual lesson, and it is bigger than the game loop. We made a decision in week two, about a constraint that does not arrive until week thirteen, and if we had not made it now we would be rewriting the loop in November. That is what specification work buys you.

It is also a decision you could reasonably argue was premature. Bring that argument to class.
---

# Twenty against sixty

![](game-loop-and-time-20hz.svg)

NOTES:
And here is the argument in one picture.

The top row is sixty hertz — sixty command batches a second, and every one of those marks is a message sent to every peer and a round trip somebody has to wait for. The bottom row is twenty.

Count what you are buying. Three times less traffic, yes. But look at the caption again: every mark is also a synchronisation point, a moment where the whole game waits for the slowest person in it. At sixty hertz you have sixty of those every second. At twenty you have twenty.

That is the real argument for twenty, and it has almost nothing to do with rendering — which is why we could only make it by knowing in August what week thirteen was going to need.


---

# Before Thursday

- **Open your one-prompt game.** Find the loop. Did it use a fixed step?
- If not — **what breaks first?** Jump height, tunneling, or the backgrounded tab?
- Read `spec/S01-time-and-loop.md` and its conformance vector
- Fiedler, *Fix Your Timestep!* — the canonical article, still the best one

Thursday's AI lecture: **CLAUDE.md** — and Forge 01 is due Sep 7.

NOTES:
Three things before Thursday.

First and most important: open the game you shipped last week and find the loop. I am fairly confident about what most of you will find, because I ran the same experiment. Look at whether there is a fixed step in there, and if there is not, work out which of the three failure modes would bite you first. We are opening class with this, so come with an answer rather than an intention to look.

Second, read section one of the class spec. That is the normative version of everything in this lecture — the part your engine gets built from and graded against. Notice how much shorter it is than this lecture, and notice that it has a conformance vector attached: a seed, a set of commands, a tick count, and an expected hash. That vector is what makes the prose checkable.

Third, Fiedler's article. It is from 2004 and it is still the clearest thing written on this.

Thursday we switch tracks — that one is CLAUDE.md, and it is the one you need before Forge 01 is due on the seventh.
