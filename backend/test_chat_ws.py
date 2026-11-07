import asyncio
import json
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import init_db
from app.core.redis import init_redis


def run_ws_tests():
    print("\n⚔️  STARTING WEBSOCKET & CHAT REST TESTS ⚔️\n")

    # Initialize DB & Redis
    asyncio.run(init_db())
    asyncio.run(init_redis())

    with TestClient(app) as client:
        # 1. Register a test user to obtain token
        username = "blade_runner_42"
        reg_res = client.post("/api/v1/auth/cyber-id/register", json={
            "username": username,
            "password": "secret_password_999"
        })
        if reg_res.status_code == 400:
            # Already registered in previous test, log in
            login_res = client.post("/api/v1/auth/cyber-id/login", json={
                "identifier": username,
                "password": "secret_password_999"
            })
            assert login_res.status_code == 200, f"Login failed: {login_res.text}"
            token = login_res.json()["tokens"]["access_token"]
            user = login_res.json()["user"]
        else:
            assert reg_res.status_code == 201, f"Register failed: {reg_res.text}"
            token = reg_res.json()["tokens"]["access_token"]
            user = reg_res.json()["user"]

        print(f"✅ 1. Authenticated user: {user['cyber_tag']} ({user['username']})")

        headers = {"Authorization": f"Bearer {token}"}

        # 2. Test GET /api/v1/rooms/global
        global_res = client.get("/api/v1/rooms/global", headers=headers)
        assert global_res.status_code == 200, f"Global room failed: {global_res.text}"
        room_data = global_res.json()
        room_id = room_data["id"]
        assert room_data["name"] == "Таверна Нео-Токио"
        print(f"✅ 2. GET /rooms/global: ID={room_id}, Name='{room_data['name']}', Online={room_data['online_count']}")

        # 3. Test WebSocket connection: WS /api/v1/ws/{room_id}?token={token}
        ws_url = f"/api/v1/ws/{room_id}?token={token}"
        with client.websocket_connect(ws_url) as websocket:
            # 3a. Expect initial online_count event
            init_event = json.loads(websocket.receive_text())
            assert init_event["type"] == "online_count"
            assert init_event["count"] >= 1
            print(f"✅ 3a. WS Connected: Received online_count={init_event['count']}")

            # 3b. Test Ping -> Pong
            websocket.send_text(json.dumps({"type": "ping"}))
            pong_event = json.loads(websocket.receive_text())
            assert pong_event["type"] == "pong"
            print("✅ 3b. WS Ping -> Pong OK")

            # 3c. Send new_message
            msg_text = "Катана наготове. Кто за столиком в углу?"
            websocket.send_text(json.dumps({
                "type": "new_message",
                "content": msg_text
            }))
            msg_event = json.loads(websocket.receive_text())
            assert msg_event["type"] == "new_message"
            message_obj = msg_event["message"]
            first_msg_id = message_obj["id"]
            assert message_obj["content"] == msg_text
            assert message_obj["sender"]["username"] == username
            assert message_obj["is_deleted"] is False
            print(f"✅ 3c. WS new_message broadcast received: ID={first_msg_id}, Content='{message_obj['content']}'")

            # 3d. Send message with reply_to
            reply_text = "Я слежу за матрицей. Всё чисто."
            websocket.send_text(json.dumps({
                "type": "new_message",
                "content": reply_text,
                "reply_to_id": first_msg_id
            }))
            reply_event = json.loads(websocket.receive_text())
            assert reply_event["type"] == "new_message"
            reply_obj = reply_event["message"]
            second_msg_id = reply_obj["id"]
            assert reply_obj["reply_to"] is not None
            assert reply_obj["reply_to"]["id"] == first_msg_id
            assert reply_obj["reply_to"]["content"] == msg_text
            print(f"✅ 3d. WS new_message with reply_to received: Quoting ID={first_msg_id}")

            # 3e. Test typing event
            websocket.send_text(json.dumps({
                "type": "typing",
                "is_typing": True
            }))
            print("✅ 3e. WS typing event transmitted without error")

            # 3f. Test delete_message (Katana Slash)
            websocket.send_text(json.dumps({
                "type": "delete_message",
                "message_id": first_msg_id
            }))
            del_event = json.loads(websocket.receive_text())
            assert del_event["type"] == "message_deleted"
            assert del_event["message_id"] == first_msg_id
            print(f"✅ 3f. WS Katana Slash: message_deleted broadcast for ID={first_msg_id}")

        # 4. Verify REST history GET /api/v1/rooms/{room_id}/messages
        hist_res = client.get(f"/api/v1/rooms/{room_id}/messages?limit=20", headers=headers)
        assert hist_res.status_code == 200, f"History fetch failed: {hist_res.text}"
        history = hist_res.json()
        assert len(history) >= 2

        # Check deleted flag
        deleted_item = next(m for m in history if m["id"] == first_msg_id)
        assert deleted_item["is_deleted"] is True
        print(f"✅ 4. REST History verified: Total messages={len(history)}, Deleted message marked is_deleted=True")

    print("\n🎉 ALL WEBSOCKET & REST CHAT TESTS PASSED SUCCESSFULLY! 🎉\n")


if __name__ == "__main__":
    run_ws_tests()
