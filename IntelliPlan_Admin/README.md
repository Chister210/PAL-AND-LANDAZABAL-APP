# Admin Panel — StudyApp (Static Demo)

This is a static, responsive admin panel UI demo built with HTML, CSS and JavaScript. It uses Chart.js (via CDN) and mock data in `js/app.js`.

Features
- Modern dark theme and responsive layout
- Collapsible sidebar for mobile
- Overview widgets, user table, analytics charts, subjects, feedback and system logs
- Mock data, ready to be wired to Firestore or your backend

How to run
1. Open `index.html` in your browser (double-click or use your editor's Live Server extension).
2. Charts require internet to load Chart.js from CDN.

Next steps (optional)
- Wire to Firebase/Firestore: replace mock data in `js/app.js` with real queries and secure admin auth.
- Add server-side audit/log viewer and real action handlers (ban user, reset streak, etc.).
- Add tests and a build step if you convert to a framework.

Notes
- This is a front-end mock for demonstration and design. No real data deletion or admin actions are implemented.

Enjoy! — If you want, I can integrate Firebase next (I'll need your config or instructions).