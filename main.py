from datetime import date, datetime
from pathlib import Path
from typing import Optional

import bcrypt
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from psycopg2 import errors

from database import get_cursor
from schemas import GedungIn, PeminjamanIn, RuanganIn, StatusIn, UserIn, UserUpdate

app = FastAPI(title="API Peminjaman Ruangan Kampus")

BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"
TEMPLATES_DIR = BASE_DIR / "templates"

templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


# app.js ada di folder templates/ (bukan static/), jadi /static/app.js tidak akan ketemu.
# Route ini harus didefinisikan SEBELUM app.mount("/static") supaya diprioritaskan.
# Solusi yang benar: pindahkan app.js ke static/, lalu route ini boleh dihapus.
@app.get("/static/app.js", include_in_schema=False)
def serve_app_js():
    for p in (STATIC_DIR / "app.js", TEMPLATES_DIR / "app.js"):
        if p.exists():
            return FileResponse(p, media_type="application/javascript")
    raise HTTPException(404, "app.js tidak ditemukan di static/ maupun templates/")


app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


# ---------- helper halaman HTML ----------
def wants_html(request: Request) -> bool:
    """True kalau request datang dari navigasi browser (bukan fetch/Swagger)."""
    return "text/html" in request.headers.get("accept", "")


def render(request: Request, name: str, **context):
    return templates.TemplateResponse(request, name, context)


# ---------- error handler untuk constraint / trigger database ----------
def _err(status: int, detail: str):
    return JSONResponse(status_code=status, content={"detail": detail})


@app.exception_handler(errors.UniqueViolation)
async def unique_handler(request: Request, exc):
    return _err(409, "Data duplikat (kode / nama / email sudah dipakai)")


@app.exception_handler(errors.ForeignKeyViolation)
async def fk_handler(request: Request, exc):
    return _err(409, "Relasi tidak valid: data induk tidak ada, atau data masih dipakai tabel lain")


@app.exception_handler(errors.ExclusionViolation)
async def exclusion_handler(request: Request, exc):
    return _err(409, "Bentrok jadwal: ruangan sudah diajukan/disetujui pada rentang waktu tersebut")


@app.exception_handler(errors.CheckViolation)
async def check_handler(request: Request, exc):
    return _err(400, f"Data melanggar aturan database: {exc.diag.constraint_name}")


@app.exception_handler(errors.RaiseException)
async def trigger_handler(request: Request, exc):
    # pesan dari RAISE EXCEPTION di trigger fn_validasi_peminjaman
    return _err(400, exc.diag.message_primary or "Ditolak oleh validasi database")


# ---------- helper ----------
def one_or_404(cur, label: str):
    row = cur.fetchone()
    if not row:
        raise HTTPException(404, f"{label} tidak ditemukan")
    return row


def hash_password(pw: str) -> str:
    return bcrypt.hashpw(pw.encode(), bcrypt.gensalt()).decode()


USER_COLS = "id, nama, email, role, no_hp, created_at"  # password_hash TIDAK PERNAH dikembalikan

RUANGAN_SELECT = """
    SELECT r.*, g.kode AS kode_gedung, g.nama AS gedung
    FROM ruangan r JOIN gedung g ON g.id = r.gedung_id
"""

# transisi status yang diizinkan
TRANSISI = {
    "diajukan": {"disetujui", "ditolak", "dibatalkan"},
    "disetujui": {"dibatalkan", "selesai"},
    "ditolak": set(),
    "dibatalkan": set(),
    "selesai": set(),
}


def get_ruangan(cur, id: int):
    cur.execute(RUANGAN_SELECT + " WHERE r.id = %s", (id,))
    return one_or_404(cur, "Ruangan")


def get_peminjaman(cur, id: int):
    cur.execute("SELECT * FROM v_peminjaman_detail WHERE id = %s", (id,))
    return one_or_404(cur, "Peminjaman")


def cek_ruangan_layak(cur, ruangan_id: int, jumlah_peserta: int):
    cur.execute("SELECT kapasitas, aktif FROM ruangan WHERE id = %s", (ruangan_id,))
    r = one_or_404(cur, "Ruangan")
    if not r["aktif"]:
        raise HTTPException(409, "Ruangan sedang tidak aktif")
    if jumlah_peserta > r["kapasitas"]:
        raise HTTPException(400, f"Jumlah peserta ({jumlah_peserta}) melebihi kapasitas ruangan ({r['kapasitas']})")


# ====================== HALAMAN UTAMA ======================
@app.get("/", response_class=HTMLResponse, include_in_schema=False)
def halaman_index(request: Request):
    return render(request, "index.html", active="index")


