import asyncio
import json
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.database import init_db
from app.core.redis import init_redis, get_redis_instance


async def run_tests():
    print("\n⚔️  STARTING RONINNET AUTOMATED BACKEND TESTS ⚔️\n")

    # Manually invoke lifespan initialization
    await init_db()
    await init_redis()

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Health check
        res = await client.get("/health")
        assert res.status_code == 200, f"Health check failed: {res.text}"
        print("✅ 1. Health Check OK:", res.json())

        # 2. Cyber-ID Registration
        reg_payload = {
            "username": "kaze_runner",
            "password": "cyber_secret_password_123"
        }
        res = await client.post("/api/v1/auth/cyber-id/register", json=reg_payload)
        assert res.status_code == 201, f"Cyber-ID Register failed: {res.text}"
        data = res.json()
        user = data["user"]
        tokens = data["tokens"]
        seed_words = data["seed_phrase"]

        assert user["username"] == "kaze_runner"
        assert "#" in user["cyber_tag"]
        assert len(seed_words) == 12
        assert tokens["access_token"]
        print(f"✅ 2. Cyber-ID Registered: Tag={user['cyber_tag']}, 12 Words={seed_words[:3]}...{seed_words[-2:]}")

        access_token = tokens["access_token"]
        auth_headers = {"Authorization": f"Bearer {access_token}"}

        # 3. Check /api/v1/auth/me
        res = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert res.status_code == 200, f"Get me failed: {res.text}"
        assert res.json()["username"] == "kaze_runner"
        print("✅ 3. Authenticated /me endpoint OK")

        # 4. Check Rooms & Auto-Join to 'Таверна Нео-Токио'
        res = await client.get("/api/v1/rooms/", headers=auth_headers)
        assert res.status_code == 200, f"Get rooms failed: {res.text}"
        rooms = res.json()
        assert len(rooms) >= 1
        assert any(r["name"] == "Таверна Нео-Токио" for r in rooms)
        print("✅ 4. Auto-Joined 'Таверна Нео-Токио' (Global Hub) confirmed!")

        # 5. Cyber-ID Login via Cyber-Tag
        res = await client.post("/api/v1/auth/cyber-id/login", json={
            "identifier": user["cyber_tag"],
            "password": "cyber_secret_password_123"
        })
        assert res.status_code == 200, f"Login by tag failed: {res.text}"
        print("✅ 5. Login via Cyber-Tag OK")

        # 6. Cyber-ID Login via Username
        res = await client.post("/api/v1/auth/cyber-id/login", json={
            "identifier": "kaze_runner",
            "password": "cyber_secret_password_123"
        })
        assert res.status_code == 200, f"Login by username failed: {res.text}"
        print("✅ 6. Login via Username OK")

        # 7. Cyber-ID Restore via 12-Word Seed Phrase
        res = await client.post("/api/v1/auth/cyber-id/restore", json={
            "seed_phrase": " ".join(seed_words),
            "new_password": "new_katana_password_999"
        })
        assert res.status_code == 200, f"Seed restore failed: {res.text}"
        assert res.json()["user"]["username"] == "kaze_runner"
        print("✅ 7. Restore & Password Reset via 12 Cyberpunk Words OK")

        # Verify new password works
        res = await client.post("/api/v1/auth/cyber-id/login", json={
            "identifier": "kaze_runner",
            "password": "new_katana_password_999"
        })
        assert res.status_code == 200, "Login with new password failed"
        print("✅ 7b. Login with updated password OK")

        # 8. Email OTP Request
        res = await client.post("/api/v1/auth/email/send-code", json={"email": "samurai@ronin.net"})
        assert res.status_code == 200, f"Send Email OTP failed: {res.text}"
        otp_data = res.json()
        dev_code = otp_data["dev_code"]
        assert dev_code and len(dev_code) == 6
        print(f"✅ 8. Email OTP Generated and Dispatched: Code={dev_code}")

        # 9. Email OTP Verify (Registers samurai on first login)
        res = await client.post("/api/v1/auth/email/verify", json={
            "email": "samurai@ronin.net",
            "code": dev_code
        })
        assert res.status_code == 200, f"Verify Email OTP failed: {res.text}"
        email_user = res.json()["user"]
        assert email_user["email"] == "samurai@ronin.net"
        assert "#" in email_user["cyber_tag"]
        print(f"✅ 9. Email OTP Verified & User Created: {email_user['cyber_tag']} ({email_user['username']})")

        # 10. Telegram Neuromodem Simulation
        redis = await get_redis_instance()
        tg_code = "777888"
        tg_payload = {
            "telegram_id": 987654321,
            "username": "tg_shogun",
            "first_name": "Shogun"
        }
        await redis.set(f"tg_otp:{tg_code}", json.dumps(tg_payload), ex=300)

        res = await client.post("/api/v1/auth/telegram/verify", json={"code": tg_code})
        assert res.status_code == 200, f"Verify Telegram Code failed: {res.text}"
        tg_user = res.json()["user"]
        assert tg_user["telegram_id"] == 987654321
        assert tg_user["username"] == "tg_shogun"
        assert "#" in tg_user["cyber_tag"]
        print(f"✅ 10. Telegram Neuromodem Login OK: {tg_user['cyber_tag']} (Telegram ID: {tg_user['telegram_id']})")

        # Verify single-use of Telegram code (should fail on second try)
        res_repeat = await client.post("/api/v1/auth/telegram/verify", json={"code": tg_code})
        assert res_repeat.status_code == 400, "Telegram code was not invalidated after use!"
        print("✅ 10b. Telegram Code Single-Use Consumption confirmed!")

        # 11. Refresh Token Test
        rf_tokens = res.json()["tokens"]
        res_refresh = await client.post("/api/v1/auth/refresh", json={"refresh_token": rf_tokens["refresh_token"]})
        assert res_refresh.status_code == 200, f"Token refresh failed: {res_refresh.text}"
        new_tokens = res_refresh.json()
        assert new_tokens["access_token"]
        print("✅ 11. JWT Token Refresh OK")

    print("\n🎉 ALL 11 TESTS PASSED! BACKEND STAGE 1 & 2 FULLY OPERATIONAL! 🎉\n")


if __name__ == "__main__":
    asyncio.run(run_tests())
