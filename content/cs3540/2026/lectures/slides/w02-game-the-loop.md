---
track: game
week: 2
title: The Loop
subtitle: Fixed Timestep, the Accumulator, and Why 20Hz
runtime: 30
---

NOTES:
Welcome to week two.

Last week we established that a complete, playable game is roughly one prompt away. This week is about the part that is not. The part where you have to know what correct looks like, because the thing writing your code will hand you something that runs, looks fine, and is wrong.

We are going to spend this half hour on four lines of code. That is not a figure of speech. The game loop is four lines. And almost every one of you has already written it wrong, including in the one-prompt game you shipped last week.

So open that build while you watch this. At the end I am going to ask you to find the loop in it.

---

# What you'll know after this

- Why using frame time as your timestep makes a game **unshippable**
- How to write a **fixed-timestep accumulator** with a spiral-of-death clamp
- What the **interpolation alpha** is and where it is allowed to go
- Why the class engine steps at **20Hz** — and why that is a networking decision

NOTES:
Four things. Notice the shape of them: one problem, one fix, one detail people get wrong, and one decision that looks arbitrary until you know what it is for.

The alpha is where implementations that got the first two right still fall apart. And the last one is the one I want you to argue with me about on Thursday.

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
Here it is. This is the loop in essentially every browser game tutorial written in the last fifteen years, and it is the loop your agent writes by default if you do not tell it otherwise.

Read it charitably first, because it is doing something reasonable. It measures how much real time passed since the last frame, and it advances the simulation by that much. If a twentieth of a second went by, move everything a twentieth of a second's worth. That is a physically sensible idea.

The problem is not the idea. The problem is the delta. That number is chosen by the player's hardware, and you have just made it an input to your simulation.

---

# Same code, two machines

- A 144Hz gaming monitor hands you `dt` around **7ms**
- A laptop on battery, thermally throttled, hands you **33ms**
- A tab that was backgrounded hands you **8,000ms**

Same code. Same build. **Different game.**

NOTES:
Here is what that means in practice.

Student A has a nice monitor. Their frame callback fires every seven milliseconds. Student B is on a five-year-old laptop, on battery, with sixteen tabs open, and theirs fires every thirty-three. That is a factor of nearly five between two people running the same build.

The third case is the one nobody plans for. Someone switches to another tab, comes back ninety seconds later, and the browser hands you one enormous delta. Hold on to that number. We come back to it.

The headline is the last line on the slide. Same code, same build, same everything, and it is not the same game. That should bother you.
---

# One build, three machines

![](game-loop-and-time-frame-variance.svg)

NOTES:
Here it is drawn to scale, and the scale is the point.

The green bar at the top is the fast machine, at seven milliseconds. The orange one is the throttled laptop, at thirty-three. The red one is the backgrounded tab, and that is not an exotic case. That is what happens every time somebody checks their email.

Look at the relative widths, and remember what that number actually is. It is the amount your simulation is being asked to advance by, in one go.

The bottom line is the whole lecture in one sentence. The player's hardware picks that number, and the obvious loop hands it straight to your physics.


---

# What actually breaks

## Jump height depends on frame rate

Gravity applied in five big steps and gravity applied in thirty small steps do not integrate to the same curve. Your jump clears the gap on your machine and not on mine.

## Fast bodies tunnel through walls

At `dt` of 33ms a bullet moving 600 units per second travels **20 units** in one step. Your wall is 8 units thick. The bullet was in front of it, then behind it, and never once overlapped it.

NOTES:
Two failure modes, and they fail in different ways.

The first one is smooth. Your jump is a little different on different machines. It is easy to miss, because it does not look like a bug. It looks like the game is slightly floaty sometimes. So you tune the jump on your machine until it feels right, you ship it, and you get a report from somebody whose jump does not clear the first gap in the level.

The second one is a discontinuity, and it is much worse. Do the arithmetic with me. Six hundred units a second, thirty-three milliseconds. That is twenty units of travel in a single step. The wall is eight units thick. At the start of the step the bullet is in front of the wall. At the end of the step the bullet is behind the wall. And there is no moment in between where your collision code could have looked, because there is no in between. There are two endpoints, and neither one overlaps the wall.

So there was no collision to detect. Your collision code is not wrong. It was never asked.

That is tunneling. If you have ever played a game where you occasionally fall through the floor, you have watched this exact bug from the outside.
---

# Tunneling, to scale