# ====================== GEDUNG ======================
@app.post("/gedung", status_code=201, tags=["gedung"])
def tambah_gedung(data: GedungIn):
    with get_cursor() as cur:
        cur.execute("INSERT INTO gedung (kode, nama) VALUES (%s, %s) RETURNING *", (data.kode, data.nama))
        return cur.fetchone()


@app.get("/gedung", tags=["gedung"])
def daftar_gedung(request: Request):
    if wants_html(request):
        return render(request, "gedung.html", active="gedung")
    with get_cursor() as cur:
        cur.execute("SELECT * FROM gedung ORDER BY kode")
        return cur.fetchall()


@app.get("/gedung/{id}", tags=["gedung"])
def detail_gedung(id: int):
    with get_cursor() as cur:
        cur.execute("SELECT * FROM gedung WHERE id = %s", (id,))
        return one_or_404(cur, "Gedung")


@app.put("/gedung/{id}", tags=["gedung"])
def ubah_gedung(id: int, data: GedungIn):
    with get_cursor() as cur:
        cur.execute("UPDATE gedung SET kode=%s, nama=%s WHERE id=%s RETURNING *", (data.kode, data.nama, id))
        return one_or_404(cur, "Gedung")


@app.delete("/gedung/{id}", tags=["gedung"])
def hapus_gedung(id: int):
    with get_cursor() as cur:
        cur.execute("DELETE FROM gedung WHERE id = %s RETURNING id", (id,))
        one_or_404(cur, "Gedung")
    return {"detail": "Gedung dihapus"}


# ====================== RUANGAN ======================
@app.post("/ruangan", status_code=201, tags=["ruangan"])
def tambah_ruangan(data: RuanganIn):
    with get_cursor() as cur:
        cur.execute(
            """INSERT INTO ruangan (kode, nama, gedung_id, lantai, kapasitas, fasilitas, aktif)
               VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id""",
            (data.kode, data.nama, data.gedung_id, data.lantai, data.kapasitas, data.fasilitas, data.aktif),
        )
        return get_ruangan(cur, cur.fetchone()["id"])


@app.get("/ruangan", tags=["ruangan"])
def daftar_ruangan(
    request: Request,
    gedung_id: Optional[int] = None,
    min_kapasitas: Optional[int] = None,
    aktif: Optional[bool] = None,
):
    if wants_html(request):
        return render(request, "ruangan.html", active="ruangan")
    conds, params = [], []
    if gedung_id is not None:
        conds.append("r.gedung_id = %s")
        params.append(gedung_id)
    if min_kapasitas is not None:
        conds.append("r.kapasitas >= %s")
        params.append(min_kapasitas)
    if aktif is not None:
        conds.append("r.aktif = %s")
        params.append(aktif)
    where = " WHERE " + " AND ".join(conds) if conds else ""
    with get_cursor() as cur:
        cur.execute(RUANGAN_SELECT + where + " ORDER BY g.kode, r.kode", params)
        return cur.fetchall()


@app.get("/ruangan/tersedia", tags=["ruangan"])
def ruangan_tersedia(mulai: datetime, selesai: datetime, min_kapasitas: Optional[int] = None):
    """Ruangan aktif yang kosong (tidak ada diajukan/disetujui) pada rentang waktu itu. Logika sama dengan no_bentrok."""
    if selesai <= mulai:
        raise HTTPException(422, "selesai harus lebih besar dari mulai")
    sql = RUANGAN_SELECT + """
        WHERE r.aktif AND NOT EXISTS (
            SELECT 1 FROM peminjaman p
            WHERE p.ruangan_id = r.id
              AND p.status IN ('diajukan', 'disetujui')
              AND tsrange(p.mulai, p.selesai) && tsrange(%s, %s))
    """
    params = [mulai, selesai]
    if min_kapasitas is not None:
        sql += " AND r.kapasitas >= %s"
        params.append(min_kapasitas)
    with get_cursor() as cur:
        cur.execute(sql + " ORDER BY g.kode, r.kode", params)
        return cur.fetchall()


@app.get("/ruangan/{id}", tags=["ruangan"])
def detail_ruangan(id: int):
    with get_cursor() as cur:
        return get_ruangan(cur, id)


@app.put("/ruangan/{id}", tags=["ruangan"])
def ubah_ruangan(id: int, data: RuanganIn):
    with get_cursor() as cur:
        cur.execute(
            """UPDATE ruangan SET kode=%s, nama=%s, gedung_id=%s, lantai=%s,
                   kapasitas=%s, fasilitas=%s, aktif=%s WHERE id=%s RETURNING id""",
            (data.kode, data.nama, data.gedung_id, data.lantai, data.kapasitas, data.fasilitas, data.aktif, id),
        )
        one_or_404(cur, "Ruangan")
        return get_ruangan(cur, id)


