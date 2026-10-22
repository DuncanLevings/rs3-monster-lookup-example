# Monster Lookup Example

A developer demo showing how an RS3 plugin can use **Monster Lookup** and **Monster Data Core**
to build its own monster interface.

The demo combines public components in a custom window, handles search selections itself,
and adds a section and tab to the standard Monster Lookup window. Use it as a reference or
starting point for your own plugin.

## What it demonstrates

- **A custom layout:** selected stat rows, immunities, Slayer information, detailed stats and
  a model preview, arranged by the consuming plugin.
- **Independent searches:** monster, dropped-item and stat searches, each with its own state.
- **Combined search:** the same three searches in one component with a mode selector.
- **Embedded views:** drop tables and locations inside the demo's own tabs.
- **Opening Monster Lookup:** send a selection to the standard window, preserving item, mode
  and tab focus from search results.
- **Extensions:** register an `Example consumer` section and an `Example` tab in Monster Lookup.
- **Lifecycle handling:** own a lookup handle, reject stale callbacks, pause hidden searches
  and release components before their containers.

## Run the demo

Install these dependencies:

- [Monster Data Core](https://github.com/DuncanLevings/rs3-monster-data-core)
- [Monster Lookup](https://github.com/DuncanLevings/rs3-monster-lookup)
- PrettyUI, available from the Plugin Hub.

From your `dev_plugins` directory, clone the example using this folder name:

```sh
git clone https://github.com/DuncanLevings/rs3-monster-lookup-example.git monster-lookup-example
```

For local development, the layout should be:

```text
dev_plugins/
  monster-data-core/
  monster-lookup/
  monster-lookup-example/
```

The example manifest references those local dependency names. Published consumers can use
these mod.io listing ids:

| Dependency | mod.io ID |
| --- | --- |
| Monster Lookup | `6468042` |
| Monster Data Core | `6471519` |
| PrettyUI | `6398181` |

For example, `"MonsterLookup": 6468042` imports the Monster Lookup API under the same alias.
The demo manifest stays configured for local development.

In the game console:

```text
prf
pon monster-data-core
pon monster-lookup
pon monster-lookup-example
```

Open **Monster Lookup Example** from the Plugins ribbon or Plugin Hub settings, then click
**Open example**. The demo starts with Goblin. Its window opens only when requested.

## Try it out

1. Use **Monsters**, **Items**, **Stats** or **Combined** to select a monster. The demo updates
   its own **Preview**; it does not automatically open the standard window. In Items search,
   choose an item and then a monster that drops it.
2. Inspect **Preview**, **Drops** and **Locations**. Use **Next variant** on a monster with
   multiple variants to change the custom preview's stats and model.
3. Click **Open Monster Lookup** to send the selection to the standard window. An item search
   carries its item/mode focus; a stat search opens Monster info.
4. Click **Open example tab** to see the registered extension. The standard Monster info tab
   also contains the `Example consumer` section while this demo is enabled.
5. Close/reopen the demo, switch tabs, resize it and log out/back in to exercise cleanup.

The custom preview's variant is independent of the standard window's variant selector.
The model uses limited scroll zoom with turning disabled; edit its options to try other controls.

**Locations controls the same marker as Monster Lookup.** The demo uses the existing navigation
provider. Its drop view uses saved prices.

Disable the demo when finished:

```text
poff monster-lookup-example
```

Its window and registered extensions are removed on shutdown.

## Read the code

| File | What to look for |
| --- | --- |
| [main.lua](main.lua) | Plugin startup and shutdown. |
| [src/example.lua](src/example.lua) | Dependency checks, lookup handle, selection/focus handling, ribbon/settings entry points and logout cleanup. |
| [src/view.lua](src/view.lua) | Caller-owned window and layout, component construction, tab activation, variant changes and destruction order. |
| [src/extensions.lua](src/extensions.lua) | Namespaced section/tab registration, structured content and disposal. |
| [plugin.json](plugin.json) | Dependency aliases exposed as `MonsterLookup`, `MonsterDataCore` and `prettyui`. |

Start with `src/view.lua` to change the layout. The tab ids, spacing and model size constants
are grouped near the top. Stat field lists and component options sit beside their constructors.
The library supplies the components; this demo decides where they go and how they are used.

All integration goes through the public dependency exports. No dependency implementation is
copied into this repository. Public calls use dot syntax, such as `MonsterLookup.open(...)`
and `component.destroy()`.

## Ownership and data

The demo requests no permissions and stores no settings. Its lookup handle uses Monster Lookup's
data service: covered records come from local data; unknown monsters may use Monster Lookup's
Wiki fallback and permissions.

Keep the shared dependency exports unchanged. Destroy components and lookup handles and dispose
extensions during your plugin's shutdown. Hidden searches stop running, and the model releases
its native resources while Preview is hidden. A selection revision prevents late lookup results
from updating a closed or replaced view.

## Verification

Monster Lookup's `tests/consumer_example_spec.lua` exercises the demo against its public API
and owned UI fixtures. Run Monster Lookup's normal test suite with this repository in the
sibling `monster-lookup-example` folder. Set `MONSTER_LOOKUP_EXAMPLE_ROOT` to an absolute path
if your checkout is elsewhere.

Real cross-plugin clicks, model rendering and layout should also be checked in the client.
When reloading a required dependency, enable/reload its dependents after it is ready; the demo
does not automatically restart itself. Optional-dependency hot swapping and replacing the
navigation provider are not demonstrated here.
