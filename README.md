# InventoryPopUp

A Figura avatar API that plays a start -> loop animation cycle whenever a GUI
screen opens (chest, furnace, crafting table, your own inventory, Figura's
own menu, and a few supported modded screens), and an end -> idle cycle when
it closes.

Works in multiplayer: the host detects the screen and syncs the state to
everyone watching, so the animation plays the same for all viewers - not
just for yourself.

## Install

Drop `InventoryPopUp.lua` into `scripts/API/` in your avatar folder.

## Usage

```lua
local InventoryPopUp = require("scripts/API/InventoryPopUp")

local inspect = InventoryPopUp.new({
    startAnim = animations.Base.inspectingstart,
    loopAnim  = animations.Base.inspectingloop,
    endAnim   = animations.Base.inspectingend,
})
```

`startAnim`, `loopAnim`, and `endAnim` are your own Blockbench animations -
the names above are just an example, use whatever you named yours.

Then, anywhere in your script, check the current phase and do whatever you
want with it:

```lua
events.TICK:register(function()
    if inspect:getPhase() ~= "idle" then
        -- example only - replace with your own model part
        -- models.YourModel.YourPart:setVisible(true)
    end
end)
```

## Texture & making your own animations

This repo also includes a ready-made texture, `MC_GUI_Inventory.png`,
free for anyone to use as a starting point.

1. Import `MC_GUI_Inventory.png` into your own Blockbench project.
2. Add it to your own model (a cube or plane works fine) - position it and
   set up the UV mapping however you like.
3. Create three animations on your model: one for opening, one that loops
   while the screen stays open, and one for closing. This repo's own
   example uses `inspectingstart` / `inspectingloop` / `inspectingend` -
   using the same names isn't required (InventoryPopUp doesn't care what
   your animations are called), but it keeps things consistent if you're
   following along with the example.
4. Pass those three animations into `InventoryPopUp.new()` as `startAnim`,
   `loopAnim`, and `endAnim` (see Usage above).

## Options

All of these are optional except the three animations.

| Option | Default | Description |
|---|---|---|
| `startAnim` | *(required)* | Animation played once when a screen opens |
| `loopAnim` | *(required)* | Animation looped while the screen stays open |
| `endAnim` | *(required)* | Animation played once when the screen closes |
| `priority` | `6` | Priority passed to `:setPriority()` on all three animations |
| `enableFiguraMenu` | `false` | Whether Figura's own menu counts as "open" (off by default - looping animations tend to look disrupted there) |
| `enableCobblemonPC` | `true` | Whether Cobblemon's PC screen counts as "open" |
| `enableCreateBlocks` | `true` | Whether Create's "value setting" block screens count as "open" |
| `enableWaystones` | `true` | Whether Waystones' teleport screen counts as "open" |

## Two kinds of screens

- **Opt-in** (`MODDED_SCREENS` in the file): screens that aren't vanilla
  containers, so they're missed by default. Toggling one of these *on*
  makes it count; it has no other effect.
- **Opt-out** (`EXCLUDABLE_CONTAINER_SCREENS` in the file): screens that
  *are* vanilla containers, so they already count via the general
  container check. Toggling one of these *off* excludes just that screen -
  every other container (chests, barrels, etc.) keeps working normally.

If you're not sure which kind a screen is: open it with the debug block
(see below) and check `isContainerOpen=`. `true` means opt-out, `false`
means opt-in.

## `:getPhase()`

Returns one of:

- `"idle"` - no screen open, nothing playing
- `"starting"` - `startAnim` is playing
- `"looping"` - `loopAnim` is playing (screen is open)
- `"ending"` - `endAnim` is playing

## Adding more screens

Open `InventoryPopUp.lua` and find the debug block (commented out, near the
top). Uncomment it, open the screen in-game, and read the class name and
`isContainerOpen=` value it prints in chat.

- `isContainerOpen=false` -> add the class name to `MODDED_SCREENS`, with
  your own key name and (if you want it toggleable) an `enable*` option.
- `isContainerOpen=true` -> it already works automatically. Only add it to
  `EXCLUDABLE_CONTAINER_SCREENS` if you specifically want the *option* to
  turn it off later.

## Credits

Made by Kehan. Questions or issues? Message me on Discord (@Kehan) with as
much detail as possible - a screenshot or short clip helps a lot.
