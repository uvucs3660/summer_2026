#!/usr/bin/env python3
"""Authoring kit for CS 3540 lecture diagrams.

Diagrams are shared: they render into the deck AND onto the Canvas cheat-sheet
page, so they are written straight into cheatsheets/diagrams/. This module
exists so the palette is defined once — it matches the diagrams that shipped
with the cheat sheets, which is why decks can use that dark background.

Two rules the existing artwork got wrong and this kit guards against:
  * text must clear its panel's bottom edge by a descender (see fit_panel)
  * the font has no ∝ ↯ ⇢ glyphs — they render as tofu boxes (see check_glyphs)
"""
import subprocess
import tempfile
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent.parent / "cheatsheets" / "diagrams"

STYLE = """  <style>
    .panel { fill: #0b1220; stroke: #374151; stroke-width: 1.2; rx: 10; ry: 10; }
    .node  { fill: #1f2937; stroke: #60a5fa; stroke-width: 1.4; rx: 8; ry: 8; }
    .good  { fill: #064e3b; stroke: #34d399; stroke-width: 1.5; rx: 8; ry: 8; }
    .warn  { fill: #7c2d12; stroke: #fb923c; stroke-width: 1.5; rx: 8; ry: 8; }
    .bad   { fill: #7f1d1d; stroke: #f87171; stroke-width: 1.5; rx: 8; ry: 8; }
    .h     { fill: #fcd34d; font-weight: 700; }
    .label { fill: #f9fafb; font-weight: 700; }
    .body  { fill: #d1d5db; font-size: 12px; }
    .mute  { fill: #9ca3af; font-size: 11px; }
    .code  { font-family: ui-monospace, Menlo, monospace; fill: #93c5fd; font-size: 11px; }
    .arrow { stroke: #9ca3af; stroke-width: 1.6; fill: none; marker-end: url(#tri); }
    .warrow{ stroke: #fb923c; stroke-width: 1.8; fill: none; marker-end: url(#tri-w); }
  </style>
  <defs>
    <marker id="tri" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#9ca3af" />
    </marker>
    <marker id="tri-w" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="#fb923c" />
    </marker>
  </defs>"""

TOFU = "∝↯⇢⟶∀∃⊕⊗≜⌀▲▼◆✓✗"
W = 780  # every cheat-sheet diagram is 780 wide


def esc(t):
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


