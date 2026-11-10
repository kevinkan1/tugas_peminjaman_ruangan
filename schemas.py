from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field, model_validator

Status = Literal["diajukan", "disetujui", "ditolak", "dibatalkan", "selesai"]


class GedungIn(BaseModel):
    kode: str = Field(min_length=1, max_length=10)
    nama: str = Field(min_length=1, max_length=100)


class RuanganIn(BaseModel):
    kode: str = Field(min_length=1, max_length=30)
    nama: str = Field(min_length=1, max_length=100)
    gedung_id: int
    lantai: int = 1
    kapasitas: int = Field(gt=0)
    fasilitas: Optional[str] = None
    aktif: bool = True


class UserIn(BaseModel):
    nama: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=3, max_length=100)
    password: str = Field(min_length=6, max_length=72)  # bcrypt maksimal 72 byte
    role: Literal["admin", "peminjam"] = "peminjam"
    no_hp: Optional[str] = Field(default=None, max_length=20)


class UserUpdate(BaseModel):
    nama: str = Field(min_length=1, max_length=100)
    email: str = Field(min_length=3, max_length=100)
    role: Literal["admin", "peminjam"] = "peminjam"
    no_hp: Optional[str] = Field(default=None, max_length=20)
    password: Optional[str] = Field(default=None, min_length=6, max_length=72)  # kosong = tidak diganti


class PeminjamanIn(BaseModel):
    user_id: int
    ruangan_id: int
    keperluan: str = Field(min_length=1, max_length=200)
    jumlah_peserta: int = Field(default=1, gt=0)
    mulai: datetime
    selesai: datetime

    @model_validator(mode="after")
    def cek_waktu(self):
        if self.selesai <= self.mulai:
            raise ValueError("selesai harus lebih besar dari mulai")
        return self


class StatusIn(BaseModel):
    status: Status
    catatan_admin: Optional[str] = None
