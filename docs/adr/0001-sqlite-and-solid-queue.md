# 1. SQLite and Solid Queue

Status: accepted

The first plan was PostgreSQL in Docker. The development machine had no working Docker engine, and one process with one disk is enough for a single-node gateway, so Hookline uses SQLite with Solid Queue.

Trade-offs:

- One writer at a time, and one host. Multi-host deployment means moving to PostgreSQL.
- Jobs live in a separate database, so saving a delivery and enqueueing its job is not atomic. The delivery row is therefore the source of truth and a recurring sweep enqueues anything due.
- State changes use conditional `UPDATE`s rather than row locks, so the logic carries over to PostgreSQL.
