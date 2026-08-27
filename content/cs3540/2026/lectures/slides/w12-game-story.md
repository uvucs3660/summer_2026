---
track: game
week: 12
title: Story
subtitle: Told, Shown, Played — and a Language Model Inside 16 Milliseconds
runtime: 24
---

NOTES:
Week twelve, game track, and this is the one with the course's hardest engineering constraint in it.

The first half is narrative design, which is mostly about spending your effort in the right place. The second half is putting a language model inside a frame budget, which sounds impossible and is a seam you already built in week three.

---

# What you'll know after this

- The three modes — **told, shown, played** — and where to spend a single term
- What **ludonarrative dissonance** is, and which side players believe
- Why you **bottleneck** instead of branching
- How a 2,000ms model fits inside a 16.6ms budget

NOTES:
Four things. The third is the one that saves the most work; the fourth is the one that makes your S16 section make sense.

---

# Told, shown, played

**Told** — cutscenes, dialogue, text. Precise, expensive, and it **stops the player from playing** — the one thing your medium does that no other can.

**Shown** — the environment itself. Two skeletons and a locked door. Rides on level layout you were building anyway.

**Played** — what your systems make happen. **The story players actually retell.**

> For one term, spend almost everything on **shown.**

NOTES:
Three ways a game tells a story, and they have wildly different cost structures.

Told is the one everyone reaches for, because it is how every other medium works. It is precise — you can say exactly the thing. It is expensive: writing, and voice, and time. And it has a cost unique to games, which is that during a cutscene the player is not playing. You have paused the only thing your medium does that a film cannot.

Shown is environmental. Two skeletons and a locked door tell a complete story and cost you the level geometry you were already building. The ratio here is extraordinary and it is why it is the recommendation.

Played is what emerges from your systems — the near-death, the improvised solution, the thing that went wrong. It is what people actually retell afterwards, and you cannot author it directly. You can only build systems that make good stories likely.

The recommendation for a single semester is the quote. Shown has by far the best return, because it is nearly free if your level design is doing its job anyway.

---

# Players believe the mechanics

**Ludonarrative dissonance** — the story says one thing, the mechanics say another.

- The story says you are a reluctant pacifist
- The mechanics award experience points for kills

Players believe the mechanics. It is what they **did**, not what the game **claimed**.

NOTES:
Short one, and it is a good check to run over your own design.

The classic shape: a narrative about a reluctant hero who hates violence, wrapped around a system that rewards violence with progression.

Players resolve that conflict instantly and unconsciously, and they always resolve it the same way: they believe the mechanics. What the game rewarded is what the game is about. What the text claimed is set dressing.

So if there is something you want your game to be about, check whether the reward structure agrees. If your game says exploration matters and rewards only combat, then it is a combat game with exploration-flavoured text — and no amount of dialogue fixes that, because dialogue is not what anyone did.

---

# Bottleneck instead of branch

![](storytelling-in-games-bottleneck.svg)

NOTES:
Now the structural advice, and it is the one that most changes how much you get done.

Four binary choices is sixteen endings. That is the arithmetic that kills student narrative projects, because sixteen endings means sixteen times the writing and each one gets a sixteenth of the effort. They are all bad, and any given player sees exactly one of them and concludes your writing is bad.

The alternative is on the right. Let choices diverge and then bring them back together. Remember what happened as *state* — two flags — and let that state change details rather than structure. A different line. An ally present or not. A door that is open because of something you did in act one.

The counterintuitive part is the last line: this feels *more* responsive, not less. Because the details land continuously, throughout, instead of all at once in an ending most players never compare with any other. Two flags and one well-written act beat four badly-written branches every time.

---

# Dialogue as data

Not code. **Data.**

- Editable without a rebuild
- Translatable
- Testable
- A chosen line enters the simulation as a **command** — which is what keeps a conversation replayable

NOTES:
Quick structural note that pays off in three ways.

Put dialogue in a data file, not in code. You can edit it without rebuilding, which means you will actually iterate on it. It can be translated. It can be tested — you can walk every node and check for dead ends automatically.

And the fourth one is the course-specific reason. When a player chooses a line, that choice enters the simulation as a command, like any other input. Which means a conversation is replayable, and a conversation is part of the state hash, and a divergence in dialogue state is detectable like any other.

Dialogue as code is dialogue outside the command log, and therefore outside everything the rest of this course gives you.

---

# Never await in the tick

![](local-llm-in-games-never-await.svg)

NOTES:
And here is the constraint.

You have sixteen point six milliseconds per frame. A model takes five hundred to three thousand. That gap is two orders of magnitude — it is not something you tune your way out of, and there is no faster model that closes it.

Look at the left. If you await inside the tick, the frame never finishes. Real time keeps passing, so the accumulator fills up, and on the next frame you have several seconds of backlog — which is the spiral of death from week two, arriving from a completely different direction.

The right side is the answer, and notice how ordinary it is. Fire the request. Keep ticking. When the reply arrives two seconds later, append it to the command log like any other input.

And the line at the bottom is the point I want to land. You did not need a new mechanism for this. The seam already existed — it is the same one a remote peer's input arrives through, built in week three. A slow language model and a distant human are the same shape of problem, and the command log solved both before either had come up.

---

# Constrain the output

A 3B model asked for **prose** wanders.

The same model asked for this **complies**:

```json
{ "line": "...", "emotion": "angry", "action": "attack" }
```

`emotion` and `action` are **enums.** Validate against them before acting.

That validation is also your **injection defence** — week 14.

NOTES:
Second half of making a small model usable.

Ask a three-billion-parameter model for a line of dialogue and you get something rambling, out of character, and occasionally about something else entirely. The same model asked for a small JSON object with an enum for emotion and an enum for action will comply, and the compliance rate is dramatically higher.

The reason is that you have collapsed the output space. Free prose has enormous room to go wrong. Three fields, two of them from a fixed list, has almost none.

And validate the result against your enums before acting on it. That is not defensive programming for its own sake — a player can type into an NPC conversation, so player-authored text reaches your model, and a validated enum is what stops "action" ever being something you did not design. We do that properly in week fourteen; for now, note that the enum is doing security work as well as quality work.

---

# The fallback is the deliverable

![](local-llm-in-games-fallback.svg)

NOTES:
And the last piece, which is the one that gets graded hardest.

There is a conformance vector that kills every provider — no cloud, no local model, nothing — and checks that your game still runs.

Read the standard on the bottom line carefully, because it is stricter than it sounds. Not "fails gracefully." Not "shows an error." It keeps playing, using authored lines, and it tells the player that is what is happening.

Design that path first and everything gets easier, because the cloud call becomes an enhancement rather than a dependency. Design it last and you will be building it at midnight before the Showcase, on campus wifi, discovering that your game is a menu.

And that is not hypothetical — your Showcase note says it explicitly: bring a build that works without the campus network.

---

# Before Thursday

- **Where is your story?** Told, shown, or played? Move one thing from told to shown.
- Check for **dissonance** — does your reward structure agree with your text?
- If you use a model: **kill the network and play your game.** What happens?
- `cheatsheet-storytelling-in-games`, `cheatsheet-local-llm-in-games`

Thursday, AI: **The Council.** Forge 08 due **Sun Nov 16.**

NOTES:
Three things, and the third one is the one to do tonight.

Turn off your network and play your own game. Not read the code — play it. Most of you will find something between a hang and a crash, and finding that now instead of in December is the entire point of the exercise.

The first one is a five-minute design exercise with a real payoff: take one thing you were going to tell the player and find a way to show it instead.

Thursday is the Council, and Forge 08 is due on the sixteenth.
