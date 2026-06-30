# NOCTIS Dots & Boxes

Classic Dots & Boxes game built with Flutter — dark cyberpunk aesthetic, AI opponent, local multiplayer, and Bluetooth/Hotspot multiplayer architecture ready.

---

## Game Rules

1. **Grid** — Players see a grid of dots. The size is chosen at setup (3×3 up to 10×10).
2. **Draw a line** — On your turn, tap between any two adjacent dots to draw one line.
3. **Complete a box** — If your line closes all 4 sides of a square, the box is marked with your initial (R or B).
4. **Bonus turn** — Completing one or more boxes earns you another turn immediately.
5. **No re-drawing** — A line that has already been drawn cannot be drawn again.
6. **Game ends** — When every possible box has been completed.
7. **Winner** — The player with the most completed boxes wins. Tied scores = Draw.

---

## Modes

| Mode | Description |
|------|-------------|
| VS COMPUTER | Play against AI — Easy / Medium / Hard |
| VS FRIEND | Pass & play on the same device |
| ONLINE *(coming soon)* | Bluetooth or Wi-Fi Hotspot multiplayer |

---

## AI Difficulty

| Level | Strategy |
|-------|----------|
| Easy | Random moves |
| Medium | Takes boxes when available; avoids giving opponent easy boxes |
| Hard | Chain-aware; sacrifices smallest chain; aggressive box capturing |

---

## Project Structure

```
lib/
├── main.dart                         # App entry
├── screens/
│   ├── home_screen.dart              # Mode selection
│   ├── setup_screen.dart             # Grid size, names, difficulty
│   └── game_screen.dart              # Main gameplay + scoreboard
├── widgets/
│   └── game_board.dart               # Board renderer + tap detection
├── game/
│   ├── game_state.dart               # Core game engine
│   └── score_service.dart            # Game history persistence
├── ai/
│   └── ai_engine.dart                # AI logic (3 levels)
└── multiplayer/
    └── multiplayer_service.dart      # Bluetooth/Hotspot hook-in stub
```

---

## Setup & Build

### Prerequisites
- GitHub account (no local Flutter needed)
- Push code to a GitHub repo

### Build via GitHub Actions
1. Create a new repo: `noctisi9/dots-and-boxes`
2. Push all files
3. Go to **Actions** tab → **Build Dots & Boxes APK** → **Run workflow**
4. Download APK from the **Artifacts** section

### Local build (optional)
```bash
flutter pub get
flutter build apk --release
```

---

## Multiplayer (Coming Soon)

The multiplayer architecture is wired up in `lib/multiplayer/multiplayer_service.dart`.

To implement, add the `nearby_connections` package and replace `StubMultiplayerService`:

```yaml
# pubspec.yaml
dependencies:
  nearby_connections: ^4.1.0
```

Protocol:
- Host advertises service: `com.noctis.dotsandboxes`
- Guest discovers and connects
- Host sends `GAME_CONFIG`: `{ cols, rows }`
- Moves sent as: `{ o: 'h'|'v', r: row, c: col }`

---

## Colors

| Element | Color |
|---------|-------|
| Background | `#0D1B2A` |
| Accent (brand) | `#00FFCC` |
| Player 1 (Red) | `#E63946` |
| Player 2 (Blue) | `#457BFF` |
| Cards | `#1C2F45` |

---

## Credits

Built by **NOCTIS** (Noctis Nobunga)  
GitHub: `noctisi9`  
Contact: lunganobunga@gmail.com  
Instagram: @justin_blacc
