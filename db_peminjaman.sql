--
-- PostgreSQL database dump
--

\restrict 3VN9X6nUKctXNRkllMaV2JWId4U9sI3oGkPobc1U0jEL9g8lpdnJagwWP64rBcm

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-11-10 10:32:55

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5382 (class 1262 OID 16534)
-- Name: db_peminjaman; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE db_peminjaman WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_Indonesia.1252';


ALTER DATABASE db_peminjaman OWNER TO postgres;

\unrestrict 3VN9X6nUKctXNRkllMaV2JWId4U9sI3oGkPobc1U0jEL9g8lpdnJagwWP64rBcm
\connect db_peminjaman
\restrict 3VN9X6nUKctXNRkllMaV2JWId4U9sI3oGkPobc1U0jEL9g8lpdnJagwWP64rBcm

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 17282)
-- Name: gedung; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gedung (
    id integer NOT NULL,
    kode character varying(10) NOT NULL,
    nama character varying(100) NOT NULL
);


ALTER TABLE public.gedung OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 17281)
-- Name: gedung_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gedung_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gedung_id_seq OWNER TO postgres;

--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 222
-- Name: gedung_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gedung_id_seq OWNED BY public.gedung.id;


--
-- TOC entry 229 (class 1259 OID 17366)
-- Name: log_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_status (
    id integer NOT NULL,
    peminjaman_id integer NOT NULL,
    status_lama character varying(20),
    status_baru character varying(20) NOT NULL,
    waktu timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.log_status OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 17365)
-- Name: log_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_status_id_seq OWNER TO postgres;

--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 228
-- Name: log_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_status_id_seq OWNED BY public.log_status.id;


--
-- TOC entry 227 (class 1259 OID 17325)
-- Name: peminjaman; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.peminjaman (
    id integer NOT NULL,
    user_id integer NOT NULL,
    ruangan_id integer NOT NULL,
    keperluan character varying(200) NOT NULL,
    jumlah_peserta integer DEFAULT 1 NOT NULL,
    mulai timestamp without time zone NOT NULL,
    selesai timestamp without time zone NOT NULL,
    status character varying(20) DEFAULT 'diajukan'::character varying NOT NULL,
    catatan_admin text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT peminjaman_check CHECK ((selesai > mulai)),
    CONSTRAINT peminjaman_jumlah_peserta_check CHECK ((jumlah_peserta > 0)),
    CONSTRAINT peminjaman_status_check CHECK (((status)::text = ANY ((ARRAY['diajukan'::character varying, 'disetujui'::character varying, 'ditolak'::character varying, 'dibatalkan'::character varying, 'selesai'::character varying])::text[])))
);


ALTER TABLE public.peminjaman OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 17324)
-- Name: peminjaman_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.peminjaman_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.peminjaman_id_seq OWNER TO postgres;

--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 226
-- Name: peminjaman_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.peminjaman_id_seq OWNED BY public.peminjaman.id;


--
-- TOC entry 225 (class 1259 OID 17296)
-- Name: ruangan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ruangan (
    id integer NOT NULL,
    kode character varying(30) NOT NULL,
    nama character varying(100) NOT NULL,
    gedung_id integer NOT NULL,
    lantai integer DEFAULT 1 NOT NULL,
    kapasitas integer NOT NULL,
    fasilitas text,
    aktif boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT ruangan_kapasitas_check CHECK ((kapasitas > 0))
);


ALTER TABLE public.ruangan OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 17295)
-- Name: ruangan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ruangan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ruangan_id_seq OWNER TO postgres;

--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 224
-- Name: ruangan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ruangan_id_seq OWNED BY public.ruangan.id;