@app.delete("/ruangan/{id}", tags=["ruangan"])
def hapus_ruangan(id: int):
    """Gagal (409) kalau ruangan pernah dipinjam (ON DELETE RESTRICT). Untuk menonaktifkan, ubah aktif=false lewat PUT."""
    with get_cursor() as cur:
        cur.execute("DELETE FROM ruangan WHERE id = %s RETURNING id", (id,))
        one_or_404(cur, "Ruangan")
    return {"detail": "Ruangan dihapus"}


@app.get("/ruangan/{id}/jadwal", tags=["ruangan"])
def jadwal_ruangan(id: int, tanggal: date):
    """Jadwal aktif (diajukan + disetujui) yang menyentuh tanggal tersebut, dari view v_jadwal_aktif."""
    with get_cursor() as cur:
        get_ruangan(cur, id)
        cur.execute(
            """SELECT * FROM v_jadwal_aktif
               WHERE ruangan_id = %s AND mulai < %s::date + 1 AND selesai > %s::date
               ORDER BY mulai""",
            (id, tanggal, tanggal),
        )
        return cur.fetchall()


# ====================== USERS ======================
@app.post("/users", status_code=201, tags=["users"])
def tambah_user(data: UserIn):
    with get_cursor() as cur:
        cur.execute(
            f"""INSERT INTO users (nama, email, password_hash, role, no_hp)
                VALUES (%s, %s, %s, %s, %s) RETURNING {USER_COLS}""",
            (data.nama, data.email, hash_password(data.password), data.role, data.no_hp),
        )
        return cur.fetchone()


@app.get("/users", tags=["users"])
def daftar_user(request: Request, role: Optional[str] = None):
    if wants_html(request):
        return render(request, "users.html", active="users")
    with get_cursor() as cur:
        if role:
            cur.execute(f"SELECT {USER_COLS} FROM users WHERE role = %s ORDER BY nama", (role,))
        else:
            cur.execute(f"SELECT {USER_COLS} FROM users ORDER BY nama")
        return cur.fetchall()


@app.get("/users/{id}", tags=["users"])
def detail_user(id: int):
    with get_cursor() as cur:
        cur.execute(f"SELECT {USER_COLS} FROM users WHERE id = %s", (id,))
        return one_or_404(cur, "User")


@app.put("/users/{id}", tags=["users"])
def ubah_user(id: int, data: UserUpdate):
    with get_cursor() as cur:
        if data.password:
            cur.execute(
                f"""UPDATE users SET nama=%s, email=%s, role=%s, no_hp=%s, password_hash=%s
                    WHERE id=%s RETURNING {USER_COLS}""",
                (data.nama, data.email, data.role, data.no_hp, hash_password(data.password), id),
            )
        else:
            cur.execute(
                f"""UPDATE users SET nama=%s, email=%s, role=%s, no_hp=%s
                    WHERE id=%s RETURNING {USER_COLS}""",
                (data.nama, data.email, data.role, data.no_hp, id),
            )
        return one_or_404(cur, "User")


@app.delete("/users/{id}", tags=["users"])
def hapus_user(id: int):
    with get_cursor() as cur:
        cur.execute("DELETE FROM users WHERE id = %s RETURNING id", (id,))
        one_or_404(cur, "User")
    return {"detail": "User dihapus"}


