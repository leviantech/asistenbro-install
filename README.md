# Asistenbro Installer

Repository publik untuk script instalasi dan standalone release binary Asistenbro Runner/Host serta Desktop App.

## Download Desktop App (GUI)

Unduh aplikasi desktop native untuk sistem operasi Anda:

- **Windows**: [Asistenbro Setup (.exe)](https://github.com/leviantech/asistenbro-install/releases/latest)
- **macOS (Apple Silicon)**: [Asistenbro (.zip)](https://github.com/leviantech/asistenbro-install/releases/latest)
- **Linux**: [Asistenbro (.AppImage / .deb)](https://github.com/leviantech/asistenbro-install/releases/latest)

---

## Instalasi CLI / Host (One-Liner)

### Linux & macOS
Buka terminal dan jalankan:
```bash
curl -fsSL https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.sh | bash
```

### Windows (PowerShell)
Buka PowerShell dan jalankan:
```powershell
# Install CLI
irm https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.ps1 | iex

# Atau download & jalankan Desktop Installer
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.ps1))) -Desktop
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
