# PodlodkaFiles
Demo app for Podlodka Crew 5 shows two approaches for the persistence layer architecture:
- Normalized in-memory storage based on Swift value types
- LMDB

Both in-memory and LMDB based storages share such solid features as thread-safe access and multi-versioning. The presentation and domain layers of the app are entirely abstracted from persistent one and can be switched from one to another without any effort.

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

# Links
Here are some materials for diving deeper. Everything is in Russian.
- [[Хабр] Блеск и нищета key-value базы данных LMDB в приложениях для iOS](https://habr.com/ru/company/mailru/blog/480850/)
- [[YouTube] Видеоверсия статьи на Хабре в виде выступления на AppsConf](https://appsconf.ru/spb/2019/abstracts/5431)
- [[YouTube] Укрощаем нормализованное состояние: граф объекты и санитайзеры](https://youtu.be/SXzDR6GtxFw)
