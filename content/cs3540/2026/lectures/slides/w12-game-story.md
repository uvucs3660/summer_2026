---
track: game
week: 12
title: Story
subtitle: Told, Shown, Played — and a Language Model Inside 16 Milliseconds
runtime: 24
---

NOTES:
Week twelve, game track, and this one contains the hardest engineering constraint in the course.

Two halves. The first is narrative design, which is almost entirely a question of where you spend your effort — and the answer is not where instinct sends you. The second half is putting a language model inside a frame budget. It sounds impossible. It is not, because the seam it needs already exists: you built it in week three, for a completely different reason.

One framing before we start. Everything in the first half is a cost argument, not a taste argument. Which way of telling a story costs the most per unit of story delivered, and which one costs you almost nothing because you were building it anyway.
---

# What you'll know after this

- The three modes — **told, shown, played** — and where to spend a single term
- What **ludonarrative dissonance** is, and which side players believe
- Why you **bottleneck** instead of branching
- How a 2,000ms model fits inside a 16.6ms budget

NOTES:
Four things. The third saves the most work — it is the difference between finishing your narrative and abandoning it in November. The fourth is the one that makes the S sixteen section of the spec make sense.
---

# Told, shown, played

**Told** — cutscenes, dialogue, text. Precise, expensive, and it **stops the player from playing** — the one thing your medium does that no other can.

**Shown** — the environment itself. Two skeletons and a locked door. Rides on level layout you were building anyway.

**Played** — what your systems make happen. **The story players actually retell.**

> For one term, spend almost everything on **shown.**

NOTES:
Three ways a game tells a story, and they have wildly different cost structures. That is the whole slide. Cost.

Told is what everyone reaches for, because it is how every other medium works. It is precise — you can say exactly the thing. It is expensive: writing, revision, voice, and art behind all of it. And it carries a cost that belongs to games alone. During a cutscene the player is not playing. You have paused the one thing your medium does that a film cannot, in order to do the thing film is better at.

Shown is the environment doing the work. Two skeletons and a locked door. A player walks in, reads it in about a second, and assembles a story you never wrote — and it cost you the level geometry you were already placing. That ratio is the entire reason it is the recommendation.

Played is what your systems produce. The near miss, the improvised solution, the plan that went wrong interestingly. It is what people actually retell afterwards, and you cannot author it. You can only build systems whose failures are interesting and then get out of the way.

So for one term, spend almost everything on shown. Not because told is bad, but because told is the only one of the three whose cost scales with how much story you want.
---

# Players believe the mechanics

**Ludonarrative dissonance** — the story says one thing, the mechanics say another.

- The story says you are a reluctant pacifist
- The mechanics award experience points for kills

Players believe the mechanics. It is what they **did**, not what the game **claimed**.

NOTES:
Short one, and it is a check you can run over your own design in five minutes.

The classic shape: a narrative about a reluctant hero who hates violence, wrapped around a system that pays out experience points for kills.

Players resolve that contradiction instantly, without noticing they did it, and they always resolve it the same way. They believe the mechanics. What the game rewarded is what the game was about. What the text claimed is set dressing.

So here is the check. Write down what you want your game to be about. Then open your scoring code and read what it actually pays for. If your game says exploration matters and rewards only combat, it is a combat game with exploration-flavoured text, and no amount of dialogue repairs it — because dialogue is not what anybody did.
---

# Bottleneck instead of branch

![](storytelling-in-games-bottleneck.svg)

NOTES:
Now the structural advice, and it is the one that most changes how much you finish.

Four binary choices is sixteen endings. That arithmetic is what kills student narrative projects, because sixteen endings means sixteen times the writing, and the writing you have to spend is fixed — so each ending gets a sixteenth of it. They are all thin. And any given player sees exactly one of them, and concludes from that one that you cannot write.

The alternative is on the right. Let the choices diverge, then bring them back together. Remember what happened as state — two flags — and let the state change details rather than structure. A different line in act two. An ally present or not. A door already open because of something you did in act one.

The counterintuitive part is the last line: this feels more responsive, not less. And here is why. The details land continuously, all the way through, instead of arriving once at an ending that no player ever compares against another. Two flags and one act you wrote well beat four branches you did not.
---

# Dialogue as data

Not code. **Data.**

