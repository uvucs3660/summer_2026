# JS Framework Survey Cheat Sheet (80/20)

The 20% of framework knowledge you'll use 80% of the time when picking one for a project. The four candidates this course will see: **React**, **Vue**, **Svelte**, **Flutter-web**. There is no winner. There are right-for-context picks.

## How to choose

In rough order of weight:

1. **What does the team already know?** A team productive in React beats a team learning Svelte for 4 weeks.
2. **What's the deployment surface?** Web only? Web + native mobile? Just web in a Canvas page?
3. **How much custom UI vs. data display?** A dashboard wants a component library; a game wants raw control.
4. **Bundle size budget.** Marketing site = strict. Internal admin tool = lax.
5. **Hype is not weight.** The framework that was hot 18 months ago has the better docs.

## React — the default

**Component model**: function components + hooks. JSX (HTML-in-JS).
**Reactivity**: re-render on state change; `useState`, `useEffect`, `useMemo`. Reconciler diffs the virtual DOM.
**Build pipeline**: Vite or Next.js (the whole framework, not just React).
**Bundle size**: ~45 KB minified-gzipped for React + ReactDOM. Add libs: usually 100-300 KB total.
**Mobile**: React Native (separate but skill-transfers).

**When right**: you have ANY React experience on the team; you want the largest ecosystem of libraries; you want to hire later (50%+ of frontend job postings).

**When wrong**: bundle-size critical (marketing sites); you want compile-time reactivity (Svelte does it cleaner).

```jsx
function Counter() {
  const [n, setN] = useState(0);
  return <button onClick={() => setN(n + 1)}>{n}</button>;
}
```

## Vue — the pragmatic middle

**Component model**: Single-File Components (`.vue`) — template + script + style in one file.
**Reactivity**: proxy-based with `ref()`/`reactive()`; explicit dependency tracking via the Composition API.
**Build pipeline**: Vite (Vue's creator built Vite).
**Bundle size**: ~35 KB minified-gzipped.
**Mobile**: NativeScript-Vue, Quasar; not first-class.

**When right**: smaller team, you like SFCs more than JSX, you want progressive enhancement (drop Vue into an existing page).
**When wrong**: hiring at scale (smaller talent pool than React); you want compile-time guarantees beyond TypeScript.

```vue
<script setup>
import { ref } from 'vue'
const n = ref(0)
</script>

<template>
  <button @click="n++">{{ n }}</button>
</template>
```

## Svelte — the compile-time bet

**Component model**: `.svelte` file, no virtual DOM. Compiler generates surgical DOM updates.
**Reactivity**: `$state`/`$derived`/`$effect` runes (Svelte 5). Compile-time, zero-runtime overhead.
**Build pipeline**: Vite + SvelteKit (the meta-framework).
**Bundle size**: ~10 KB minified-gzipped for the runtime; per-component code is tiny.
**Mobile**: not first-class (web only realistically).

**When right**: bundle size matters; you love minimalism; team is small and willing to learn.
**When wrong**: you need a giant ecosystem; you have React muscle memory you don't want to retrain.

```svelte
<script>
  let n = $state(0);
</script>

<button onclick={() => n++}>{n}</button>
```

## Flutter — web + everything

**Component model**: Widget tree in Dart.
**Reactivity**: `setState` + Riverpod/Provider/BLoC.
**Build pipeline**: Flutter SDK.
**Bundle size**: BIG (1-2 MB at minimum). Trade-off: identical app on web/iOS/Android/Desktop.
**Mobile**: First-class.

**When right**: you ship the same app to web AND native; design uniformity matters more than web-native UX.
**When wrong**: pure web project; any concern about bundle size, accessibility, or feeling-like-a-web-page.

```dart
class Counter extends StatefulWidget {
  @override
  _CounterState createState() => _CounterState();
}
class _CounterState extends State<Counter> {
  int n = 0;
  @override
  Widget build(BuildContext c) =>
    ElevatedButton(onPressed: () => setState(() => n++), child: Text('$n'));
}
```

## Side-by-side cheat

| | React | Vue | Svelte | Flutter |
|---|---|---|---|---|
| **Language** | JSX (JS/TS) | SFC (HTML+JS) | `.svelte` | Dart |
| **Reactivity** | re-render | proxy | compiled signals | setState |
| **Bundle (basic app)** | ~150 KB | ~120 KB | ~30 KB | 1-2 MB |
| **Learning curve** | medium | low | low-medium | medium-high |
| **Mobile native** | React Native | weak | weak | excellent |
| **Hiring pool (2026)** | huge | medium | small | small |
| **Best for** | most things | smaller teams | size-critical | multi-platform |

## What to skip

- **Angular**. Excellent at scale, but the learning curve and ceremony don't fit a 4-week sprint. Skip it for CS3660 unless you already know it.
- **Solid.js, Qwik, Marko**. Interesting; small ecosystems. Pass for now.
- **Lit, Stencil**. Web Components frameworks. Use only if you specifically want WC interop.

## How to make the call for your sprint

The questions, in order:

1. Does any team member have ≥3 months on one of these? → use that one.
2. Do you ship native mobile too? → Flutter.
3. Is bundle size a hard rubric line? → Svelte.
4. Default → React.

That's it. Don't agonize past 30 minutes; pick and move.

## Further reading

- **react.dev** · **vuejs.org** · **svelte.dev** · **flutter.dev** — read the official getting-started for whichever you pick.
- **Tree-shaking + code-splitting** — orthogonal to framework choice; learn it once.
- **Hydration cost** — what makes your initial-paint slow regardless of framework.