# ====================== PEMINJAMAN ======================
@app.post("/peminjaman", status_code=201, tags=["peminjaman"])
def ajukan_peminjaman(data: PeminjamanIn):
    """Status awal selalu 'diajukan'. Bentrok jadwal ditolak oleh constraint no_bentrok (409)."""
    with get_cursor() as cur:
        cek_ruangan_layak(cur, data.ruangan_id, data.jumlah_peserta)
        cur.execute(
            """INSERT INTO peminjaman (user_id, ruangan_id, keperluan, jumlah_peserta, mulai, selesai)
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
            (data.user_id, data.ruangan_id, data.keperluan, data.jumlah_peserta, data.mulai, data.selesai),
        )
        return get_peminjaman(cur, cur.fetchone()["id"])


@app.get("/peminjaman", tags=["peminjaman"])
def daftar_peminjaman(
    request: Request,
    user_id: Optional[int] = None,
    ruangan_id: Optional[int] = None,
    status: Optional[str] = None,
    tanggal: Optional[date] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    if wants_html(request):
        return render(request, "peminjaman.html", active="peminjaman")
    conds, params = [], []
    if user_id is not None:
        conds.append("user_id = %s")
        params.append(user_id)
    if ruangan_id is not None:
        conds.append("ruangan_id = %s")
        params.append(ruangan_id)
    if status:
        conds.append("status = %s")
        params.append(status)
    if tanggal:
        conds.append("mulai::date = %s")
        params.append(tanggal)
    where = " WHERE " + " AND ".join(conds) if conds else ""
    with get_cursor() as cur:
        cur.execute(
            f"SELECT * FROM v_peminjaman_detail{where} ORDER BY mulai DESC, id DESC LIMIT %s OFFSET %s",
            params + [limit, offset],
        )
        return cur.fetchall()


@app.get("/peminjaman/{id}", tags=["peminjaman"])
def detail_peminjaman(id: int):
    with get_cursor() as cur:
        return get_peminjaman(cur, id)


@app.get("/peminjaman/{id}/log", tags=["peminjaman"])
def log_peminjaman(id: int):
    """Riwayat perubahan status (diisi otomatis oleh trigger trg_log_status)."""
    with get_cursor() as cur:
        get_peminjaman(cur, id)
        cur.execute("SELECT * FROM log_status WHERE peminjaman_id = %s ORDER BY waktu, id", (id,))
        return cur.fetchall()


@app.put("/peminjaman/{id}", tags=["peminjaman"])
def ubah_peminjaman(id: int, data: PeminjamanIn):
    """Hanya boleh diubah selama masih 'diajukan'."""
    with get_cursor() as cur:
        cur.execute("SELECT status FROM peminjaman WHERE id = %s FOR UPDATE", (id,))
        lama = one_or_404(cur, "Peminjaman")
        if lama["status"] != "diajukan":
            raise HTTPException(409, "Hanya peminjaman berstatus 'diajukan' yang bisa diubah")
        cek_ruangan_layak(cur, data.ruangan_id, data.jumlah_peserta)
        cur.execute(
            """UPDATE peminjaman SET user_id=%s, ruangan_id=%s, keperluan=%s, jumlah_peserta=%s,
                   mulai=%s, selesai=%s, updated_at=now() WHERE id=%s""",
            (data.user_id, data.ruangan_id, data.keperluan, data.jumlah_peserta, data.mulai, data.selesai, id),
        )
        return get_peminjaman(cur, id)


@app.patch("/peminjaman/{id}/status", tags=["peminjaman"])
def ubah_status(id: int, data: StatusIn):
    with get_cursor() as cur:
        cur.execute("SELECT status FROM peminjaman WHERE id = %s FOR UPDATE", (id,))
        lama = one_or_404(cur, "Peminjaman")["status"]
        if data.status not in TRANSISI[lama]:
            boleh = ", ".join(sorted(TRANSISI[lama])) or "(tidak ada, status sudah final)"
            raise HTTPException(409, f"Status '{lama}' tidak bisa menjadi '{data.status}'. Yang diizinkan: {boleh}")
        cur.execute(
            """UPDATE peminjaman SET status = %s, catatan_admin = COALESCE(%s, catatan_admin),
                   updated_at = now() WHERE id = %s""",
            (data.status, data.catatan_admin, id),
        )
        return get_peminjaman(cur, id)


@app.delete("/peminjaman/{id}", tags=["peminjaman"])
def hapus_peminjaman(id: int):
    """Hapus permanen (log_status ikut terhapus via CASCADE). Untuk membatalkan, lebih baik pakai PATCH status."""
    with get_cursor() as cur:
        cur.execute("DELETE FROM peminjaman WHERE id = %s RETURNING id", (id,))
        one_or_404(cur, "Peminjaman")
    return {"detail": "Peminjaman dihapus"}


# ====================== LAPORAN ======================
@app.get("/laporan/ruangan-terpopuler", tags=["laporan"])
def ruangan_terpopuler(limit: int = Query(5, ge=1, le=50)):
    with get_cursor() as cur:
        cur.execute(
            """SELECT r.id, r.kode, r.nama, g.nama AS gedung,
                      COUNT(p.id) AS total_peminjaman,
                      COALESCE(ROUND(SUM(EXTRACT(epoch FROM (p.selesai - p.mulai))) / 3600.0, 2), 0) AS total_jam
               FROM ruangan r
               JOIN gedung g ON g.id = r.gedung_id
               LEFT JOIN peminjaman p ON p.ruangan_id = r.id AND p.status IN ('disetujui', 'selesai')
               GROUP BY r.id, g.nama
               ORDER BY total_peminjaman DESC, total_jam DESC, r.nama
               LIMIT %s""",
            (limit,),
        )
        return cur.fetchall()


@app.get("/laporan/rekap-status", tags=["laporan"])
def rekap_status():
    with get_cursor() as cur:
        cur.execute("SELECT status, COUNT(*) AS jumlah FROM peminjaman GROUP BY status ORDER BY jumlah DESC")
        return cur.fetchall()
