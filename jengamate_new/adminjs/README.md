# JengaMate AdminJS

Lightweight AdminJS scaffold to administer the Postgres database used by the app.

Quick start:

1. Install dependencies:

```bash
cd adminjs
npm install
```

2. Set `DATABASE_URL` env var pointing to your Postgres database (Supabase local or remote). Example:

```bash
export DATABASE_URL=postgres://postgres:password@localhost:5432/jengamate
```

3. Start server:

```bash
npm start
```

Open `http://localhost:3001/admin`

Notes:
- This scaffold is intentionally small — extend `index.js` to map more models and secure the AdminJS router with authentication in production.


