import os
from dotenv import load_dotenv
from gigachat import GigaChat

# Загружаем ключи из файла .env
load_dotenv()

# Инициализация клиента
client = GigaChat(
    credentials=os.getenv("GIGACHAT_CREDENTIALS"),
    scope="GIGACHAT_API_PERS",
    verify_ssl_certs=False,
    model="GigaChat-2"
)

PROMPT = """Ты — финансовый ассистент приложения Spendly. 
Пользователь рассказывает о своих тратах. Твоя задача — извлечь из текста все траты.

Верни ТОЛЬКО JSON-массив. Никакого текста до или после. Формат:
[
  {{"amount": 1000, "category": "Развлечения", "note": "игровой клуб"}},
  {{"amount": 500, "category": "Еда", "note": "шаурма"}}
]

Категории строго из списка: Еда, Транспорт, Развлечения, Жилье, Здоровье, Прочее.
Учитывай сленг: штукарь=1000, пятихатка=500, косарь=1000, полтос=50, чирик=10.

Текст пользователя: {user_text}
"""

user_text = "Сегодня оставил штукарь в игровом клубе и пятихатку на шаурму"

print("Отправляем запрос в GigaChat...")
# Отправка запроса
response = client.chat(PROMPT.format(user_text=user_text))

print("\nОтвет нейросети:")
print(response.choices[0].message.content)