![](game-loop-and-time-tunneling.svg)

NOTES:
I want to show you this one properly, because there is a correction buried in it.

The bullet is at the left at the start of the step and at the right at the end. The wall is in between. Neither sample overlaps it, so your collision code was never asked a question it could have answered wrong. It simply never saw the wall.

Now read the bottom panel, because I have been slightly sloppy up to now and this is where I fix it. A fixed timestep does not eliminate tunneling. Our step is fifty milliseconds, and at six hundred units a second that is thirty units of travel. Which is worse than the thirty-three millisecond case I just showed you.

What a fixed timestep buys you is that it tunnels the same way every time, on every machine. That turns an unreproducible ghost into a bug with a test case.

The actual fix is swept collision. You test the path the object travelled instead of the two endpoints, and that is week seven.

So hold the distinction. A fixed timestep is not a collision fix. It is what makes a collision fix possible.


---

# The real cost

Three things this course requires, all dead on arrival:

- **Replay** — you cannot re-run what you cannot reproduce
- **Lockstep multiplayer** — two peers on different hardware diverge instantly
- **Conformance testing** — no stable hash, nothing to grade against

The simulation now depends on hardware. Everything downstream of determinism is gone.

NOTES:
Now here is why this gets a whole lecture instead of a bullet point.

We could survive slightly wrong jump heights. Plenty of shipped games have them. What we cannot survive is the sentence at the bottom of the slide: the simulation now depends on hardware.

Everything this course does technically stands on one property. Run the same simulation twice, get the same answer. Replays are free if you have that and impossible if you do not. Lockstep multiplayer, which is how your games get networking in week thirteen, assumes every peer computes an identical world from identical inputs. And your spec sections get graded by building them independently and comparing state hashes, which requires that a state hash mean something.

One line of code takes all three off the table. Not degrades them. Takes them off the table.

That is why this is the second thing we teach and not the twentieth.

---

# The fix: two clocks, not one

**Separate when the simulation advances from when you draw.**

- The simulation advances in **fixed, identical steps** — always the same size
- Rendering happens whenever the display is ready — as often as it likes

Real time drives rendering. It does **not** drive simulation.

NOTES:
Here is the whole idea. Everything after this slide is bookkeeping.

You have been treating these as one thing. A frame happens, so you advance the world and you draw it. Split them apart.

The simulation advances in steps that are always exactly the same size. Fifty milliseconds, every time, no exceptions, regardless of what the hardware is doing. Rendering happens whenever the browser gives you a frame.

Those two rates now have nothing to do with each other. On a fast machine you might render three times between simulation steps. On a slow one you might take two simulation steps between renders. Both are fine. Both produce the identical simulation.

Real time still exists. It decides how often you draw, and it decides when it is time to take another step. It just never gets to decide how big a step is.

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
This is the whole thing. Read it slowly, because every line is doing a job.

The constant at the top is your step size. Fifty milliseconds, and it never changes for the life of the program.

Then the accumulator. You take however much real time passed since the last frame, and you pour it into a bucket. You do not use it. You do not pass it anywhere. It goes in the bucket.

Then the while loop. While the bucket holds at least one full step's worth of time, you take a step and you remove exactly that much time from the bucket. Work three examples. Eighty milliseconds accumulated, and your step is fifty: you take one step, and thirty milliseconds stay in the bucket for next time. A hundred and twenty accumulated: two steps, and twenty milliseconds stay. Forty accumulated: no steps at all, and all forty stay.

Nothing is ever thrown away. Time that is not yet enough to spend is not lost. It waits. That is the entire trick, and it is what lets the irregular thing at the top feed a perfectly regular thing at the bottom.

And whatever is left in the bucket when the loop ends gets handed to the renderer. That is the next slide.

---

# `tick()` takes no time argument

That is not an omission. **That is the point.**

- If `tick()` accepted `dt`, hardware would be back inside your simulation
- A step is always `STEP` — the function does not need to be told
- Nothing inside the simulation can ask what time it is

> Any function that can see wall-clock time can make your game non-deterministic.

NOTES:
Stop on this one, because this is the part people undo by accident.

Look at the signature. Tick, with no parameters. Every tutorial version of this function takes a delta. Ours does not, and that is deliberate.

If tick accepted a time argument, then somewhere down in your physics code somebody would multiply by it. Hardware timing would be back inside the simulation and we would have accomplished nothing. By not passing it, you make that mistake unavailable. The step size is a constant the simulation already knows. There is nothing to pass.