--
-- TOC entry 221 (class 1259 OID 17262)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    nama character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) DEFAULT 'peminjam'::character varying NOT NULL,
    no_hp character varying(20),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'peminjam'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 17261)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 220
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 230 (class 1259 OID 17386)
-- Name: v_peminjaman_detail; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_peminjaman_detail AS
 SELECT p.id,
    p.mulai,
    p.selesai,
    round((EXTRACT(epoch FROM (p.selesai - p.mulai)) / 3600.0), 2) AS durasi_jam,
    p.status,
    p.keperluan,
    p.jumlah_peserta,
    p.catatan_admin,
    u.id AS user_id,
    u.nama AS peminjam,
    u.email,
    r.id AS ruangan_id,
    r.kode AS kode_ruangan,
    r.nama AS ruangan,
    g.nama AS gedung,
    p.created_at
   FROM (((public.peminjaman p
     JOIN public.users u ON ((u.id = p.user_id)))
     JOIN public.ruangan r ON ((r.id = p.ruangan_id)))
     JOIN public.gedung g ON ((g.id = r.gedung_id)));


ALTER VIEW public.v_peminjaman_detail OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 17391)
-- Name: v_jadwal_aktif; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_jadwal_aktif AS
 SELECT id,
    mulai,
    selesai,
    durasi_jam,
    status,
    keperluan,
    jumlah_peserta,
    catatan_admin,
    user_id,
    peminjam,
    email,
    ruangan_id,
    kode_ruangan,
    ruangan,
    gedung,
    created_at
   FROM public.v_peminjaman_detail
  WHERE ((status)::text = ANY ((ARRAY['diajukan'::character varying, 'disetujui'::character varying])::text[]));


ALTER VIEW public.v_jadwal_aktif OWNER TO postgres;

--
-- TOC entry 5171 (class 2604 OID 17285)
-- Name: gedung id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gedung ALTER COLUMN id SET DEFAULT nextval('public.gedung_id_seq'::regclass);


--
-- TOC entry 5181 (class 2604 OID 17369)
-- Name: log_status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_status ALTER COLUMN id SET DEFAULT nextval('public.log_status_id_seq'::regclass);


--
-- TOC entry 5176 (class 2604 OID 17328)
-- Name: peminjaman id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peminjaman ALTER COLUMN id SET DEFAULT nextval('public.peminjaman_id_seq'::regclass);


--
-- TOC entry 5172 (class 2604 OID 17299)
-- Name: ruangan id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ruangan ALTER COLUMN id SET DEFAULT nextval('public.ruangan_id_seq'::regclass);


--
-- TOC entry 5168 (class 2604 OID 17265)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 5370 (class 0 OID 17282)
-- Dependencies: 223
-- Data for Name: gedung; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.gedung VALUES (1, 'A', 'Gedung A - Kuliah Umum');
INSERT INTO public.gedung VALUES (2, 'B', 'Gedung B - Laboratorium');
INSERT INTO public.gedung VALUES (3, 'C', 'Gedung C - Serbaguna');


--
-- TOC entry 5376 (class 0 OID 17366)
-- Dependencies: 229
-- Data for Name: log_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.log_status VALUES (1, 1, NULL, 'disetujui', '2026-11-10 10:12:40.723611');
INSERT INTO public.log_status VALUES (2, 2, NULL, 'disetujui', '2026-11-10 10:12:40.723611');
INSERT INTO public.log_status VALUES (3, 3, NULL, 'diajukan', '2026-11-10 10:12:40.723611');
INSERT INTO public.log_status VALUES (4, 4, NULL, 'diajukan', '2026-11-10 10:12:40.723611');
INSERT INTO public.log_status VALUES (5, 5, NULL, 'ditolak', '2026-11-10 10:12:40.723611');


--
-- TOC entry 5374 (class 0 OID 17325)
-- Dependencies: 227
-- Data for Name: peminjaman; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.peminjaman VALUES (1, 2, 1, 'Kelas tambahan Basis Data', 35, '2026-11-11 09:00:00', '2026-11-11 11:00:00', 'disetujui', NULL, '2026-11-10 10:12:40.723611', '2026-11-10 10:12:40.723611');
INSERT INTO public.peminjaman VALUES (2, 3, 4, 'Praktikum pengganti', 28, '2026-11-11 13:00:00', '2026-11-11 15:00:00', 'disetujui', NULL, '2026-11-10 10:12:40.723611', '2026-11-10 10:12:40.723611');
INSERT INTO public.peminjaman VALUES (3, 4, 3, 'Seminar proposal skripsi', 60, '2026-11-12 10:00:00', '2026-11-12 12:00:00', 'diajukan', NULL, '2026-11-10 10:12:40.723611', '2026-11-10 10:12:40.723611');
INSERT INTO public.peminjaman VALUES (4, 2, 6, 'Rapat organisasi', 150, '2026-11-13 14:00:00', '2026-11-13 17:00:00', 'diajukan', NULL, '2026-11-10 10:12:40.723611', '2026-11-10 10:12:40.723611');
INSERT INTO public.peminjaman VALUES (5, 3, 2, 'Bimbingan kelompok', 20, '2026-11-14 08:00:00', '2026-11-14 10:00:00', 'ditolak', NULL, '2026-11-10 10:12:40.723611', '2026-11-10 10:12:40.723611');


