# Asistenbro Installer

Repository publik untuk script instalasi dan standalone release binary Asistenbro Runner/Host.

## Instalasi Cepat (One-Liner)

### Linux & macOS
Buka terminal dan jalankan:
```bash
curl -fsSL https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.sh | bash
```

### Windows (PowerShell)
Buka PowerShell dan jalankan:
```powershell
irm https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.ps1 | iex
```

---

## Menghubungkan ke Server

Setelah instalasi selesai, hubungkan komputer Anda ke server Asistenbro:

```bash
# Mode interaktif di foreground
asistenbro host https://agent.asistenbro.my.id

# Atau aktifkan sebagai background service otomatis (Linux/systemd)
asistenbro host enable --server https://agent.asistenbro.my.id
```
