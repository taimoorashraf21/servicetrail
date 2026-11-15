# ServiceTrail

Smart service and maintenance management for solar installation and
maintenance companies. One Flutter app for customers, admins and field
technicians.

## What it does

- **Customer** — register equipment (solar panel / inverter / battery),
  submit service requests, track repair status
  (Submitted → Assigned → In Progress → Resolved), view maintenance
  history per equipment.
- **Admin** — dashboard KPIs (open jobs, resolved this month, average
  resolution time), jobs list with status filters, assign technicians,
  analytics (jobs by status, jobs by type, monthly completions).
- **Technician** — assigned tasks, job detail, GPS check-in / check-out
  (graceful fallback when permission is denied), status updates, work
  notes, mark complete.
- **Offline-first** — all data is stored locally with sqflite. Changes
  made offline are queued and shown as "pending sync"; the sync button
  simulates pushing them to the server.

## Demo mode

No backend, no passwords. On launch, pick a role and a seeded demo
account:

- Admin: ServiceTrail Admin
- Customers: Ahmed Raza (Lahore), Fatima Khan (Islamabad),
  Bilal Hussain (Karachi)
- Technicians: Ali Nawaz (Solar Panels), Usman Tariq (Inverters),
  Hassan Ali (Batteries)

Seed data: 6 pieces of equipment and 8 service requests in various
states.

## Build

```sh
flutter pub get
flutter analyze
flutter build apk --debug
```

The debug APK is at `build/app/outputs/flutter-apk/app-debug.apk`.

GitHub Actions (`.github/workflows/build-apk.yml`) builds the same APK
on every push to `main` and uploads it as an artifact.

## Build status (2026-11-16)

`flutter analyze` passes with zero errors. The debug APK is **not yet
built**: the sandbox VM intercepts Java processes' TCP loopback, so the
Gradle client can never talk to its daemon (daemon starts, idles out
after 2 min, client reports "The first result from the daemon was
empty"). Local build is therefore blocked in this VM; use the GitHub
Actions workflow (needs the `taimoorashraf21/servicetrail` repo) to
produce the APK.
