# ReelBoost AI

Flutter client + Express.js API for Instagram creator tools: hashtags, captions, ideas, viral scoring, and mock trends.

## Backend (Express)

```powershell
cd backend
Copy-Item .env.example .env
# Edit .env: MONGO_URI, JWT_SECRET, OPENAI_API_KEY
npm install
npm start
```

- Health: `GET http://localhost:3000/health`
- API base: `http://localhost:3000/api` (routes under `/api/auth`, `/api/hashtag`, …)

Protected with JWT (Bearer): `POST /api/hashtag/generate`, `GET /api/trends`. Other AI routes are open unless you add middleware later.

## Flutter app

```powershell
cd c:\Users\admin2\Desktop\instaviral
flutter pub get
```

Point the app at your API (includes `/api`). On a **real Android phone** on the same Wi‑Fi, the default compile-time base is `http://192.168.1.7:3000/api` (see `lib/services/api_service.dart`). Override if your PC uses another IP:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.7:3000/api
```

Web and desktop `flutter run` still use `http://localhost:3000/api` for the API base.

## Project layout

- `backend/` — Express API, Mongoose, OpenAI (`gpt-4o-mini`), JWT auth
- `lib/core/` — theme, `api_constants.dart`, Riverpod `app_providers.dart`, utils
- `lib/features/*` — auth, home, hashtag, caption, ideas, trends, viral score screens
- `lib/services/` — `api_client.dart`, `auth_repository.dart`, `reelboost_api_service.dart`
- `lib/services/notifications/notification_service.dart` — FCM placeholder
- `lib/services/payments/payment_service_stub.dart` — payments placeholder