- Editable without a rebuild
- Translatable
- Testable
- A chosen line enters the simulation as a **command** — which is what keeps a conversation replayable

NOTES:
A quick structural note that pays off four separate ways, and the fourth is the one specific to this course.

Put your dialogue in a data file, not in code. Then you can edit it without a rebuild, which is the difference between iterating on your writing and shipping your first draft of it. It can be translated. It can be tested — you can walk every node automatically and find the dead ends before a player does.

And the fourth. When a player picks a line, that choice enters the simulation as a command, exactly like a key press. Which means the conversation is in the command log, so the conversation replays, so dialogue state is inside the hash, so a divergence in a conversation is detectable like every other divergence.

Dialogue held in code is dialogue outside the command log, and therefore outside every guarantee the rest of this course gives you.
---

# Never await in the tick

![](local-llm-in-games-never-await.svg)

NOTES:
And here is the constraint.

You have sixteen point six milliseconds per frame. A model takes five hundred to three thousand. That is two orders of magnitude. It is not a tuning problem: there is no faster model that closes it and no machine you can buy that closes it. The gap is structural.

Look at the left. If you await inside the tick, the frame never finishes. Meanwhile real time keeps going, so the accumulator fills. On the next frame you have two seconds of backlog to simulate, which takes longer than a frame, so more backlog arrives while you simulate it. That is the spiral of death from week two, reached from a completely different direction.

The right side is the answer, and notice how ordinary it is. Fire the request. Keep ticking. Two seconds later the reply arrives, and you append it to the command log like any other input, at the tick it arrived on.

And the line at the bottom is the point. You did not need a new mechanism for this. The seam already existed — it is the same one a remote peer's input arrives through, and you built it in week three for netcode. A slow language model and a distant human are the same shape of problem: an input that is authoritative and late. The command log solved both before either of them had come up.
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
Second half of making a small model usable, and this one is measurable.

Ask a three-billion-parameter model for a line of dialogue as prose and you get something rambling, out of character, and occasionally about a subject nobody raised. Ask the same model for a small object — one line, one emotion from a fixed list, one action from a fixed list — and it complies, at a dramatically higher rate.

Nothing about the model changed. You collapsed the output space. Free prose has enormous room to be wrong in. Three fields, two of them drawn from a short list, has almost none.

Then validate the result against your enums before you act on it, and this is not defensive programming for its own sake. A player can type into a conversation with a non-player character, so player-authored text reaches your model, and whatever comes back is on its way into your game logic. A validated enum makes it impossible for the action field to be something you did not design. We do that properly in week fourteen. For now, notice that the enum is doing security work as well as quality work, and that it costs one line.
---

# The fallback is the deliverable

![](local-llm-in-games-fallback.svg)

NOTES:
And the last piece, which is the one graded hardest.

There is a conformance vector that kills every provider — no cloud, no local model, nothing answering — and then checks that your game still runs.

Read the standard on the bottom line carefully, because it is stricter than it sounds. Not fails gracefully. Not shows an error. It keeps playing, using authored lines, and it tells the player that is what is happening. Three requirements, and the third is the one people miss.

Design that path first and everything downstream gets easier, because the model call becomes an enhancement rather than a dependency, and an enhancement is something you are allowed to cut. Design it last and you will be building it at midnight before the Showcase, on campus wifi, discovering that your game is a menu.

And that is not a hypothetical. Your Showcase note says it in as many words: bring a build that works without the campus network.
---

# Before Thursday

- **Where is your story?** Told, shown, or played? Move one thing from told to shown.
- Check for **dissonance** — does your reward structure agree with your text?
- If you use a model: **kill the network and play your game.** What happens?
- `cheatsheet-storytelling-in-games`, `cheatsheet-local-llm-in-games`

Thursday, AI: **The Council.** Forge 08 due **Sun Nov 16.**

NOTES:
Three things, and the third is the one to do tonight.

Turn off your network and play your own game. Not read the code — play it. Most of you will find something between a hang and a crash, and finding that tonight instead of in December is the entire point of the exercise.

The first one is a five-minute design exercise with a real payoff. Take one thing you were going to tell the player and find a way to show it instead. One thing. If it works you will do the rest without being asked.

Thursday is the Council, and Forge 08 is due on the sixteenth.