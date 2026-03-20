# พีรพงศ์ ปัญญาสัน 67543210042-7
# Weather App (Lab 9)

แอปพลิเคชันรายงานสภาพอากาศที่พัฒนาด้วย Flutter โดยดึงข้อมูลผ่าน Open-Meteo API

## ฟีเจอร์หลัก

- ค้นหาเมืองทั่วโลกแบบ Real-time ผ่าน Open-Meteo Geocoding API
- แสดงอุณหภูมิและความเร็วลมปัจจุบัน
- แสดง Animation หมุนไอคอนสภาพอากาศ
- UI แบบ Gradient ไล่สีโทนส้ม-ขาว
- โหลดเมือง Chiang Mai เป็นค่าเริ่มต้น

## API ที่ใช้

| API | วัตถุประสงค์ |
|-----|------------|
| [Open-Meteo Geocoding](https://geocoding-api.open-meteo.com) | ค้นหาพิกัดเมือง |
| [Open-Meteo Forecast](https://api.open-meteo.com) | ดึงข้อมูลสภาพอากาศ |

## การติดตั้งและรัน

```bash
flutter pub get
flutter run
```

## โครงสร้างโปรเจกต์

```
lib/
└── main.dart      # โค้ดหลักทั้งหมด (Model, API Service, UI)
```

---

**พัฒนาโดย:**  พีรพงศ์ ปัญญาสัน | **รหัส:** 67543210042-7
