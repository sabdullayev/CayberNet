import asyncio
import httpx

BASE_URL = "http://127.0.0.1:8000/api/v1"

async def test_profile_update():
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10.0) as client:
        # 1. Register test user A
        u_a = "tester_a_99"
        p_a = "pass12345"
        res_a = await client.post("/auth/cyber-id/register", json={"username": u_a, "password": p_a})
        if res_a.status_code not in (200, 201):
            # Try login
            res_a = await client.post("/auth/cyber-id/login", json={"identifier": u_a, "password": p_a})
        token_a = res_a.json()["tokens"]["access_token"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        # 2. Register test user B
        u_b = "tester_b_99"
        p_b = "pass12345"
        res_b = await client.post("/auth/cyber-id/register", json={"username": u_b, "password": p_b})
        if res_b.status_code not in (200, 201):
            res_b = await client.post("/auth/cyber-id/login", json={"identifier": u_b, "password": p_b})
        user_b = res_b.json()["user"]
        tag_b = user_b["cyber_tag"]

        # 3. Try to update user A username to user B's username (should fail 400)
        res_dup_u = await client.patch("/users/me", headers=headers_a, json={"username": u_b})
        assert res_dup_u.status_code == 400, f"Expected 400 for duplicate username, got {res_dup_u.status_code}"
        print("PASS: Duplicate username check")

        # 4. Try to update user A tag to user B's tag (should fail 400)
        res_dup_tag = await client.patch("/users/me", headers=headers_a, json={"cyber_tag": tag_b})
        assert res_dup_tag.status_code == 400, f"Expected 400 for duplicate tag, got {res_dup_tag.status_code}"
        print("PASS: Duplicate tag check")

        # 5. Update user A with unique username and unique tag
        new_u = "cyber_samurai_x"
        new_tag = "SAMURAI#007"
        res_ok = await client.patch("/users/me", headers=headers_a, json={"username": new_u, "cyber_tag": new_tag})
        assert res_ok.status_code == 200, f"Expected 200, got {res_ok.status_code}: {res_ok.text}"
        data = res_ok.json()
        assert data["username"] == new_u
        assert data["cyber_tag"] == new_tag
        print(f"PASS: Successfully updated profile: {data['username']} ({data['cyber_tag']})")

if __name__ == "__main__":
    asyncio.run(test_profile_update())
