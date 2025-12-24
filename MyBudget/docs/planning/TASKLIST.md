5. Как импортировать курс валют? Откуда? В разных форматах? Каким образом будет сделан пересчёт?    
6. Откуда тянуть данные? ТАк же хочу крипту и акции
7. Насколько в ddd хорошо иметь nulluable значение? Для id норм?
8. Пресеты конвертаций, выбор своего курса конвертации, 
11. Сделать API общую и для себя для получение цены в белграде на квартиры (сделать открытую в гите)
12. Подсосаться к API steam и добавть свой инветать 
13. kucoin тоже получить
14. Сделать уровень дисирфекации
15. Сделай свои быстрый курс конвертации и насклько я это проебал по отношению курсу ЦБ
16. Почитать о use case
17. Исправить баг с темой просто разобраться почему она не меняется дебаг стоит
18. Разработь ML для оценки своей хаты
19. Сначала повторить one money улучшить базу, а потом уже лезть далее
20. Там сервак микросервесую архитектуру пощупать все дела
22. Проверить всё оптимизацию под конец
24. Возможно добавить сжатие для базы данных
26. Сделать workshop с темами для этого нужна полная кастомизация интерфейса
27. Add to minimalization navigation 
28. Add to beatiful widget display calendar for each page for filter and i can to add dashabord
29. add to custom widget for display calendar and day for my proposose   
30. get data from sms
13. To do reffacot classes filter_date and transaction list to have ancestorj
14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 14. To add widget for calander to generic 
Давай разберем твой код и то, где должна жить логика.

### 1. Твой текущий код (`Account`)
Сейчас твой класс `Account` — это **Анемичная модель (Anemic Domain Model)**.
Это просто **мешок с данными**. Он выглядит как "отражение таблицы БД".
В нем есть поля (`balance`, `name`), но **нет поведения**.

В подходе DDD это считается анти-паттерном (если мы говорим о сложной логике).

### 2. Где должна быть логика? (Битва UseCase vs Entity)

В DDD есть четкое разделение бизнес-правил:

1.  **Enterprise Business Rules (Правила Предприятия) -> Живут в ENTITY (`Account`)**
    Это правила, которые верны всегда, даже если у нас нет приложения.
    *   *Пример:* "Нельзя снять денег больше, чем есть на балансе".
    *   *Пример:* "Если валюта счета 'RUB', комиссия 0%".
    *   Это **суть** твоего бизнеса.

2.  **Application Business Rules (Правила Приложения) -> Живут в USE CASE**
    Это сценарии того, как приложение работает с этими правилами.
    *   *Пример:* "Достань аккаунт из базы, попробуй снять деньги, если ок — сохрани в базу и отправь пуш-уведомление".

---

### 3. Как превратить твой код в DDD (Богатая модель)

Давай перенесем логику списания баланса **ВНУТРЬ** класса `Account`. Он не должен быть просто таблицей, он должен быть "умным".

*Твой код переписанный под DDD:*

```dart
class Account extends Equatable {
  // Поля остаются те же (они final, иммутабельность - это круто)
  final String id;
  final double balance;
  // ... остальные поля

  const Account({required this.id, required this.balance});

  // --- ВОТ ОНА, БИЗНЕС ЛОГИКА (Behavior) ---
  
  // Метод возвращает НОВЫЙ экземпляр Account с измененным балансом.
  // Или кидает ошибку, если правила нарушены.
  Account withdraw(double amount) {
    if (amount <= 0) {
      throw Exception("Сумма списания должна быть положительной");
    }
    
    if (amount > balance) {
      throw Exception("Недостаточно средств. Баланс: $balance, нужно: $amount");
    }

    // Если всё ок, возвращаем копию себя с новым балансом
    return copyWith(balance: this.balance - amount);
  }

  // Пример еще одной логики
  bool get isVipClient => balance > 1000000;

  // Твой copyWith и props остаются тут
  Account copyWith({double? balance}) {
    return Account(id: this.id, balance: balance ?? this.balance);
  }
  
  @override
  List<Object?> get props => [id, balance];
}
```

### 4. А что тогда делает Use Case?

Теперь Use Case перестает быть "калькулятором" и становится **Дирижером (Orchestrator)**. Он просто говорит объектам, что делать, и сохраняет результат.

Вот как выглядит сценарий списания денег:

```dart
class WithdrawMoneyUseCase {
  final AccountRepository repository;

  WithdrawMoneyUseCase(this.repository);

  Future<void> call(String accountId, double amount) async {
    // 1. Получаем текущее состояние (загружаем сущность)
    final Account account = await repository.getAccount(accountId);

    try {
      // 2. Делегируем бизнес-логику САМОЙ СУЩНОСТИ.
      // UseCase не знает, можно ли списывать. Account сам знает.
      final Account updatedAccount = account.withdraw(amount);

      // 3. Сохраняем новое состояние
      await repository.saveAccount(updatedAccount);
      
      // 4. (Опционально) Добавляем запись в историю транзакций
      // await transactionRepo.add(...)
      
    } catch (e) {
      // Обрабатываем ошибку ("Недостаточно средств") и кидаем на UI
      rethrow;
    }
  }
}
```

### В чем разница?

#### Вариант "Анемичный" (Без DDD, просто Clean Architecture):
*   **UseCase:** `if (account.balance < amount) throw Error; double newBalance = account.balance - amount;`
*   **Account:** Просто хранит цифры.
*   **Проблема:** Если у тебя списание денег происходит в 5 разных местах приложения, ты 5 раз напишешь проверку `if (balance < amount)`. Ты размажешь логику.

#### Вариант "Rich Model" (DDD):
*   **Account:** `withdraw()` — вся логика проверки тут.
*   **UseCase:** `account.withdraw()` — просто вызов.
*   **Плюс:** Если завтра правило изменится (например, "можно уходить в минус на 100 рублей"), ты поменяешь это **только в одном месте** — внутри класса `Account`. Все UseCase-ы автоматически начнут работать по-новому.

### Резюме: Кто за что отвечает?

1.  **Account (Entity):**
    *   Отвечает за **Инварианты** (Целостность данных).
    *   "Я не позволю создать себя с отрицательным балансом".
    *   "Я сам посчитаю, сколько останется денег".

2.  **UseCase:**
    *   Отвечает за **Поток операций**.
    *   "Взять из БД -> Вызвать метод сущности -> Сохранить в БД".
    *   Тут живут транзакции (начать транзакцию БД, выполнить действия, закоммитить).

3.  **Repository:**
    *   Просто тупо сохраняет и загружает то, что ему дали.

**Вердикт по твоему коду:**
Твой текущий `Account` — это хорошая заготовка. Чтобы это стало DDD, начни добавлять в него методы действий (`withdraw`, `deposit`, `changeName`), вместо того чтобы менять поля `balance` где-то снаружи.

**Правило большого пальца:**
Если ты видишь в UseCase код типа:
`account.balance = account.balance + 100;`
Это **плохо**.
Должно быть:
`account = account.deposit(100);`

