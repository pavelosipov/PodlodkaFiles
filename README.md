# PodlodkaFiles
Demo app for Podlodka Crew 5 shows two approaches for the persistence layer architecture:
- Normalized in-memory storage based on Swift value types
- LMDB

Both in-memory and LMDB based storages share such solid features as thread-safe access and multi-versioning. The presentation and domain layers of the app are entirely abstracted from persistent one and can switch from one to another without any effort.

The current type of storage is determined by state and stateUpdater properties in `Assembly` class.

```swift
// In-Memory aka RAM version
private var state: State { ramState.value }
private var stateUpdater: StateUpdater { ramStateUpdater }
```
```swift
// LMDB version
private var state: State { dbState }
private var stateUpdater: StateUpdater { dbStateUpdater }
```
Happy coding!