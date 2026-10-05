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

## Seeing it in first person (optional)

By default, Minecraft doesn't render your own player model in first person,
so you won't see the animation from your own point of view - only other
players (or you, in third person / F5) will.

If you also want to see it in first person, install the
**First-person Model** mod:

- [Modrinth](https://modrinth.com/mod/first-person-model)
- [CurseForge](https://www.curseforge.com/minecraft/mc-mods/first-person-model)

This is purely client-side and optional - InventoryPopUp works fine without it.

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

- **Opt-in**: screens that aren't vanilla containers (like Cobblemon's PC
  or Create's blocks) are off unless you turn them on with the matching
  `enable*` option.
- **Opt-out**: screens that already count automatically (like Waystones,
  since it's a vanilla-style container) can be turned off individually
  with the matching `enable*` option, without affecting other containers
  like chests or barrels.

## `:getPhase()`

Returns one of:

- `"idle"` - no screen open, nothing playing
- `"starting"` - `startAnim` is playing
- `"looping"` - `loopAnim` is playing (screen is open)
- `"ending"` - `endAnim` is playing

## Credits

Made by Kehan. Questions, issues, or need a screen supported that isn't
yet? Message me on Discord (@Kehan) with as much detail as possible - a
screenshot or short clip helps a lot.
