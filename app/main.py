from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import transactions 

app = FastAPI(
    title="Spendly API",
    description="Бэкенд для голосового трекера расходов",
    version="1.0.0"
)

# Разрешаем запросы с других устройств 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # На этапе разработки разрешаем всем
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Тестовый эндпоинт (просто чтобы проверить, что сервер жив)
@app.get("/")
def read_root():
    return {"status": "ok"}

app.include_router(transactions.router)

@app.post("/auth/login")
def fake_login():
    # Временная заглушка, чтобы приложение могло войти
    return {"access_token": "test-token", "token_type": "bearer"}