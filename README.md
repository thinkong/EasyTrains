# Sam's Trains
A simple, easy-to-use, no circuits required train scheduler for people who just want their trains to work. 

**Adds 3 different train stops to the game:**

*Depot*: a place for your trains to fuel and wait for their next task\
![Depot](https://i.ibb.co/V9cF1g2/depot.png)
\
*Supplier*: a stop that has and can supply a resource\
![Supplier](https://i.ibb.co/SrqmVkY/supplier.png)
\
*Consumer*: a stop that wants a resource\
![Consumer](https://i.ibb.co/tLpR7rr/consumer.png)


---
### Change log
**0.17**
- Update the icon and entity graphics. These are still temporary graphics, just slightly better.
- Reorder the train stop icons to be depot, supplier, consumer
- Fix priority tooltip not working
- Add optional warning if train has been waiting at consumer/supplier for a configurable timer
- Add optional timeout to consumer/supplier stops
- Add request an item count to consumer stops
- Fix st-data-entity not having a name
- Hide trains without a depot name from the overview list

**0.16**
- Fix blueprinting not properly copying settings
- Fix trains not dispatching from the depot until another train has arrived at the depot

**0.1.5**
- Allow train stop names to not be unique.
- Allow train stops to be blueprinted.
- Allow signals to specify the resource on a train stop.
- Allow disabling train stop by circuit.

**0.1.4**
- Fix case sensitivity issue for linux/mac

---

### How to use
 - Research Sam's Trains
 - Create one or more 'Train Stop Depots'.
 - Send a train to your Depot. The train will now be automatically managed by the scheduler.
 - Create a Train Stop Consumer. Specify the resource it wants and enable it.
 - Create a Train Stop Supplier. Specify the resource it has and enable it.
 - Your trains should now automatically be dispatched from your depot to your supplier, then to your consumer, then back to the depot.

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
 - [NO LONGER NECESSARY AS OF 0.1.5] Consumers and suppliers must have unique names. Depots can be named the same.
 - Trains at depot with multiple resources will not be dispatched
 - Can't handle mixed trains (fluid and items)
 - Train stop can only be consumer or supplier. Can't supply sulfuric acid and pick up uranium with a single stop for example.
 - Trains will wait to be fully fueled in each slot. This means you either need to have a single fuel type going into trains, or that each fuel type needs to be delivered by a separate inserter (or the inserter will get blocked trying to deliver a fuel that is already full on the train)
 - [NO LONGER NECESSARY AS OF 0.1.5] Train stop settings are not copied with blueprints due to Factorio limitations. But you can copy settings with shift click. The enabled setting will not be copied by default to give you time to finish setting up your train stop.

---

### Known issues
 - Multiple forces in a game probably don't work
 - The graphics are stock and the icons are just text. I'm not an artist. Can you help?
 - Train stop editor will not update if another player edits it while you have it opened
 - Train stop defaults cannot be edited (min/max length, etc)
 
---
### Future
 - Grouping train stops - making trains only be used within their groups, so they won't be sent across the map for a task.
 -  Add warning if train has been waiting at depot for fuel for 2 mins
 -  Complex train stop pattern matching (eg, a train stop will only allow trains that match locomotive, locomotive, cargo wagon, cargo wagon, locomotive, cargo wagon, cargo wagon)
 -  Make resource show over train stops on alt mode
 -  Make the resource of a train stop show automatically on the map
 -  Don't send a train back to a depot if it has enough fuel to do another task, just dispatch it en route
