# Project Context: CyberNet (Pure Cyberpunk Messenger)

## 1. Обзор проекта
Кастомный реалтайм-мессенджер в стиле чистого киберпанка (CyberNet: хакеры, нетраннеры, сетевые операторы).
Структура репозитория — Monorepo:
- `/backend` — серверная часть на Python (FastAPI, PostgreSQL, Redis, WebSockets, Aiogram 3).
- `/mobile` — клиентское приложение на Flutter (Android/iOS).

## 2. Правила для ИИ-агента (Gemini CLI)
- Пиши чистый, модульный, полностью рабочий код без заглушек (`TODO` или `pass` запрещены, если не оговорено).
- Строго соблюдай разделение слоев как на бэкенде, так и на Flutter.
- Всегда проверяй импорты и зависимости перед завершением задачи.
- Отвечай кратко и по делу на русском языке, комментарии в коде — на английском или русском.
- **Журнал багов и фиксов:** Все выявленные баги, первопричины и правила предотвращения ОБЯЗАТЕЛЬНО фиксируются в `BUGS_LOG.md`.
- **Автотесты обязательны:** После любого исправления запускать бэкенд-тесты (`pytest` / `test_*.py`) и `flutter analyze`.

## 3. Архитектура и стек Бэкенда (`/backend`)
- **Framework:** FastAPI (Python 3.11+), асинхронный подход везде.
- **Database:** PostgreSQL 16 + SQLAlchemy 2.0 (`AsyncSession`, `asyncpg`) + Alembic для миграций (в dev-режиме fallback на SQLite).
- **Cache & Realtime Broker:** Redis (`redis.asyncio`) для хранения OTP-кодов (TTL 3-5 мин), онлайн-статусов, репутационных кулдаунов и Pub/Sub рассылки сообщений по WebSockets.
- **Auth (JWT + 3 метода входа):**
  1. `Cyber-ID`: вход по `cyber_tag` (или `username`) + пароль / восстановление по 12-словной киберпанк сид-фразе.
  2. `Telegram Neuromodem`: вход по 6-значному одноразовому коду, который генерирует встроенный бот на `aiogram 3` по команде `/start` и сохраняет в Redis.
  3. `Email OTP`: отправка 6-значного кода на почту (в режиме разработки `DEV_MODE=True` код также выводится в консоль сервера для удобного теста) с хранением в Redis.
- **Структура `/backend/app`:**
  - `core/` — `config.py` (Pydantic Settings), `database.py`, `redis.py`, `security.py` (JWT, bcrypt).
  - `models/` — таблицы SQLAlchemy (`User`, `Room`, `RoomMember`, `Message`).
  - `schemas/` — Pydantic v2 модели запросов и ответов.
  - `services/` — бизнес-логика (`auth_service.py`, `chat_service.py`).
  - `api/v1/` — роутеры (`auth.py`, `users.py`, `rooms.py`, `chat_ws.py`).
  - `ws/` — `manager.py` (WebSocket ConnectionManager + Redis Pub/Sub).
  - `bot/` — `tg_bot.py` (Aiogram 3 роутер, запускаемый параллельно с FastAPI в `lifespan`).

## 4. Архитектура и стек Мобилки (`/mobile`)
- **Framework:** Flutter (Dart 3+), Feature-First + Clean Architecture (`data`, `domain`, `presentation`).
- **State Management:** `flutter_bloc` (BLoC / Cubit).
- **DI:** `get_it`.
- **Network:** `dio` (с интерцептором для JWT) + `web_socket_channel` (с пингом и авто-реконнектом).
- **Local Storage:** `hive_flutter` (кэш последних сообщений, JWT токены, настройки профиля).
- **UI & Theme (Pure Cyberpunk Style):**
  - Background: `#0A0A0E` (Obsidian), Surface/Cards: `#14141C`.
  - Primary Accent: `#FF003C` (Neon Crimson), Secondary Accent: `#00F0FF` (Cyber Cyan) / `#FCEE0A` (Matrix Gold).
  - Формы: никаких стандартных круглых кнопок. Использовать `BeveledRectangleBorder` (скошенные под 45 градусов углы) и тонкие неоновые рамки (`BorderSide(color: Color(0xFFFF003C), width: 1)`).
  - **Геометрия срезов:** Контейнеры со срезанными углами ОБЯЗАТЕЛЬНО оборачивать с `clipBehavior: Clip.antiAlias` во избежание вылезания индикаторов за пределы 45-градусных срезов. Индикаторы центрировать через `indicatorSize: TabBarIndicatorSize.label` или фиксированные плашки.
  - **Плавные переходы:** Переключение экранов и вкладок оформлять через `AnimatedSwitcher` (fade + slide) вместо грубых `TabBarView`, чтобы карточки не склеивались при свайпах.
  - **Ссылки:** Никаких дефолтных белых подчеркиваний (`TextDecoration.none`).
  - Шрифты: заголовки — `Orbitron` / `JetBrains Mono`, текст сообщений — `Inter` / `Roboto`.

## 5. Схема Базы Данных (MVP)
- `users`: `id` (UUID, PK), `cyber_tag` (String, unique, например `CYBER#1024`), `username` (String, unique), `password_hash` (String, nullable), `seed_phrase_hash` (String, nullable), `email` (String, unique, nullable), `telegram_id` (BigInt, unique, nullable), `avatar_url` (String, nullable), `honor_points` (Int, default 0, система Репутации), `created_at` (DateTime).
- `rooms`: `id` (UUID, PK), `type` (Enum: `global`, `direct`), `name` (String), `created_at` (DateTime). При старте сервера автоматически создается комната `Global Hub` ("НЕО-ТОКИО СЕКТОР 01"), если её нет.
- `room_members`: `id` (UUID, PK), `room_id` (FK), `user_id` (FK), `joined_at` (DateTime).
- `messages`: `id` (UUID, PK), `room_id` (FK, index), `sender_id` (FK), `content` (Text), `reply_to_id` (UUID, nullable), `is_deleted` (Bool, default False), `created_at` (DateTime, index).
