"use strict";

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

/* ---------- util ---------- */
function esc(v) {
  return String(v ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
const pad = (n) => String(n).padStart(2, "0");
const BULAN = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];
function fmtDT(s) {
  if (!s) return "-";
  const d = new Date(s); // string tanpa zona = waktu lokal
  return `${d.getDate()} ${BULAN[d.getMonth()]} ${d.getFullYear()}, ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
function fmtTime(s) {
  const d = new Date(s);
  return `${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
const toInput = (s) => (s ? s.slice(0, 16) : ""); // untuk <input type="datetime-local">
const badge = (text, cls) => `<span class="badge ${esc(cls ?? text)}">${esc(text)}</span>`;

/* ---------- API ---------- */
function parseDetail(d) {
  if (!d) return "";
  if (typeof d.detail === "string") return d.detail;
  if (Array.isArray(d.detail)) {
    return d.detail.map((e) => `${(e.loc || []).slice(1).join(".")}: ${(e.msg || "").replace("Value error, ", "")}`).join("; ");
  }
  return "";
}

async function api(path, { method = "GET", body, params } = {}) {
  let url = path;
  if (params) {
    const q = new URLSearchParams();
    for (const [k, v] of Object.entries(params)) if (v !== "" && v != null) q.append(k, v);
    const qs = q.toString();
    if (qs) url += "?" + qs;
  }
  let res;
  try {
    res = await fetch(url, {
      method,
      headers: body ? { "Content-Type": "application/json" } : {},
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (e) {
    throw new Error("Gagal terhubung ke server");
  }
  let data = null;
  try { data = await res.json(); } catch (e) { /* respons kosong */ }
  if (!res.ok) throw new Error(parseDetail(data) || `Terjadi kesalahan (${res.status})`);
  return data;
}

/* ---------- UI helper ---------- */
function toast(msg, type = "ok") {
  const el = document.createElement("div");
  el.className = "toast " + (type === "err" ? "err" : "");
  el.textContent = msg;
  $("#toasts").appendChild(el);
  setTimeout(() => el.remove(), 4500);
}

function renderTable(el, cols, rows, emptyMsg = "Belum ada data.") {
  if (!rows.length) { el.innerHTML = `<p class="empty">${esc(emptyMsg)}</p>`; return; }
  const head = cols.map((c) => `<th>${esc(c.h)}</th>`).join("");
  const body = rows.map((r) => "<tr>" + cols.map((c) => `<td class="${c.cls || ""}">${c.f(r)}</td>`).join("") + "</tr>").join("");
  el.innerHTML = `<table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>`;
}

function fillSelect(sel, items, valueFn, labelFn, placeholder, disabledFn) {
  const first = placeholder !== undefined ? `<option value="">${esc(placeholder)}</option>` : "";
  sel.innerHTML = first + items.map((i) =>
    `<option value="${esc(valueFn(i))}"${disabledFn && disabledFn(i) ? " disabled" : ""}>${esc(labelFn(i))}</option>`).join("");
}

const openDlg = (id) => $("#" + id).showModal();

document.addEventListener("click", (e) => {
  if (e.target.matches("[data-close]")) e.target.closest("dialog").close();
  else if (e.target.tagName === "DIALOG") e.target.close(); // klik area gelap di luar kotak
});

/* membungkus aksi async: tampilkan error sebagai toast */
async function guard(fn) {
  try { return await fn(); } catch (e) { toast(e.message, "err"); }
}
