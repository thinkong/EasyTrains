# Easy Trains
A simple, easy-to-use, no circuits required train scheduler for people who just want their trains to work. 
Originally [Sam's Train](https://mods.factorio.com/mod/SamTrain) but the original author(kiasyn) seemed to have abandoned it. I forked the source and rebranded it adding [SamTrainsV18](https://mods.factorio.com/mod/SamTrain_v18) which is a 0.18 fix by bMac59 into the source.
It should be compatible with the original SamTrainv18.
I have kept the tech name and icons from the original. Please contact me if you wish to have this mod or any part of this mod to be removed.

**Adds 3 different train stops to the game:**
*Depot*: a place for your trains to fuel and wait for their next task
![Depot](https://i.ibb.co/V9cF1g2/depot.png)
*Supplier*: a stop that has and can supply a resource
![Supplier](https://i.ibb.co/SrqmVkY/supplier.png)
*Consumer*: a stop that wants a resource
![Consumer](https://i.ibb.co/tLpR7rr/consumer.png)

---

### How to use
 - Research Sam's Trains
 - Create one or more 'Train Stop Depots'.
 - Send a train to your Depot. The train will now be automatically managed by the scheduler.
 - Create a Train Stop Consumer. Specify the resource it wants and enable it.
 - Create a Train Stop Supplier. Specify the resource it has and enable it.
 - Your trains should now automatically be dispatched from your depot to your supplier, then to your consumer, then back to the depot.
 - In the case of emergency try using `/et_cleanup` in the console.

---

### Features
 - Automatically schedules and reuses your trains
 - Easily disable / enable your train stops with the scheduler
 - Manual trains are ignored by the scheduler
 - Prioritize some stops over others
 - Set the min and max size train your train stop can handle
 - Trains will not leave depot until they are fully fueled
 - A train will always return to the depot (by name) that you set it to.
 - Trains will automatically balance themselves over consumers/suppliers
 - Trains will visit consumers & suppliers in a round robin order, so every stop will get visited
 - If you send a train with a single resource in it to the depot (eg, iron ore) it will wait until a consumer needs that resource, then be dispatched to that task instead of an empty train
 - Trains will automatically colour themselves based on their destination consumer stop

---

### Limitations
 - Trains will wait until full/empty at each stop, currently there is no extra configuration here.
 - Consumers and suppliers must have unique names. Depots can be named the same.
 - Trains at depot with multiple resources will not be dispatched
 - Can't handle mixed trains (fluid and items)
 - Train stop can only be consumer or supplier. Can't supply sulfuric acid and pick up uranium with a single stop for example.
 - Trains will wait to be fully fueled in each slot. This means you either need to have a single fuel type going into trains, or that each fuel type needs to be delivered by a separate inserter (or the inserter will get blocked trying to deliver a fuel that is already full on the train)
 - Train stop settings are not copied with blueprints due to Factorio limitations. But you can copy settings with shift click. The enabled setting will not be copied by default to give you time to finish setting up your train stop.

---

### Known issues
 - Multiple forces in a game probably don't work
 - The graphics are stock and the icons are just text. I'm not an artist. Can you help?
 - Train stop editor will not update if another player edits it while you have it opened
 - Train stop defaults cannot be edited (min/max length, etc)
 
---
### Future
#### Below is a list that the original author made.. I have no idea if I will ever implement anything
 - Grouping train stops - making trains only be used within their groups, so they won't be sent across the map for a task.
 -  Add warning if train has been waiting at depot for fuel for 2 mins
 -  Add warning if train has been waiting at supplier for configurable timer
 -  Add warning if train has been waiting at consumer for configurable timer
 -  Add configurable timeout to supplier to make the train leave even if not full?
 -  Complex train stop pattern matching (eg, a train stop will only allow trains that match locomotive, locomotive, cargo wagon, cargo wagon, locomotive, cargo wagon, cargo wagon)
 -  Make resource show over train stops on alt mode
 -  Make the resource of a train stop show automatically on the map
 -  Don't send a train back to a depot if it has enough fuel to do another task, just dispatch it en route