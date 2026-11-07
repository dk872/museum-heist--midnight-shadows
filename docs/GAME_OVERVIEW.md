# Museum Heist: Midnight Shadows — game overview

*Based on the Game Design Document. Midnight Shadows Studio.*

## Pitch
2D top-down tactical stealth game for the web browser (Godot 4.x → HTML5/WebAssembly, single player, 12+). You are a professional thief breaking into a city history museum at night. Without weapons or violence you must slip past guards, kill the power to the security system, steal the **Eye of the Pharaoh** and leave unseen. The fun is in reading guard patrol patterns, finding blind spots and using columns and rooms as cover.

## Goal and loss
1. Find the **security panel** and press **E** → the barrier on the central display case goes down.
2. **Hold E for 2 seconds** at the display case → take the artifact.
3. Reach the **Emergency Exit** zone → **win**.

**Lose:** a guard's flashlight beam keeps you in sight until the **Detection Meter reaches 100 %**.

## Controls (PC only; no mobile, no gamepad)
| Key | Action |
|---|---|
| W A S D | Move |
| Mouse | Where the character looks |
| Shift (hold) | Sneak, quiet and slow |
| E / Space | Interact (panel, case; hold for the case) |
| Esc | Pause / restart menu |

## Core features
- **Vision cone:** 60° flashlight cone built with `RayCast2D`. Walls and columns block rays, which creates blind spots.
- **Detection meter:** 0–100 %. Fills faster the closer the guard is, drains when you leave their sight. Shown in the HUD, calm yellow → critical red.
- **Guard state machine:** Patrol → Investigate (suspicious activity) → Alarm.
- **Object interaction:** `Area2D` triggers with delayed activation (panel, case lock, exit door).
- **Web build:** runs in one click in Chrome, Firefox, Safari, Edge; 60 FPS target.

## Levels
| Level | Content |
|---|---|
| **Antiquity Gallery** (tutorial) | Big hall, large marble columns, **one slow guard**, simple layout, straight path to the goal. Teaches cones and cover. |
| **Central Treasury** (master) | Harder spatial puzzle: **two guards with crossing view zones**, the panel is hidden in a side corridor, the artifact stands on a pedestal in the centre. |

## Look and feel
Dark minimalist pixel art (Kenney / OpenGameArt, CC0). Cold dark-blue and graphite environment; warm semi-transparent **yellow guard cones**, **red laser markers**, **gold glow** on the artifact. Minimal UI so the playfield stays readable.

## Characters
- **Thief (player):** agile intruder in a dark hooded suit, silent, turns toward the cursor.
- **Night guard:** uniformed, walks a fixed route with a flashlight.

## Team
| Person | Role | Owns |
|---|---|---|
| Katerina Hasiukova | Game designer / PM | GDD, level balance, TileMap halls, sprints, end-to-end testing |
| Veronika Maslo | Systems & UI | Main menu, HUD (detection bar), win/lose screens, audio, Web build; tests player mechanics |
| Mariia Samoilenko | AI | Guards, vision cones, state machine, patrols; tests UI and system transitions |
| Dmytro Kulyk | Core gameplay | Player controller, collisions, sneaking, interaction (`Area2D`); tests guard AI |

## Schedule
| Dates | Phase |
|---|---|
| 1–6 Oct | GDD |
| 7–20 Oct | Sprint 1: base mechanics prototype |
| 21 Oct – 3 Nov | Sprint 2: subsystem integration |
| 4–15 Nov | Sprint 3: testing and Web build |
| 16–25 Nov | Final polish and rehearsal |

## Risks (GDD)
Deadlines/study load (high/medium) · WebAssembly build problems (medium/**high**) · dynamic flashlight shadows (medium/medium) · Git merge conflicts (medium/medium).

## Monetisation (only if released later)
Non-commercial student project, open source. Possible ethical F2P: cosmetic outfits, flashlight/laser colours, itch.io tip jar ("name your own price"). No pay-to-win.

## MVP checklist
Controllable player · one patrolling guard with yellow cone · collisions that block both player and rays · panel → reveals display case · Game Over at 100 % / win at exit with artifact · no browser errors · 60 FPS · meter and current-objective text on screen.
