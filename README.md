
﻿
# Random Outfit Destruction (R.O.D) 
[(Also available on Nexusmods)](https://www.nexusmods.com/cyberpunk2077/mods/22660)

Random Outfit Destruction (R.O.D) is a cyber engine tweaks mod inspired by the ESE﻿ mod made by tacobum for stellar blade

When the player takes damage there is a set chance (that can be edited on the cyber engine tweaks gui via a slider on the overlay)﻿ that 1 or more outfit pieces (visual only - Equipment Ex) get removed.

## New in version 1.3:
The goal in 1.3 was to implement a system to read loadouts and making break events more consistent with short cooldowns (60 frames)

![](https://i.imgur.com/IspZe3X.png)

- introduced a cooldown (lockstate) between break events to prevent multiple instances of break events happening at the same time
- Knockdowns now trigger a guaranteed break event (% break rate and limit still applies)
- Introduced an option to get a random wardrobe loadout when mounting a vehicle or entering a safezone (this took way more effort than i expected :O)
- Added two new buttons, randomize for giving you the option to get a new random loadout instead of repairing and Get Random Outfit for equiping a random loadout when you click the button :P
- Fixed instances of vehicle repairing despite no break event having happened when the user loaded the save while inside a vehicle or when a dot effect was still ongoing
- Changed the preset name ROD creates when saving your current appearence to "00 - ROD Current Outfit" (if you used an older version before, delete "00codeoutfit temp")

## New in version 1.2.1:
Minor patch to introduce some quality of life features:

- Auto Save Settings: Settings.lua is now dynamically updated when you click hide settings
- Init.lua now has a debugrod = false variable that when changed shows telemetry about break events and more

Note: I forgot to mention that (from version 1.2 onward) when the mod saves your currently equipped outfit (to restore when you get on a vehicle or safezone) it creates a wardrobe loadout by the name of "00codeoutfit temp", please do not delete this as it might cause unexpected bugs and weird behavior from the mod when attempting to restore your outfit, future versions will save a loadout by the name of "00 - ROD Current Outfit" and the mod will have checks for when a user might accidentally delete this.

New in version 1.2:
Thanks to ripperdoc's suggestion the mod is now capable of finding what visual slots the player is wearing

![](https://i.imgur.com/pcLCoNb.png)

- Implemented a system to repair clothes (currently equipped clothes get saved the first time you take dmg) by mounting your vehicle or entering a safehouse (this can also be toggled in settings)

- The list that shows the items that were broken now only shows the name of the item (less visual clutter)

- The file structure has changed so you can now set your own settings by editing the file in ("data/settings.lua")﻿(in the future il change this to update in real time)

- Outfits now break in a more linear fashion according to the structure in ("data/slots.lua"), basically the mod checks the list from top to bottom tries to break each item until you reach the limit (max number of items you can break) you set in settings

## New in version 1.1:
I made a breakthrough on the onhealthupdate function and implemented:

- A probability of triggering a break event
- A damage threshold to trigger a break event while still keeping the overall chance of each outfit breaking

![](https://i.imgur.com/qw1iGD3.png)

Basically these 2 are test variables to show what the game outputs but its basically max hp and delta hp (damage taken) from last attack, if you take more than the value on the box there is a % chance (% trigger) to do a break event (basically what 1.0 does rn)

So in this scenario if i take 25 damage there is a 10 % chance that any outfit i have has a 10% chance to break﻿

~~Sometimes no pieces are removed as this mod does not reference the currently worn slots but generic slots instead (trying to fix that but W.I.P for now as its not critical).~~ - Fixed in 1.2 thanks to ripperdoc

﻿﻿﻿﻿![](https://i.imgur.com/7USuzBv.png)

Usage : The first time you launch the mod the overview will be visible at all times, in order to edit it press your CET hotkey to open cyber engine tweaks window.

![](https://i.imgur.com/UyDf1gK.png)

Drag the sliders to define on a scale of 0% to 100% what's the chance of each of your outfit pieces breaking.
You can click on hide settings to hide the sliders if you are happy with the result.
(i like 30% trigger 10% rate for very low chance / 20% trigger 50% rate for medium/high chance).

- **% rate** - means the chance of your outfit breaking when you trigger a break event (you take enough damage and % trigger activates).
- **% trigger** - chance of triggering a break event when enough damage is taken (acording to the value set on damage trigger).
- **Damage trigger** - Amount of damage you need to take to have a chance of triggering a break event.
- **Limit** - max amount of outfit pieces that can break in a single break event.

Any time the mod is triggered the outfit piece(s) that were removed will show on the list.
You can also hide this if you don't want to see it by clicking on hide list.

**Note:** You can resize and move the window (its an invisible window) anywhere you want it to be and you can resize it by clicking on the arrow at the bottom left corner.

removing both the list and the bar will hide everything and if you wanna see the ui again you have to press reload mods (i might fix this in the future if i have patience)

Screenshots of the mod in action (old version 1.0):

﻿![](https://i.imgur.com/zido0sJ.jpeg)
![](https://i.imgur.com/NGvQhvB.jpeg)

This mod was mostly made for myself but because i didn't see any mod that did something similar i decided to publish it.

### future updates are not guaranteed but some features that could be introduced in future versions may include:

- Improving the lua code to be more performant (i know the current code could be more optimized to consume less resources)
- ~~Finding a way to detect when the player gets hit instead of when the player heals themselves~~ - Added on 1.1
- ~~Finding a way to detect what items the player currently has equipped on the visual slots and only remove those (one at a time)~~ - Added on 1.2 (massive thanks to ripperdoc﻿ and the functions on the mod : Visual Holsters (Automatic Clothes Swap) )
- ~~Developing a system to restore broken outfits (ex: going to your car or your house)~~ - Added on 1.2

### Version 1.3 plans:
- Ability to remember your settings by storing then dynamically on settings.lua (i already have a patch for this working so might release it separately) - Version 1.2.1 introduces this feature when you click hide settings so yall don't have to wait too long :)
- Making a hit by car/knockdown trigger a guaranteed break event (I'm not sure if i should make it guaranteed or % trigger)
- Have an option so that every time you go into a vehicle or safezone, instead of repairing your current outfit you equip a random wardrobe loadout

### Potential version 1.4 plans:
- Punishment system (open to ideas)
- Immersive clothing recovery : Every time you collect equipment or outfits from the ground you repair the specific slot you broke if the types match (ex : a shirt can only repair another shirt)

### Hypothetical version 1.5 plans:
- Npc/Police reactions : I have no idea to what extent the code will allow me to do this as i will have to really dig deep on nativedb to figure out how to implement this but the idea would be when certain outfit parts are missing (user can specify which) npcs start avoiding you (and calling you crazy) and police becomes hostile