class Diagram:
    def __init__(self, name, title, height):
        self.name, self.height = name, height
        self.parts = []
        self.panels = []   # (x, y, w, h) for the fit checks
        self.light = []    # near-white text, which needs a dark panel behind it
        self.widths = []   # (x, y, anchor, chars, size) for the overflow estimate
        self.texts = []    # (x, y, anchor) baselines for the fit check
        if title:
            self.text(20, 24, title, "h", size=15)

    # ---- primitives ----
    def raw(self, s):
        self.parts.append(s)

    def panel(self, x, y, w, h, cls="panel"):
        self.parts.append(f'<rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}" />')
        self.panels.append((x, y, w, h))

    def box(self, x, y, w, h, cls="node"):
        self.parts.append(f'<rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}" />')
        self.panels.append((x, y, w, h))   # boxes are dark too, so they back text as well

    def text(self, x, y, t, cls="body", size=None, anchor=None, raw=False):
        a = f' text-anchor="{anchor}"' if anchor else ""
        s = f' font-size="{size}"' if size else ""
        self.parts.append(f'<text x="{x}" y="{y}" class="{cls}"{a}{s}>{t if raw else esc(t)}</text>')
        self.texts.append((x, y, anchor))
        self.widths.append((x, y, anchor, len(t), size or 13))
        if cls in ("label", "body", "code"):
            self.light.append((x, y, cls))

    def lines(self, x, y, items, cls="body", step=19, anchor=None, raw=False):
        """A run of text lines; returns the y after the last one."""
        for i, t in enumerate(items):
            self.text(x, y + i * step, t, cls, anchor=anchor, raw=raw)
        return y + (len(items) - 1) * step

    def line(self, x1, y1, x2, y2, stroke="#4b5563", width=1.2):
        self.parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{width}" />')

    def arrow(self, d, cls="arrow"):
        self.parts.append(f'<path class="{cls}" d="{d}" />')

    def circle(self, cx, cy, r, fill, stroke=None, width=1.8):
        st = f' stroke="{stroke}" stroke-width="{width}"' if stroke else ""
        self.parts.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"{st} />')

    # ---- checks ----
    @staticmethod
    def _spans(tx, anchor, px, pw):
        """Is a text at tx horizontally within [px, px+pw]? Anchored text runs left."""
        if anchor == "middle":
            return px - 4 <= tx <= px + pw + 4
        if anchor == "end":
            return px - 4 <= tx <= px + pw + 4
        return px - 4 <= tx <= px + pw

    def _verify(self, svg):
        bad = {c for c in svg if c in TOFU}
        if bad:
            raise ValueError(f"{self.name}: font lacks glyph(s) {''.join(sorted(bad))}")
        if self.texts:
            low = max(t[1] for t in self.texts)
            if low > self.height - 6:
                raise ValueError(f"{self.name}: text baseline {low} overflows height {self.height}")
        for px, py, pw, ph in self.panels:
            bottom = py + ph
            inside = [ty for tx, ty, anc in self.texts
                      if py < ty <= bottom + 4 and self._spans(tx, anc, px, pw)]
            if inside and max(inside) > bottom - 6:
                raise ValueError(
                    f"{self.name}: text baseline {max(inside)} clipped by "
                    f"box x={px} w={pw} ending at y={bottom}"
                )
        # Near-white text outside every panel is invisible on the white Canvas
        # cheat-sheet page, even though it looks correct on a dark slide.
        for tx, ty, cls in self.light:
            if not any(px <= tx <= px + pw and py <= ty <= py + ph
                       for px, py, pw, ph in self.panels):
                raise ValueError(
                    f"{self.name}: .{cls} text at ({tx},{ty}) sits on no panel — "
                    f"invisible on the white cheat-sheet page. Use .h/.mute or add a panel."
                )

    def _check_widths(self):
        """Flag text that visibly overruns its container.

        Width is estimated at 0.52em per character — close enough for the
        sans stack at these sizes. The 1.06 slack keeps the estimate from
        firing on text that merely reaches the edge.
        """
        for tx, ty, anchor, chars, size in self.widths:
            w = chars * size * 0.52
            left = tx - w / 2 if anchor == "middle" else (tx - w if anchor == "end" else tx)
            right = left + w
            holders = [(px, pw) for px, py, pw, ph in self.panels
                       if py <= ty <= py + ph and px - 4 <= left <= px + pw + 4]
            if not holders:
                continue
            px, pw = min(holders, key=lambda h: h[1])       # the tightest container
            if right > px + pw * 1.06:
                raise ValueError(
                    f"{self.name}: text of {chars} chars at ({tx},{ty}) reaches "
                    f"~{right:.0f}, past its container edge at {px + pw}"
                )

    def save(self):
        # Full-bleed dark background. Without it the diagram renders as floating
        # panels on Canvas's white page, where the amber title sits at ~1.4:1
        # contrast and light captions vanish entirely.
        bg = (f'<rect class="bg" x="0" y="0" width="{W}" height="{self.height}" '
              f'fill="#0b1220" rx="12" ry="12" />')
        self.panels.append((0, 0, W, self.height))
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {self.height}" '
               f'font-family="ui-sans-serif, system-ui, sans-serif" font-size="13">\n'
               + STYLE + "\n  " + bg + "\n"
               + "\n".join("  " + p for p in self.parts) + "\n</svg>\n")
        self._verify(svg)
        self._check_widths()
        path = OUT / f"{self.name}.svg"
        path.write_text(svg)
        # rsvg-convert refuses /dev/stdout, so render to a scratch file to prove it parses.
        with tempfile.NamedTemporaryFile(suffix=".png") as tmp:
            subprocess.run(["rsvg-convert", "-w", "600", "-f", "png", "-o", tmp.name, str(path)],
                           check=True, capture_output=True)
        return path
