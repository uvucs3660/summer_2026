#!/usr/bin/env python3
"""Generate pages/course-schedule.md from course.yaml.

The schedule is derived, never hand-written. A hand-written one drifts from
the actual due dates within a week, and the drift is invisible until a
student misses a deadline that the page said was later.

Usage: scripts/gen_schedule.py <content-dir>   (writes the page)
       scripts/gen_schedule.py <content-dir> --check   (exit 1 if stale)
"""
import datetime as dt, pathlib, re, sys, collections

MEET = {  # Tue/Thu meetings, and the three holiday losses
    1: ["Thu Aug 20"], 2: ["Tue Aug 25", "Thu Aug 27"], 3: ["Tue Sep 01", "Thu Sep 03"],
    4: ["Tue Sep 08"], 5: ["Tue Sep 15", "Thu Sep 17"], 6: ["Tue Sep 22", "Thu Sep 24"],
    7: ["Tue Sep 29", "Thu Oct 01"], 8: ["Tue Oct 06", "Thu Oct 08"], 9: ["Tue Oct 13"],
    10: ["Tue Oct 20", "Thu Oct 22"], 11: ["Tue Oct 27", "Thu Oct 29"],
    12: ["Tue Nov 03", "Thu Nov 05"], 13: ["Tue Nov 10", "Thu Nov 12"],
    14: ["Tue Nov 17", "Thu Nov 19"], 15: [], 16: ["Tue Dec 01", "Thu Dec 03"],
}
NOTE = {
    4: "**Thu Sep 10 — no class.** Campus Closure: A Day for Healing, Service, and Connection.",
    9: "**Thu Oct 15 — no class.** Fall Break, Oct 15–18.",
    11: "**Tue Oct 27** is the last day to withdraw from a full-semester course.",
    15: "**No class all week.** Thanksgiving Break, Nov 23–29. Nothing is due; capstone work continues.",
}
ACT = {1: "Act I · The Baseline", 4: "Act II · The Spec", 10: "Act III · The Studio"}
TOPIC = {
    1: "First Contact — what a game costs now", 2: "The Loop and the 11 Pillars",
    3: "Determinism and the Command Model", 4: "Writing a Spec an Agent Can Build",
    5: "Patterns and the Component Store", 6: "Pixels — Transforms and 2D Rendering",
    7: "Contact — Collision, Budgets, Profiling", 8: "Feel — Juice, MDA, Playtesting",
    9: "Space — The 3D Pipeline", 10: "Minds — Pathfinding and Game AI",
    11: "Worlds — Procedural Generation and Sound", 12: "Story — Narrative and Local Models",
    13: "Distance — Netcode and Peer-to-Peer", 14: "Soul — Governance and Security",
    15: "", 16: "Boss Fight — polish, playtest, ship",
}

def to_local(d):
    """course.yaml stores UTC. Display and week assignment both use Mountain
    Time, or a Friday 23:59 deadline shows up as Saturday."""
    return d - dt.timedelta(hours=6 if d.month < 11 else 7)

def week_of(local):
    start = dt.date(2026, 8, 17)          # Monday of week 1
    return max(1, min(16, ((local.date() - start).days // 7) + 1))

def main():
    content = pathlib.Path(sys.argv[1])
    check = "--check" in sys.argv
    y = (content / "course.yaml").read_text()

    items = collections.defaultdict(list)
    for m in re.finditer(
        r'- slug: ([\w-]+)\n    title: "([^"]+)"\n(?:.*?\n)*?    due_at: "([^"]+)"', y):
        slug, title, iso = m.groups()
        local = to_local(dt.datetime.fromisoformat(iso))
        items[week_of(local)].append((local, title))

    out = ["# Course Schedule", "",
           "Generated from the course definition — the dates here are the dates Canvas enforces.",
           "", "All deadlines are **23:59 Mountain Time**. Lateness is measured by the *commit*",
           "timestamp in git, not by when you paste the link into Canvas.", ""]
    for w in range(1, 17):
        if w in ACT:
            out += [f"## {ACT[w]}", ""]
        meets = " · ".join(MEET[w]) or "—"
        out += [f"### Week {w:02d} — {TOPIC[w]}" if TOPIC[w] else f"### Week {w:02d}", "",
                f"**Meets:** {meets}", ""]
        if w in NOTE:
            out += [f"> {NOTE[w]}", ""]
        due = sorted(items.get(w, []))
        if due:
            out += ["| Due | Assignment |", "|---|---|"]
            out += [f"| {d.strftime('%a %b %d')} | {t} |" for d, t in due]
            out += [""]
    out += ["## Finals week — Dec 7–11", "",
            "**The Showcase**, in your assigned final exam slot. Games run, people play them,",
            "you answer questions. Bring a build that works without the campus network.", ""]
    text = "\n".join(out)

    page = content / "pages" / "course-schedule.md"
    if check:
        current = page.read_text() if page.exists() else ""
        if current != text:
            print(f"STALE: {page} does not match course.yaml — run scripts/gen_schedule.py")
            sys.exit(1)
        print("schedule is current")
    else:
        page.write_text(text)
        print(f"wrote {page} ({len(due_weeks := [w for w in items])} weeks with deadlines)")

main()
