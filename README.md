# ⚡ CyberNet (Ronin Messenger)

> **Pure Cyberpunk / Tactical HUD Realtime Messenger**  
> Высокоскоростной киберпанк-мессенджер для нетраннеров, хакеров и сетевых операторов Нео-Токио 2099.

---

## 🏗 Архитектура проекта (Monorepo)

- **`/backend`** — Высокопроизводительное ядро на **Python 3.11+ / FastAPI**:
  - Асинхронная архитектура (`asyncio`, `uvicorn`).
  - База данных: **PostgreSQL 16** / **SQLite** (`SQLAlchemy 2.0`, `asyncpg`).
  - Реалтайм-брокер и кэш: **Redis** (Pub/Sub рассылка по WebSockets, OTP-коды, 24ч кулдаун репутации).
  - 3 метода киберпанк-авторизации:
    1. `Cyber-ID`: вход по позывному / Cyber-Tag + пароль, восстановление по 12-словной сид-фразе.
    2. `Telegram Neuromodem`: генерация 6-значного одноразового OTP-кода через бота на Aiogram 3.
    3. `Email OTP`: авторизация по одноразовым почтовым кодам.
  - Поддержка Синдикатов (Групп), Нейро-каналов и глобального хаба «НЕО-ТОКИО СЕКТОР 01».
  - Система Репутации самураев (Honor Points / REP).

- **`/mobile`** — Клиентское приложение на **Flutter (Dart 3+)**:
  - Архитектура: **Feature-First + Clean Architecture** (`data`, `domain`, `presentation`).
  - Стейт-менеджмент: **BLoC / Cubit** (`flutter_bloc`).
  - Внедрение зависимостей: **GetIt** (`get_it`).
  - Сеть: **Dio** (с перехватом JWT) + **WebSocket** с авто-реконнектом.
  - Локальный кэш: **Hive**.
  - **Дизайн Tactical HUD / Pure Cyberpunk**:
    - Скошенные под 45° углы (`BeveledRectangleBorder`, `clipBehavior: Clip.antiAlias`).
    - Цветовая палитра: Obsidian Void (`#07090E`), Surface (`#0F141F`), Ronin Crimson (`#FF2A54`), Cyber Cyan (`#00F0FF`), Katana Gold (`#FCEE0A`).
    - Telegram-стиль категорий: `[ ВСЕ ]`, `[ ЛИЧНЫЕ ]`, `[ ГРУППЫ ]`, `[ КАНАЛЫ ]`.
    - Редактирование профиля самурая и сетевого Cyber-Tag.

---

## 🚀 Запуск проекта

### 1. Бэкенд
```bash
cd backend
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Мобильное приложение (Flutter)
```bash
cd mobile
flutter pub get
# При отладке на физическом Android через USB:
adb reverse tcp:8000 tcp:8000
flutter run
```

---

## 📜 Документация и журнал разработки
- [`BUGS_LOG.md`](./BUGS_LOG.md) — Журнал выявленных багов, архитектурных решений и правил предотвращения.
- [`GEMINI.md`](./GEMINI.md) — Спецификация дизайн-системы и правила архитектуры CyberNet.