The quote at the bottom generalises it, and we do this properly next week. Anything inside tick that can observe wall-clock time is a leak. Not just the delta. The system clock. A performance counter. Anything at all that can read the wall. If the simulation can tell what time it is in the real world, then two runs of the same inputs can disagree.

This is also the easiest thing in the whole subject to check in a code review. Look at the signature. If there is a parameter sitting there, ask why.

---

# The accumulator, drawn

![](game-loop-and-time-accumulator.svg)

NOTES:
Here is the same mechanism as a picture. This diagram is on the cheat sheet for the week, so you do not need to copy it down.

Follow the top track. Real time arrives in irregular chunks, because that is what hardware does. Follow the middle track. The accumulator fills and drains. Follow the bottom track. The simulation steps, and every step is exactly the same width. Always.

That regularity at the bottom is the thing you are buying. The irregularity at the top is the price, and the accumulator is what absorbs it on your behalf.

Notice there are frames where the bottom track does nothing at all, because not enough time accumulated to take a step. And there are frames where it steps twice. Both are normal. Neither one is a bug, and neither one needs a special case in your code.

---

# The leftover is the alpha

`acc / STEP` is a number between 0 and 1 — how far you are **between** two simulation steps.

- Hand it to the renderer so it can interpolate positions and draw smoothly
- The renderer uses it to **lie about where things are**, convincingly
- It goes **one direction only** — into rendering, never back into simulation

Without it, a 20Hz simulation looks like a 20Hz simulation. With it, it looks smooth.

NOTES:
Now the leftover. This is the piece people skip, and skipping it is why some of you will implement everything above this correctly and then conclude that fixed timestep looks terrible.

Start with the problem. Your simulation steps twenty times a second. If you draw whatever the last step produced, your game visually updates twenty times a second, and it looks choppy, because it is choppy.

But you know something extra. The accumulator tells you how far along you are toward the next step. Divide the leftover by the step size and you get a number between zero and one. If the bucket holds half a step, you are halfway between the last state and the next one.

So draw each object halfway between where it was and where it is going. The result looks smooth at whatever rate the display runs, while the simulation underneath is still plodding along at twenty steps a second.

The renderer is lying about where things are. That is allowed. That is its job.

The last bullet is the rule that keeps the lie safe. Alpha goes into rendering and never comes back. Nothing the renderer computes with it may touch simulation state. The moment an interpolated position flows back into tick, frame timing is inside your simulation again, through a side door, and everything you just built is undone.
---

# What the alpha actually draws

![](game-loop-and-time-alpha.svg)

NOTES:
Here is the thing itself.

The two blue circles are simulation states. Real ones, the output of two consecutive ticks. Those are the only positions your simulation ever computed.

The green circle in the middle is what you put on the screen. Read the caption under it. It exists in no simulation state. There is no tick where the object was there. You invented it, out of the two real states and the leftover time.

Sit with that, because it is the first time in this course that the thing on screen is deliberately not the thing in the simulation. It will not be the last. Week eight is an entire lecture about lying to the player convincingly.

The rule that makes it safe is the bold line at the bottom, and it is the same rule every time. The lie flows outward. Never back.


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

Somebody alt-tabs. The frame callback stops firing while the tab is hidden. Ninety seconds later they come back, and the browser hands you one enormous delta. Eight thousand milliseconds, say.

Walk the loop by hand. Eight seconds in the bucket, fifty milliseconds a step, so a hundred and sixty steps. Those hundred and sixty steps are not free. Say they take four hundred milliseconds of real time to compute.

Now here is the turn. That four hundred milliseconds is itself real time that passed. So it goes into the accumulator on the next frame, which means more steps than a normal frame needs, which takes longer, which accumulates more time.

If your simulation is cheap, you climb back out. If it is expensive, you do not. The tab locks up and stays locked up.

That is the spiral of death. It is not a hypothetical. It is the single most common way a correct-looking accumulator dies in the wild.
---

# The loop that eats itself

![](game-loop-and-time-spiral.svg)

NOTES:
Drawn as a cycle, which is what it actually is.

Go around it once. A stalled tab hands you eight seconds. The while loop runs a hundred and sixty ticks. Those ticks take four hundred milliseconds of real time. That four hundred milliseconds is real time, so it lands in the accumulator on the next frame, which means more ticks, which takes longer.