--
-- TOC entry 5372 (class 0 OID 17296)
-- Dependencies: 225
-- Data for Name: ruangan; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.ruangan VALUES (1, 'A-101', 'Ruang Kelas A101', 1, 1, 40, 'Proyektor, AC, Whiteboard', true, '2026-11-10 10:12:40.723611');
INSERT INTO public.ruangan VALUES (2, 'A-102', 'Ruang Kelas A102', 1, 1, 40, 'Proyektor, AC', true, '2026-11-10 10:12:40.723611');
INSERT INTO public.ruangan VALUES (3, 'A-201', 'Ruang Seminar A201', 1, 2, 80, 'Proyektor, AC, Sound System', true, '2026-11-10 10:12:40.723611');
INSERT INTO public.ruangan VALUES (4, 'B-101', 'Lab Komputer 1', 2, 1, 30, 'PC 30 unit, AC, Proyektor', true, '2026-11-10 10:12:40.723611');
INSERT INTO public.ruangan VALUES (5, 'B-102', 'Lab Komputer 2', 2, 1, 30, 'PC 30 unit, AC', true, '2026-11-10 10:12:40.723611');
INSERT INTO public.ruangan VALUES (6, 'C-001', 'Aula Utama', 3, 1, 300, 'Panggung, Sound System, AC', true, '2026-11-10 10:12:40.723611');


--
-- TOC entry 5368 (class 0 OID 17262)
-- Dependencies: 221
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES (1, 'Admin Kampus', 'admin@kampus.ac.id', '$2b$12$PLACEHOLDER_HASH_ADMIN', 'admin', '081200000001', '2026-11-10 10:12:40.723611');
INSERT INTO public.users VALUES (2, 'Budi Santoso', 'budi@kampus.ac.id', '$2b$12$PLACEHOLDER_HASH_BUDI', 'peminjam', '081200000002', '2026-11-10 10:12:40.723611');
INSERT INTO public.users VALUES (3, 'Siti Aminah', 'siti@kampus.ac.id', '$2b$12$PLACEHOLDER_HASH_SITI', 'peminjam', '081200000003', '2026-11-10 10:12:40.723611');
INSERT INTO public.users VALUES (4, 'Dr. Rahmat', 'rahmat@kampus.ac.id', '$2b$12$PLACEHOLDER_HASH_RAHMAT', 'peminjam', '081200000004', '2026-11-10 10:12:40.723611');


--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 222
-- Name: gedung_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gedung_id_seq', 3, true);


--
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 228
-- Name: log_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_status_id_seq', 5, true);


--
-- TOC entry 5390 (class 0 OID 0)
-- Dependencies: 226
-- Name: peminjaman_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.peminjaman_id_seq', 5, true);


--
-- TOC entry 5391 (class 0 OID 0)
-- Dependencies: 224
-- Name: ruangan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ruangan_id_seq', 6, true);


--
-- TOC entry 5392 (class 0 OID 0)
-- Dependencies: 220
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 4, true);


--
-- TOC entry 5193 (class 2606 OID 17292)
-- Name: gedung gedung_kode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gedung
    ADD CONSTRAINT gedung_kode_key UNIQUE (kode);


--
-- TOC entry 5195 (class 2606 OID 17294)
-- Name: gedung gedung_nama_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gedung
    ADD CONSTRAINT gedung_nama_key UNIQUE (nama);


