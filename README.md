# Ragnarock - SongBridge Mod
**Lua script to expose live song metadata from Ragnarock to external tools (e.g. [Streamer.bot overlay](https://github.com/Xoanon80/Ragnarock-Streamer.bot-Enhanced-Song-Overlay#-v2-songbridge-mod-integration-optional)).**

# Features
- Detects song selection
- Writes song metadata to a plain text file on every song change

# Output
On each song selection, `SongBridge.txt` is written to your Ragnarock `Binaries/Win64` directory with the following fields:
| Field | Description |
|---|---|
| `Hash` | In-game hash (CRC32) of the currently selected difficulty. |
| `IsCustom` | `true` for custom maps, `false` or `unknown` for base-game/OST songs. |
| `Artist` | Band/artist name. |
| `Title` | Song title. |
| `Mapper` | Mapper name as shown in-game (not necessarily the RagnaCustoms website username). |
| `Length` | Song length in seconds. |
| `BPM` | Base BPM. |
| `Level` | Currently selected difficulty. |
| `AllLevels` | All difficulties available for this song, comma-separated. |

External tools (like Streamer.bot) can watch this file's last-modified timestamp to react to song changes.

# Prerequisites
[UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) (UE4SS_v3.0.1-1028-gd7e7826d.zip) must be installed.<br />
A backup of this version is kept in a sub-directory of this repository.<br />
Contents from UE4SS zip go into your Win64 directory of your Ragnarock installation, for example<br />
```C:\Program Files (x86)\Steam\steamapps\common\Ragnarock\Ragnarock\Binaries\Win64```

# Installing Mod
Choose the version matching how you play. Only install/activate one at a time.

**Flat (non-VR):**
1. Extract [SongBridge](SongBridgeFlat.zip) and place into the Mods-directory of UE4SS, for example:<br />
```C:\Program Files (x86)\Steam\steamapps\common\Ragnarock\Ragnarock\Binaries\Win64\ue4ss\Mods```
2. Add "**SongBridge: 1**" to `mods.txt` (right before the line "**; Built-in keybinds, do not move up!**")

**VR:**
1. Extract [SongBridgeVR](SongBridgeVR.zip) and place into the Mods-directory of UE4SS, same location as above.
```C:\Program Files (x86)\Steam\steamapps\common\Ragnarock\Ragnarock\Binaries\Win64\ue4ss\Mods```
2. Add "**SongBridgeVR: 1**" to `mods.txt` (right before the line "**; Built-in keybinds, do not move up!**")

# Notes
- `SongBridge.txt` uses the same filename regardless of variant.
- The `SongBridge.txt` as a data source works with and adds abilites to the V2 of the [Ragnarock Streamer.bot Enhanced Overlay]([https://github.com/Xoanon80/Ragnarock-Streamer.bot-Enhanced-Song-Overlay](https://github.com/Xoanon80/Ragnarock-Streamer.bot-Enhanced-Song-Overlay#-v2-songbridge-mod-integration-optional)

---
# Project Support
For issues related to this Mod:
- Discord: @xoanon
- GitHub: https://github.com/Xoanon80
```
