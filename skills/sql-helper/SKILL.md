---

name: sql-helper
description: Write, explain or speed up a SQL query from a plain-language question and the table structure.
---

# SQL helper

1. Ask for the database (PostgreSQL, MySQL, SQLite, other) and the relevant tables and columns. Ask for a few sample rows if the meaning is unclear.
2. Write the query with readable formatting, clear aliases and comments for anything non-obvious.
3. Explain what it does step by step and what each row of the result means.
4. Think about edge cases: nulls, duplicates from joins, time zones and empty results.
5. When speeding up a query, ask for the query plan, then suggest indexes or rewrites and explain why they help.

Only write read-only queries unless the person asks to change data. For `UPDATE` or `DELETE`, show a `SELECT` of the affected rows first.
