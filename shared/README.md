# RCU Shared Utilities

Common code extracted from the per-game scripts to reduce duplication and
improve maintainability. Each module returns a table of functions and can be
loaded at runtime with:

```lua
local SHARED_ROOT = "https://raw.githubusercontent.com/Aditya-lua/RCU/main/shared/"
local Services = loadstring(game:HttpGet(SHARED_ROOT .. "Services.lua"))()
```

## Modules

| Module | Purpose |
|---|---|
| **Services.lua** | Centralised `game:GetService()` cache + HTTP request shim |
| **UI.lua** | Versus Library loading, anti-idle, `notify()`, `interval()` |
| **SafeHumanoid.lua** | `SafeGet*` / `SafeSet*` humanoid helpers (from Blox Fruits) |
| **TableUtils.lua** | `round`, `isnil`, `sortedKeys`, `filterKeys`, `prettyPrint`, `formatCash`, `lightYield` |
| **Net.lua** | `fireRemote`, `invokeRemote`, `safeRequire`, `resolvePath`, `requirePath` |
| **ThreadManager.lua** | Named-thread lifecycle manager (`Add` / `Stop` / `StopAll`) |

## Which scripts use which modules

| Script | Services | UI | SafeHumanoid | TableUtils | Net | ThreadManager |
|---|---|---|---|---|---|---|
| PickaxeSim.lua | x | x | | x | | |
| SSC_Elite_Farm_v3.lua | x | x | | x | x | |
| versus_airlines_blox_fruits.lua | x | x | x | x | | |
| RCU_Main_Final_Fixed.lua | | | | | | x |
