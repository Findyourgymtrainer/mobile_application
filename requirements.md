# Gym Tracker – Requirements

## 1. Overview
A front-end web application for logging and reviewing gym workouts. Built with React + Vite, runs in the browser, and stores data locally (no backend).

## 2. Tech Stack
- React (JSX) with Vite
- Plain CSS (`src/App.css`, `src/index.css`)
- Browser `localStorage` for persistence
- Node.js 24 / npm 11 for tooling

## 3. Functional Requirements

### Implemented
| ID | Requirement |
|----|-------------|
| FR-1 | User can add a workout entry with exercise name, sets, reps, weight (kg) and day of week. |
| FR-2 | Exercise name is required; empty names are rejected. |
| FR-3 | User can delete a workout entry. |
| FR-4 | User can filter the list by day (All, Mon–Sun). |
| FR-5 | App shows the number of exercises shown and total volume (sets × reps × kg) for the current filter. |
| FR-6 | Workouts persist across page reloads via `localStorage`. |
| FR-7 | An empty-state message is shown when there are no workouts. |

### Planned / To Be Confirmed
| ID | Requirement |
|----|-------------|
| FR-8 | Edit an existing workout entry. |
| FR-9 | Record the date of each workout and view history. |
| FR-10 | Progress charts (e.g. volume over time, per-exercise). |
| FR-11 | Exercise library / autocomplete. |
| FR-12 | Export / import workout data (JSON or CSV). |
| FR-13 | User accounts and backend sync (if required). |
| FR-14 | Figma-based UI design to be implemented. |

## 4. Non-Functional Requirements
- **Responsive:** usable on desktop and mobile screen widths.
- **Theme:** supports light and dark mode via system preference.
- **Performance:** instant interactions; production bundle under ~250 kB.
- **Resilience:** app must not crash if `localStorage` is empty, corrupted or unavailable.
- **Accessibility:** form inputs are labelled and usable by keyboard.
- **Browser support:** current versions of Chrome, Edge, Firefox and Safari.

## 5. Data Model
Workout:
```
{
  id:       number   // Date.now() timestamp
  exercise: string
  sets:     number
  reps:     number
  weight:   number   // kg
  day:      'Mon' | 'Tue' | 'Wed' | 'Thu' | 'Fri' | 'Sat' | 'Sun'
}
```
Stored as a JSON array under the `workouts` key in `localStorage`.

## 6. Running the App
```
npm install
npm run dev      # http://localhost:5173
npm run build    # production build in dist/
```

## 7. Open Questions
- Is this for personal use or for a gym with members and trainers?
- Is a backend or login needed, or is local-only storage enough?
- Should the UI follow a specific Figma design?
