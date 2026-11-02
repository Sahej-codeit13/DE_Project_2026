# DE_Project_2026 – LocalDost

LocalDost is a local market discovery platform designed to help people across India find products, markets, and specific shops easily. Users can explore market details, shop numbers, product categories, ratings, reviews, and photos. The platform aims to connect customers with local businesses and bring offline markets online.

# Local Dost (Sahi bazaar. Sahi dukaan.)

Search a product, see which **markets** sell it, see which **shops** inside the market, open a shop page with products, freshness labels and reviews.

Plain HTML, CSS and JavaScript on the front. Node.js and Express on the back. SQL in the database. No frameworks, no Prisma.

## Run it

```bash
npm install
npm run seed
npm start
```

Open http://localhost:3000

Other commands:

```bash
npm run add-shop
node server.js 4000
node src/seed.js my.json
```

## What is where

```text
server.js               starts the server (http module)
src/app.js              Express app: middleware + routes
src/db.js               database connection
src/schema.sql           all tables
src/seed.js              loads sample data
src/events.js            EventEmitter and logs
src/routes/              URL -> controller
src/controllers/         request handling
src/services/            business logic and SQL
src/middleware/          logger, validation, error handler
src/utils/               helper functions
scripts/add-shop.js      terminal tool
data/seed.json           sample data
public/                  website pages, CSS and JavaScript
```

A request travels: **route -> middleware -> controller -> service -> database**.

## Where each syllabus topic is used

| Topic | Where |
| --- | --- |
| JS, Node.js, Module system | `require` / `module.exports` |
| Process module | `server.js`, `src/seed.js` |
| Path module | `src/db.js`, `src/app.js`, `src/seed.js` |
| Event module | `src/events.js`, services |
| Readline module | `scripts/add-shop.js` |
| FS module | `src/seed.js`, `src/events.js` |
| HTTP module | `server.js` |
| Express routing and REST | `src/routes/` |
| Express middleware | `src/middleware/` |
| Express Router | `src/routes/` |
| Express static files | `src/app.js` |
| MVC architecture | routes, controllers, services, middleware |
| DBMS design | `src/schema.sql` |
| SQL joins and grouping | service files |
| SQL set operations | `search.service.js` |

## Project features

- City, market and shop pages.
- Product search with Hinglish and Hindi synonyms.
- Market and shop search.
- Filters and sorting.
- Freshness, source and verification labels.
- Reviews and ratings.
- English and Hindi toggle.
- Text-size controls and accessible tap targets.
- Google Maps links.

## Future improvements

1. Login, user roles and review moderation.
2. Admin panel.
3. Photo uploads, saved shops and user profiles.
4. Shop availability and shop claims.
5. Typo-tolerant search.

## Important notes

- The data is demo data. Shop numbers, prices, ratings and map coordinates are examples.
- SQLite is used to keep setup simple. The project can be migrated to PostgreSQL later.
- Text from the database is escaped before being displayed on the page to prevent HTML injection.