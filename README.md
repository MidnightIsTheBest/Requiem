<h1 align="center">Requiem</h1>
<p align="center">A Roblox script hub, forked from Vape V4.</p>

## Usage
Execute this in your executor:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MidnightIsTheBest/Requiem/main/NewMainScript.lua", true))()
```

## Setup (own repo)
1. Create a GitHub repo named `Requiem` under `MidnightIsTheBest` and upload everything in this folder to its `main` branch.
2. Repo Settings -> Actions -> General -> Workflow permissions: **Read and write**.
3. Wait for the `build` Action to finish. It bundles `src/` into the `compiled` branch.
4. Run the loadstring above. If something looks stale, delete the `requiem` folder in your executor's workspace.

Using a different repo name or username? Search the repo for `MidnightIsTheBest/Requiem` and replace it.

## Additions in Requiem
- Killaura animation modes **Block** and **Block Spin**
- **Auto Block** (Utility): builds a block cage around nearby players, Scaffold style
- Remote whitelist / kill switch from upstream removed

## Credits
Based on [VapeV4ForRoblox](https://github.com/7GrandDadPGN/VapeV4ForRoblox) by 7GrandDad, see LICENSE.