--
-- TOC entry 5197 (class 2606 OID 17290)
-- Name: gedung gedung_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gedung
    ADD CONSTRAINT gedung_pkey PRIMARY KEY (id);


--
-- TOC entry 5211 (class 2606 OID 17376)
-- Name: log_status log_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_status
    ADD CONSTRAINT log_status_pkey PRIMARY KEY (id);


--
-- TOC entry 5207 (class 2606 OID 17351)
-- Name: peminjaman no_bentrok; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peminjaman
    ADD CONSTRAINT no_bentrok EXCLUDE USING gist (ruangan_id WITH =, tsrange(mulai, selesai) WITH &&) WHERE (((status)::text = ANY ((ARRAY['diajukan'::character varying, 'disetujui'::character varying])::text[])));


--
-- TOC entry 5209 (class 2606 OID 17349)
-- Name: peminjaman peminjaman_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peminjaman
    ADD CONSTRAINT peminjaman_pkey PRIMARY KEY (id);


--
-- TOC entry 5200 (class 2606 OID 17317)
-- Name: ruangan ruangan_kode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ruangan
    ADD CONSTRAINT ruangan_kode_key UNIQUE (kode);


--
-- TOC entry 5202 (class 2606 OID 17315)
-- Name: ruangan ruangan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ruangan
    ADD CONSTRAINT ruangan_pkey PRIMARY KEY (id);


--
-- TOC entry 5189 (class 2606 OID 17280)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5191 (class 2606 OID 17278)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5203 (class 1259 OID 17362)
-- Name: idx_peminjaman_ruangan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_peminjaman_ruangan ON public.peminjaman USING btree (ruangan_id, mulai);


--
-- TOC entry 5204 (class 1259 OID 17364)
-- Name: idx_peminjaman_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_peminjaman_status ON public.peminjaman USING btree (status);


--
-- TOC entry 5205 (class 1259 OID 17363)
-- Name: idx_peminjaman_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_peminjaman_user ON public.peminjaman USING btree (user_id);


--
-- TOC entry 5198 (class 1259 OID 17323)
-- Name: idx_ruangan_gedung; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ruangan_gedung ON public.ruangan USING btree (gedung_id);


--
-- TOC entry 5216 (class 2620 OID 17385)
-- Name: peminjaman trg_log_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_status AFTER INSERT OR UPDATE ON public.peminjaman FOR EACH ROW EXECUTE FUNCTION public.fn_log_status();


--
-- TOC entry 5217 (class 2620 OID 17383)
-- Name: peminjaman trg_validasi_peminjaman; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validasi_peminjaman BEFORE INSERT OR UPDATE ON public.peminjaman FOR EACH ROW EXECUTE FUNCTION public.fn_validasi_peminjaman();


--
-- TOC entry 5215 (class 2606 OID 17377)
-- Name: log_status log_status_peminjaman_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_status
    ADD CONSTRAINT log_status_peminjaman_id_fkey FOREIGN KEY (peminjaman_id) REFERENCES public.peminjaman(id) ON DELETE CASCADE;


--
-- TOC entry 5213 (class 2606 OID 17357)
-- Name: peminjaman peminjaman_ruangan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peminjaman
    ADD CONSTRAINT peminjaman_ruangan_id_fkey FOREIGN KEY (ruangan_id) REFERENCES public.ruangan(id) ON DELETE RESTRICT;


--
-- TOC entry 5214 (class 2606 OID 17352)
-- Name: peminjaman peminjaman_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.peminjaman
    ADD CONSTRAINT peminjaman_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5212 (class 2606 OID 17318)
-- Name: ruangan ruangan_gedung_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ruangan
    ADD CONSTRAINT ruangan_gedung_id_fkey FOREIGN KEY (gedung_id) REFERENCES public.gedung(id) ON DELETE RESTRICT;


-- Completed on 2026-11-10 10:32:56

--
-- PostgreSQL database dump complete
--

\unrestrict 3VN9X6nUKctXNRkllMaV2JWId4U9sI3oGkPobc1U0jEL9g8lpdnJagwWP64rBcm

