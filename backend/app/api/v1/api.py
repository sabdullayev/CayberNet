from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.rooms import router as rooms_router
from app.api.v1.chat_ws import router as chat_ws_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(users_router)
api_router.include_router(rooms_router)
api_router.include_router(chat_ws_router)