There is no exit from that cycle. Each trip around makes the next trip worse. That is what makes it a spiral rather than one bad frame.

The green box is the only thing that opens it: a ceiling on how much time you will accept in a single frame. Notice what it does and does not do. It does not make the loop faster. It cuts the arrow.


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
The fix is one line, and I want to be careful about how I justify it, because just clamp it sounds like giving up.

You cap how much time you are willing to accept in a single frame. A quarter of a second is a reasonable ceiling. Anything past that, you throw away.

And yes, that means simulated time and wall-clock time have now diverged. The game believes less time passed than actually did. People find that upsetting the first time they hear it, so let me defend it.

Ask what you would be simulating. The player was in another tab. They gave no input. You would be running ninety seconds of an empty world so that one number matches another number. And the alternative, the faithful one, is a game that locks up and never comes back.

This is a real trade with a clear winner. Dropping simulated time is a decision. Falling permanently behind is a failure. Take the decision.

One caveat. In lockstep multiplayer you cannot make this choice on your own, because your peers did not drop the same time you did. That is week thirteen's problem. For single player, clamp.

---

# Why 20Hz

The class engine steps at **50ms**. Not because it looks better.

- Lockstep multiplayer sends **20 command batches per second**, not 60
- Three times less traffic, three times fewer chances to stall a peer
- The interpolation alpha is what makes 20Hz look like 60

**A rendering decision, made for a networking reason, three months early.**

NOTES:
Last idea, and it is the one I want pushback on.

Fifty milliseconds is a slow step. Most engines you have used run their fixed step at sixty hertz, or a hundred and twenty. We picked twenty. Twenty is unusual.

The reason has nothing to do with rendering. In week thirteen your games get multiplayer, and the model is lockstep. Every peer sends its inputs for a step, everyone waits until they have everyone else's, then everyone steps together. So the step rate is also the network rate. At sixty hertz you are sending sixty batches a second to every peer and waiting on sixty round trips. At twenty, you send twenty.

Three times less traffic. And, more importantly, three times fewer opportunities for one slow peer to stall everybody else.

We can afford twenty visually precisely because of the alpha. Twenty steps a second with interpolation looks smooth. Without interpolation it looks like a slideshow. Those two decisions are locked together.

Now the sentence at the bottom of the slide is the actual lesson, and it is bigger than the game loop. We made a decision in week two about a constraint that does not arrive until week thirteen. Had we not made it now, we would be rewriting the loop in November. That is what specification work buys you.

It is also a decision you could reasonably argue was premature. Bring that argument to class.
---

# Twenty against sixty

![](game-loop-and-time-20hz.svg)

NOTES:
And here is that argument in one picture.

The top row is sixty hertz. Sixty command batches a second, and every one of those marks is a message sent to every peer and a round trip somebody has to wait on. The bottom row is twenty.

Count what you are buying. Three times less traffic, yes. But read the caption again, because that is the part that matters. Every mark is also a synchronisation point, a moment where the whole game waits for the slowest person in it. At sixty hertz you have sixty of those every second. At twenty you have twenty.

That is the real argument for twenty, and it has almost nothing to do with rendering. Which is why we could only make it by knowing in August what week thirteen was going to need.


---

# Before Thursday

- **Open your one-prompt game.** Find the loop. Did it use a fixed step?
- If not — **what breaks first?** Jump height, tunneling, or the backgrounded tab?
- Read `spec/S01-time-and-loop.md` and its conformance vector
- Fiedler, *Fix Your Timestep!* — the canonical article, still the best one

Thursday's AI lecture: **CLAUDE.md** — and Forge 01 is due Sep 7.

NOTES:
Three things before Thursday.

First and most important, open the game you shipped last week and find the loop. I am fairly confident about what most of you will find, because I ran the same experiment. Look for a fixed step. If there is not one, work out which of the three failure modes bites you first: jump height, tunneling, or the backgrounded tab. We are opening class with this, so come with an answer rather than an intention to look.

Second, read section one of the class spec. That is the normative version of everything in this lecture, and it is the version your engine gets built from and graded against. Notice how much shorter it is than this lecture. Notice also that it carries a conformance vector: a seed, a set of commands, a tick count, and an expected hash. That vector is what turns prose into something checkable.

Third, Fiedler's article. It is from two thousand four and it is still the clearest thing anybody has written on this.

Thursday we switch tracks. That one is CLAUDE.md, and it is the one you need before Forge 01 is due on the seventh.
