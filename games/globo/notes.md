TODO:

- make breeding
    - make pregnant a timer rather than a bool
- temperature should affect you
    - hides that keep you warm
    - eggs need to be a certain temperature to hatch


- make seasons shorter?

- tell you the direction that damage came from
- dropped items should burn in fire
- flowing water should push you
- player should be no different than other animals to the mobs
- plants spread
- make animals sleep
- animals run from fire
- adjust the exile energy system to have a max energy and regain your current energy when you are still
- ensure the maps aren't too crazy

CHECK:
- wolves are often getting killed by cows
- behaviors seem wonky. Do they need more idle time
- make sure animals can be in equilibrium
- is it better to just have the infinite map?
- what does armor do?
- do animals get hurt by thorns?



BUGS:
- sneachens aren't eating?
- wolf energy not decreasing
- health effects are being cleared instantly
- will drift at last speed once at energy 0
2024-01-03 07:50:40: ERROR[Server]: suspiciously large amount of objects detected: 264 in (-22,0,-20); removing all of them.



- Temperature
    you start to die if not kept in a certain temperature range. It is colder at night. Certain parts of the map are colder. Some days are colder than others. If you are too hot you will lose energy faster and get thirsty faster.
    Energy expenditure raises your core temp
    The air has an ambient temp
    Your core temp goes toward this temperature over time



IDEAS:
- eat something that makes you glow
- bouyancy
    - need to be able to create some kind of raft
- Lava Ox
- Chaos Hawk
- badger
- Ogre
- Snagon
- Frost mephit
- Giant Moth
- Sand Slug
- Block that moves through the air at a particular elevation until it hits something.  Anything on top of it will ride along. Spawns randomly
- Launcher: anything that stands on this is launched in the air in the direction it was going
- tar
Motion detector
Apple Tree: grows slowly: drops apples occasionally. Has a chance of dropping wood when broken.
Fountain: Will spray water over the nearby blocks.
Slug: takes up a block. Will move in a direction pushed. Picks up the first block in its path and becomes this when it comes to a stop.
Willow wisp
Throw rocks. Do a small amount of damage
Some sort of flying glowing thing that is attracted to a certain flower
- migrations?
Flower that only blooms at dawn. You can eat it then
What would require more planning?




Later:
- Wind that affects the direction that fire spreads
- Do we want to be able to dig clay or cut trees?
- need a way to throw things away
- potatoes only spread under the right conditions
- Kill grib_weed if it is too cold for too long
- sun berry: plant that glows when it is in dry soil.
- Each block type has a chance of becoming an item or just disappearing when you break it.




Changes to Minetest
----
Allow you to send other commands
Allow you to generate the whole map and reject those that don't meet some criteria
The way lava and water flow
Allow other color lights


Notes
----
What can we take from existing mods?