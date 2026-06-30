<div align="center">

# TSTUDIO HOTEL MANAGEMENT

Hotel management for FiveM. Standalone, no ESX or QBCore required.

![Version](https://img.shields.io/badge/version-1.0.0-C9A84C?style=flat-square)
![Standalone](https://img.shields.io/badge/standalone-yes-52b87a?style=flat-square)
![OneSync](https://img.shields.io/badge/OneSync-Infinity-5b8fd4?style=flat-square)
![Lua](https://img.shields.io/badge/Lua-5.4-7c4dbd?style=flat-square)
![Idle](https://img.shields.io/badge/idle-0.00ms-52b87a?style=flat-square)

</div>

---

## Features

<table>
<tr>
<td valign="top" width="50%">

### 🏨 Management

- Unlimited hotels and rooms
- Runtime hotel builder — no restart needed
- Booking system with automatic expiry
- Room extensions, eviction, and fines
- Complaint system
- Boss dashboard with revenue analytics
- Discord webhook logging

</td>
<td valign="top" width="50%">

### 🚪 Rooms

- Physical and digital key access
- Personal stash per room
- Wardrobe integration
- Instance support
- Room cleaning system
- Configurable pricing and rental durations

</td>
</tr>
<tr>
<td valign="top" width="50%">

### 👤 Staff

Five tiers: Receptionist, Cleaner, Security, Manager, Owner.

Staff can rent rooms, extend rentals, evict tenants, issue fines, manage complaints, hire and fire employees, adjust prices, and pull analytics.

</td>
<td valign="top" width="50%">

### 🔧 Builder

Build hotels directly in-game. Place reception desks, NPCs, room doors, wardrobes, stashes, and elevators. Changes save at runtime.

</td>
</tr>
</table>

---

## Supported Resources

| Category | Resources |
|---|---|
| **Inventory** | `ox_inventory` `qb-inventory` `qs-inventory` `lj-inventory` `standalone` |
| **Door Locks** | `ox_doorlock` `cd_doorlock` `nui_doorlock` `standalone` |
| **Target** | `ox_target` `qb-target` `interact` `standalone` |
| **Wardrobe** | `illenium-appearance` `fivem-appearance` `qb-clothing` `esx_skin` `rcore_clothing` `standalone` |
| **Phone** | `lb-phone` `qb-phone` `qs-smartphone` `gksphone` `gcPhone` `standalone` |
| **Banking** | `Renewed-Banking` `qb-banking` `okokBanking` `standalone` |

Optional integrations are auto-detected at startup. Missing resources don't cause errors.

---

## Installation

1. Import `sql/hotel.sql` into your MySQL database.

2. Drop the resource into your `resources/` folder.

3. Confirm `oxmysql` starts before this resource.

4. Add to `server.cfg`:
   ```
   ensure tstudio_hotelscript
   ```

5. Configure in `shared/`:

   | File | Purpose |
   |---|---|
   | `config.lua` | Main settings |
   | `hotels.lua` | Hotel definitions |
   | `rooms.lua` | Room definitions |
   | `locale.lua` | Language strings |

6. Restart your server.

---

## Exports

```lua
exports["tstudio_hotelscript"]:CreateRental(...)
exports["tstudio_hotelscript"]:CancelRental(...)
exports["tstudio_hotelscript"]:GiveKey(...)
exports["tstudio_hotelscript"]:HasKey(...)
exports["tstudio_hotelscript"]:Notify(...)
exports["tstudio_hotelscript"]:GetHotel(...)
exports["tstudio_hotelscript"]:GetRoom(...)
exports["tstudio_hotelscript"]:GetEmployees(...)
```

> Admin command: `/hotel_reload`

---

## Performance

Tested on OneSync Infinity. Actual numbers vary by hotel count, active integrations, and server hardware.

| State | CPU |
|---|---|
| Idle | ~0.00 ms |
| Near hotel | ~0.01–0.03 ms |
| Builder active | ~0.02 ms |

---

## Folder Structure

```
tstudio_hotelscript/
├── bridge/
├── client/
├── server/
├── shared/
├── html/
├── sql/
└── fxmanifest.lua
```

---

## Permissions

| Key | Scope |
|---|---|
| `hotel.admin` | Full admin access via ACE |
| `Config.BossIdentifiers` | Per-hotel boss access |

---

## Requirements

- FiveM (latest recommended artifact)
- Lua 5.4
- oxmysql

Enable `Config.Debug` in `shared/config.lua` if you need to troubleshoot.

---

<div align="center">

Developed by **TSTUDIO** · v1.0.0

</div>
