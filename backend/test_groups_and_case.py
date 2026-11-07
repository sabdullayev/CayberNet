import asyncio
import uuid
import httpx

BASE_URL = "http://127.0.0.1:8000/api/v1"

async def main():
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=15.0) as client:
        print("⚔️ [TEST] Starting Group & Channel + Case Sensitivity Test...")
        
        # 1. Register with mixed case
        rand_suffix = uuid.uuid4().hex[:6]
        username = f"NetRunner_{rand_suffix}"
        password = "CyberPassword2099"
        
        reg_res = await client.post("/auth/cyber-id/register", json={
            "username": username,
            "password": f"  {password}  "  # test whitespace trim
        })
        assert reg_res.status_code in (200, 201), f"Register failed: {reg_res.text}"
        data = reg_res.json()
        token = data["tokens"]["access_token"]
        cyber_tag = data["user"]["cyber_tag"]
        print(f"  ✓ User registered: {username} ({cyber_tag})")
        
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Login with all lowercase username
        login_res_lower = await client.post("/auth/cyber-id/login", json={
            "identifier": username.lower(),
            "password": password
        })
        assert login_res_lower.status_code == 200, f"Lower username login failed: {login_res_lower.text}"
        print(f"  ✓ Case-insensitive lowercase username login verified!")

        # 3. Login with all lowercase Cyber-Tag
        login_res_tag = await client.post("/auth/cyber-id/login", json={
            "identifier": cyber_tag.lower(),
            "password": password
        })
        assert login_res_tag.status_code == 200, f"Lower tag login failed: {login_res_tag.text}"
        print(f"  ✓ Case-insensitive lowercase Cyber-Tag login verified!")

        # 4. Create Group
        group_res = await client.post("/rooms/group", json={
            "name": f"Syndicate {rand_suffix}",
            "description": "Tactical combat netrunners"
        }, headers=headers)
        assert group_res.status_code == 200, f"Group creation failed: {group_res.text}"
        group_data = group_res.json()
        assert group_data["type"] == "group"
        print(f"  ✓ Group room created: {group_data['name']} (ID: {group_data['id']})")

        # 5. Create Channel
        channel_res = await client.post("/rooms/channel", json={
            "name": f"Broadcast {rand_suffix}",
            "description": "Official net news"
        }, headers=headers)
        assert channel_res.status_code == 200, f"Channel creation failed: {channel_res.text}"
        channel_data = channel_res.json()
        assert channel_data["type"] == "channel"
        print(f"  ✓ Channel room created: {channel_data['name']} (ID: {channel_data['id']})")

        # 6. Verify GET /rooms/my returns Global, Group, Channel
        my_res = await client.get("/rooms/my", headers=headers)
        assert my_res.status_code == 200
        rooms = my_res.json()
        room_types = [r["type"] for r in rooms]
        assert "global" in room_types, "Global hub missing"
        assert "group" in room_types, "Group missing"
        assert "channel" in room_types, "Channel missing"
        print(f"  ✓ /rooms/my contains all room types: {set(room_types)}")

        print("\n🎉 [ALL TESTS PASSED] Group & Channel & Case Sensitivity Verified!")

if __name__ == "__main__":
    asyncio.run(main())
