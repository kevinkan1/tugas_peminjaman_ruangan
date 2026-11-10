import os
from contextlib import contextmanager

from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:admin@localhost:5432/db_peminjaman",
)

_pool = None


def _get_pool():
    global _pool
    if _pool is None:
        _pool = SimpleConnectionPool(1, 10, DATABASE_URL)
    return _pool


@contextmanager
def get_cursor():
    """Satu request = satu transaksi. Commit kalau sukses, rollback kalau error."""
    pool = _get_pool()
    conn = pool.getconn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        pool.putconn(conn)
