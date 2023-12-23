TODO:
- Add creatures
- Wolf
- mongoose
- Lava Ox
- Chaos Hawk
- cow
- badger
- Ogre
- Snagon
- Frost mephit
- Giant Moth
- Skipping Fungus
- Sand Slug
- Corn: needs to be a plant for awhile and then becomes food
- ensure the maps aren't too crazy
- remove sounds


to test
- Pulse blossom: glows periodically and hurts anything around it.
- do potatoes spread properly


Later:
- potatoes only spread under the right conditions
- Kill grib_weed if it is too cold for too long
- sun berry: plant that glows when it is in dry soil.


- Each block type has a chance of becoming an item or just disappearing when you break it.
- Trees from Exile
- Temperature
    Look at temp system in Exile
    you start to die if not kept in a certain temperature range. It is colder at night. Certain parts of the map are colder. Some days are colder than others. If you are too hot you will lose energy faster and get thirsty faster.
    Energy expenditure raises your core temp
    The air has an ambient temp
    Your core temp goes toward this temperature over time

What can we take from existing mods?
mobs from Exile?
Natural slopes library (in Exile)

Apple Tree: grows slowly: drops apples occasionally. Has a chance of dropping wood when broken.

Fountain: Will spray water over the nearby blocks.
Slug: takes up a block. Will move in a direction pushed. Picks up the first block in its path and becomes this when it comes to a stop.

Launcher: anything that stands on this is launched in the air in the direction it was going
Conveyor belt: Placed on terrain. Any item on it is conveyed along to the end of the belt

-   Corpse: provides food. Turns to bones

Every 10 seconds Pulse Blossom starts to glow for 2 seconds at the end of the glow it damages any players or mobs around it.


Also grib weed should spread to ground spaces with no flora.

We are trying to use gen_notify to do something when grib weed is created. The grib weed shows up in the world but the gen_notify isn't working. What could be wrong?


Thorns should have a random chance of going into the "with fruit" state. This changes the image shown and allows the player to harvest from the node. If harvested it should get out of he "with fruit" state
