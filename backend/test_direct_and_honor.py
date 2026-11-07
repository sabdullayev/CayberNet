import asyncio
import json
import uuid
import httpx
import websockets

BASE_URL = "http://localhost:8000"
WS_BASE = "ws://localhost:8000/api/v1/ws"


async def main():
    print("⚔️ [TEST] Starting Direct Rooms & Honor Points Test Suite...")

    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10.0) as client:
        # 1. Register 3 Samurais
        unique_id = uuid.uuid4().hex[:6]
        user_a_name = f"Ronin_A_{unique_id}"
        user_b_name = f"Ronin_B_{unique_id}"
        user_c_name = f"Ronin_C_{unique_id}"

        # Register User A
        r_a = await client.post("/api/v1/auth/cyber-id/register", json={
            "username": user_a_name,
            "password": "password_aaa"
        })
        assert r_a.status_code == 201, f"Failed register A: {r_a.text}"
        data_a = r_a.json()
        token_a = data_a["tokens"]["access_token"]
        user_a = data_a["user"]
        headers_a = {"Authorization": f"Bearer {token_a}"}

        # Register User B
        r_b = await client.post("/api/v1/auth/cyber-id/register", json={
            "username": user_b_name,
            "password": "password_bbb"
        })
        assert r_b.status_code == 201, f"Failed register B: {r_b.text}"
        data_b = r_b.json()
        token_b = data_b["tokens"]["access_token"]
        user_b = data_b["user"]
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # Register User C
        r_c = await client.post("/api/v1/auth/cyber-id/register", json={
            "username": user_c_name,
            "password": "password_ccc"
        })
        assert r_c.status_code == 201, f"Failed register C: {r_c.text}"
        data_c = r_c.json()
        token_c = data_c["tokens"]["access_token"]
        user_c = data_c["user"]
        headers_c = {"Authorization": f"Bearer {token_c}"}

        print("  ✓ Registered 3 samurai: A, B, C")

        # 2. Test User Search
        # Search by username
        r_search = await client.get(f"/api/v1/users/search?query={user_b_name}", headers=headers_a)
        assert r_search.status_code == 200, f"Search failed: {r_search.text}"
        search_results = r_search.json()
        assert len(search_results) >= 1
        assert any(u["username"] == user_b_name for u in search_results)
        print(f"  ✓ Search by username found: {user_b_name}")

        # Search by Cyber-Tag
        tag_b = user_b["cyber_tag"]
        r_search_tag = await client.get(f"/api/v1/users/search?query={tag_b}", headers=headers_a)
        assert r_search_tag.status_code == 200
        assert any(u["cyber_tag"] == tag_b for u in r_search_tag.json())
        print(f"  ✓ Search by Cyber-Tag found: {tag_b}")

        # 3. Test Direct Room Creation
        # Self-direct should fail
        r_self_direct = await client.post(f"/api/v1/rooms/direct/{user_a['id']}", headers=headers_a)
        assert r_self_direct.status_code == 400, "Self direct should return 400"
        print("  ✓ Self-direct creation blocked with 400 Bad Request")

        # Create Direct between A and B
        r_direct = await client.post(f"/api/v1/rooms/direct/{user_b['id']}", headers=headers_a)
        assert r_direct.status_code == 200, f"Create direct failed: {r_direct.text}"
        direct_room = r_direct.json()
        assert direct_room["type"] == "direct"
        assert direct_room["interlocutor"]["id"] == user_b["id"]
        assert direct_room["interlocutor"]["username"] == user_b["username"]
        assert direct_room["interlocutor"]["rank"] == "Скиталец Сетки"
        room_id = direct_room["id"]
        print(f"  ✓ Created Direct Room: {room_id} with interlocutor {user_b['username']}")

        # Re-requesting direct should return the same room
        r_direct2 = await client.post(f"/api/v1/rooms/direct/{user_a['id']}", headers=headers_b)
        assert r_direct2.status_code == 200
        direct_room2 = r_direct2.json()
        assert direct_room2["id"] == room_id
        assert direct_room2["interlocutor"]["id"] == user_a["id"]
        print("  ✓ Re-requesting from user B returned identical room ID")

        # 4. Test WebSocket message in Direct Room
        ws_url = f"{WS_BASE}/{room_id}?token={token_a}"
        async with websockets.connect(ws_url) as ws_a:
            # Send message in direct room
            await ws_a.send(json.dumps({
                "type": "new_message",
                "content": "Secret transmission between ronins."
            }))
            await asyncio.sleep(0.5)

        print("  ✓ Message sent into Direct Room")

        # 5. Test GET /api/v1/rooms/my
        r_my = await client.get("/api/v1/rooms/my", headers=headers_a)
        assert r_my.status_code == 200
        my_rooms = r_my.json()
        assert len(my_rooms) >= 2
        # First must be global
        assert my_rooms[0]["type"] == "global"
        # Direct room present
        my_direct = next((r for r in my_rooms if r["id"] == room_id), None)
        assert my_direct is not None
        assert my_direct["last_message"] is not None
        assert my_direct["last_message"]["content"] == "Secret transmission between ronins."
        assert my_direct["interlocutor"]["username"] == user_b["username"]
        print(f"  ✓ GET /api/v1/rooms/my returned {len(my_rooms)} rooms with last_message preview")

        # 6. Test Honor System (REST)
        # Self-honor should fail
        r_self_honor = await client.post(f"/api/v1/users/{user_a['id']}/honor", headers=headers_a)
        assert r_self_honor.status_code == 400
        print("  ✓ Self-honor award blocked with 400 Bad Request")

        # A awards honor to B
        r_honor = await client.post(f"/api/v1/users/{user_b['id']}/honor", headers=headers_a)
        assert r_honor.status_code == 200, f"Honor failed: {r_honor.text}"
        honor_data = r_honor.json()
        assert honor_data["honor_points"] == 1
        assert honor_data["rank"] == "Скиталец Сетки"
        print(f"  ✓ Honor awarded to {user_b_name}: {honor_data['honor_points']} points")

        # Attempting second vote within 24h should fail (429)
        r_honor_repeat = await client.post(f"/api/v1/users/{user_b['id']}/honor", headers=headers_a)
        assert r_honor_repeat.status_code == 429, "Second honor vote should be 429"
        print("  ✓ 24-hour rate limit correctly triggered 429 Too Many Requests")

        # 7. Test Realtime WebSocket give_honor event
        # Connect B and C to direct room
        async with websockets.connect(f"{WS_BASE}/{room_id}?token={token_b}") as ws_b:
            async with websockets.connect(f"{WS_BASE}/{room_id}?token={token_c}") as ws_c:
                # C gives honor to A via WS
                await ws_c.send(json.dumps({
                    "type": "give_honor",
                    "target_user_id": user_a["id"]
                }))

                # B should receive "honor_updated" broadcast
                received_honor_event = False
                for _ in range(5):
                    raw = await asyncio.wait_for(ws_b.recv(), timeout=3.0)
                    evt = json.loads(raw)
                    if evt.get("type") == "honor_updated":
                        assert evt["target_user_id"] == user_a["id"]
                        assert evt["honor_points"] == 1
                        assert evt["from_username"] == user_c["username"]
                        received_honor_event = True
                        break

                assert received_honor_event, "WebSocket honor_updated event was not received"
                print("  ✓ Realtime WebSocket 'honor_updated' broadcast received successfully!")

    print("\n🎉 [ALL TESTS PASSED] Direct Rooms, Search & Honor System verified!")


if __name__ == "__main__":
    asyncio.run(main())
