# ⚡ POWER GUARD

Project sistem tertanam berbasis Flutter dan BLE.

> 🚧 **Status: dalam pengembangan.**
> Saat ini aplikasi masih berupa **versi dummy**: data tegangan, arus, dan daya masih simulasi. Integrasi dengan perangkat ESP akan ditambahkan setelah bagian hardware selesai.

## 📌 Deskripsi

Power Guard adalah project sistem tertanam yang menggabungkan aplikasi mobile dengan perangkat keras untuk memantau kelistrikan. Pada tahap ini, aplikasi sudah memiliki tampilan monitoring dan fitur scan Bluetooth, tetapi belum terhubung ke sensor sungguhan.

## ✨ Fitur Saat Ini

- Tampilan monitoring **tegangan (Volt)**, **arus (Ampere)**, dan **daya (Watt)**
- **Grafik** perubahan nilai kelistrikan
- Tombol **scan Bluetooth (BLE)** untuk mencari perangkat sekitar
- Menampilkan nama perangkat dan kekuatan sinyal (RSSI)
- Estimasi jarak dari nilai RSSI

> Catatan: nilai volt, ampere, watt, dan grafik masih berupa data dummy.

## 🗓️ Rencana Pengembangan

- [ ] Integrasi dengan perangkat ESP
- [ ] Mengganti data dummy dengan data sensor asli
- [ ] Komunikasi data aplikasi dengan ESP via Bluetooth
- [ ] Dokumentasi perangkat keras dan skema rangkaian
- [ ] Panduan instalasi dan penggunaan

## 🛠️ Teknologi

- Flutter (Dart)
- flutter_blue_plus
