# Котята-пираты — план генерации арта и озвучки

Документ для продакшена: что нарисовать, что озвучить, в каком стиле, куда положить.
Источник контента: `godot/data/screens.json` (id предметов и тексты заданий совпадают 1-в-1).

---

## 1. Единый стиль иллюстраций

**Базовый суффикс промпта (добавляется к КАЖДОМУ описанию ниже):**

```
cute children's book illustration, flat vector style, thick soft outlines,
bright cheerful colors, simple shapes, toddler-friendly, single object centered,
isolated on plain white background, no text
```

Правила:
- Фон белый/прозрачный — в проекте вырезается (как в азбуке через iloveimg).
- Один объект на картинке, без надписей и без рамок (рамку даёт кнопка в игре).
- Персонажи — котята в пиратском стиле, единая анатомия с маскотом `Cat.png` из Азбуки.
- Разрешение исходника 1024×1024, итог — PNG с альфа-каналом.

## 2. Нейминг и размещение файлов

| Тип | Путь | Пример |
|---|---|---|
| Предмет | `godot/assets/art/{screen_id}/{item_id}.png` | `assets/art/08_transport/jetski.png` |
| Аватар контакта | `godot/assets/art/06_radio/contact_{num}.png` | `contact_3.png` (Пушок) |
| Интерфейс | `godot/assets/art/ui/{name}.png` | `ui/reward_chest.png` |
| Озвучка задания | `godot/assets/audio/tasks/{screen_id}/task_{NN}.mp3` | `audio/tasks/08_transport/task_01.mp3` |
| Подсказка | `godot/assets/audio/hints/{screen_id}/hint_{NN}.mp3` | `audio/hints/01_colors/hint_01.mp3` |
| Общая фраза | `godot/assets/audio/common/{name}.mp3` | `common/praise_02.mp3` |

Номера задач `NN` соответствуют порядку TASK в JSON (не путать: задачи в игре тасуются!).

---

## 3. Картинки по экранам

### Экран 1 — Разноцветный пикник `[01_colors]`
Предмет одного цвета крупным планом, цвет должен читаться мгновенно.

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| pomegranate | Гранат | whole red pomegranate fruit |
| bottle_mail | Бутылка с письмом | blue glass bottle with a rolled letter inside |
| banana | Банан | yellow banana |
| watermelon | Арбуз | green striped watermelon |
| pink_shell | Розовая ракушка | pink seashell |
| coconut | Кокос | brown coconut |

### Экран 2 — Всё наоборот `[02_opposites]`
Пары «наоборот» рисовать в одном масштабе внутри пары, чтобы разница была очевидна.

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| anchor | Якорь | heavy iron ship anchor |
| feather | Пёрышко | tiny light fluffy feather |
| hot_cocoa | Горячее какао | mug of hot cocoa with steam swirls |
| cold_compote | Компот со льдом | glass of compote with ice cubes |
| big_ship | Большой корабль | huge tall sailing galleon |
| small_boat | Маленькая лодочка | tiny wooden rowboat |
| full_bag | Полный мешок | stuffed full burlap sack bulging with gold |
| empty_bag | Пустой мешок | flat empty deflated burlap sack |
| long_rope | Длинная верёвка | very long coiled ship rope |
| short_pencil | Короткий карандаш | tiny short pencil stub |
| sweet_honey | Сладкий мёд | honey pot with dripping golden honey and bees |
| bitter_remedy | Горькая микстура | bottle of green herbal medicine mixture |
| cracker | Съедобный сухарик | tasty biscuit cracker with bite sparkles |
| cannonball | Несъедобное ядро | black iron cannonball |
| soft_pillow | Мягкая подушка | soft fluffy pillow with a dent |
| hard_nut | Твёрдый орех | hard walnut with a small crack |

### Экран 3 — Волшебные формы `[03_shapes]`
Форма — главный герой картинки, предмет узнаваем, но геометрия гипертрофирована.

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| porthole | Иллюминатор | round ship porthole window |
| chest | Сундук | square treasure chest |
| sail | Парус | triangular white sail on a mast |
| gangway | Трап | long rectangular wooden gangway plank |
| parrot_egg | Яйцо попугая | oval egg |
| candy | Конфета | rhombus/diamond shaped wrapped candy |

### Экран 4 — День юнги `[04_day]`
На каждой картинке — юнга Пушок (маленький белый котёнок в бандане) делает действие.

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| wake | Подъём | kitten waking up stretching in bed, sun through porthole |
| exercise | Зарядка | kitten doing morning exercises on deck |
| washing | Умывание | kitten washing face with soap bubbles |
| dressing | Одевание | kitten putting on sailor shirt |
| breakfast | Завтрак | kitten eating fish porridge breakfast |
| study | Учёба | kitten studying a treasure map |
| lunch | Обед | kitten eating soup lunch at table |
| nap | Тихий час | kitten sleeping in a hammock |
| games | Игры на палубе | kittens playing with a ball on deck |
| supper | Ужин | kitten having evening dinner |
| bath | Купание за бортом | kitten swimming in the sea near the ship |
| sleep | Отбой | kitten sleeping under a blanket, moon and stars |

### Экран 5 — Считаем сокровища `[05_counting]`
⚠️ Генерируется всего **4 картинки**, каждая переиспользуется для всех копий группы
(`coin_1…coin_7` → один файл `coin.png` и т.д.). Варианты оттенков в JSON достигаются
модификацией цвета кодом, рисовать отдельно не нужно.

| item_id (базовый) | Название | Ядро промпта (EN) | Файл |
|---|---|---|---|
| coin_* | Монета | shiny gold doubloon coin with skull emblem | `coin.png` |
| shell_* | Ракушка | white spiral seashell | `shell.png` |
| star_* | Морская звезда | cute pink five-point starfish | `star.png` |
| barrel_* | Бочонок | small wooden barrel with iron hoops | `barrel.png` |

### Экран 6 — Рация капитана `[06_radio]`

Аватары персонажей — портрет «плечи-голова», крупное лицо:

| Файл | Кто | Ядро промпта (EN) |
|---|---|---|
| contact_1 | Капитан Барсик | pirate captain kitten with tricorn hat |
| contact_2 | Матрос Мурзик | sailor kitten with bandana |
| contact_3 | Юнга Пушок | tiny cabin-boy kitten |
| contact_4 | Попугай Боцман | pirate parrot with eye patch |
| contact_5 | Краб Клешня | friendly cartoon crab |
| contact_6 | Медуза Зефирка | cute smiling jellyfish |
| contact_7 | Кит Бублик | friendly smiling whale |
| contact_8 | Дельфин Спарк | playful dolphin |
| contact_9 | Осьминог Осип | kind octopus in sailor hat |
| radio.png | Рация | retro walkie-talkie radio toy with big buttons |

### Экран 7 — Хвостик настроения `[07_emotions]`
Мордочка котёнка крупным планом, эмоция утрирована до мгновенного считывания.

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| joy | Радость | kitten face with huge happy smile |
| delight | Восторг | kitten face squealing with delight, sparkling eyes |
| surprise | Удивление | kitten face astonished, wide open eyes and mouth |
| fear | Испуг | kitten face scared, fluffy trembling tail visible |
| sadness | Грусть | kitten face sad, drooping ears, teary eyes |
| offense | Обида | kitten face pouting, turned away offended |
| displeasure | Недовольство | kitten face grumpy frowning, brows angled |

### Экран 8 — Кто плывёт, летает, едет `[08_transport]`

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| boat | Катер | small motor speedboat |
| ferry | Паром | car ferry ship carrying little cars |
| jetski | Гидроцикл | colorful jet ski water scooter |
| balloon_air | Воздушный шар | hot air balloon with wicker basket |
| airship | Дирижабль | vintage blimp airship with fins |
| tuk_tuk | Тук-тук | three-wheeled tuk-tuk taxi |
| tram | Трамвай | cute retro city tram |
| funicular | Фуникулёр | funicular cable car climbing a hill |
| bathyscaphe | Батискаф | deep-sea bathyscaphe submersible with portholes |
| rocket | Ракета | cartoon space rocket taking off |

### Экран 9 — Корабельный оркестр `[09_concert]`

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| synthesizer | Синтезатор | toy electronic synthesizer keyboard |
| ukulele | Укулеле | tiny ukulele guitar |
| tambourine | Бубен | tambourine with jingles |
| barrel_organ | Шарманка | vintage street barrel organ with crank |
| trombone | Тромбон | brass trombone with slide extended |
| timpani | Литавры | copper kettledrum timpani with mallets |
| xylophone | Ксилофон | colorful toy xylophone |
| harp | Арфа | golden concert harp |
| rattle | Трещотки | wooden ratchet percussion noisemaker |

### Экран 10 — Круглый год за бортом `[10_seasons]`
Сцена сезона с котёнком-пиратом в подходящей одежде.

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| spring | Весна | kitten sailing among blooming spring trees and flowers |
| summer | Лето | kitten sunbathing on beach with umbrella, bright sun |
| autumn | Осень | kitten playing in falling autumn leaves |
| winter | Зима | kitten in warm hat building a snowman |

### Экран 11 — Спорт на палубе `[11_sport]`

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| trampoline | Батут | round trampoline |
| barbell | Штанга | barbell with round plates |
| rollers | Ролики | roller skates |
| rower | Гребной тренажёр | rowing machine exerciser |
| badminton | Бадминтон | badminton racket with shuttlecock |
| pullup_bar | Турник | horizontal pull-up bar |
| volleyball | Волейбол | volleyball ball over a net |
| scooter | Самокат | kick scooter |

### Экран 12 — Кем стать коту? `[12_jobs]`
Котёнок в костюме профессии с главным атрибутом.

| item_id | Название | Ядро промпта (EN) |
|---|---|---|
| vet | Ветеринар | kitten veterinarian with stethoscope holding puppy |
| magician | Фокусник | kitten magician with top hat and magic wand |
| confectioner | Кондитер | kitten confectioner decorating a cake |
| gardener | Садовник | kitten gardener with watering can and flowers |
| captain | Капитан | kitten sea captain at ship wheel |
| lifeguard | Спасатель | kitten lifeguard with lifebuoy ring on beach tower |
| singer | Певец | kitten singer with microphone on stage |
| astronaut | Космонавт | kitten astronaut in spacesuit and helmet |

---

## 4. Интерфейсные картинки (опционально, второй приоритет)

| name | Что это | Ядро промпта (EN) |
|---|---|---|
| ui/menu_bg.jpg | Фон главного меню | seamless ocean waves pattern with distant pirate ship, dark navy night |
| ui/reward_chest.png | Награда за экран | open treasure chest overflowing with gold coins and gems |
| ui/pushok_hint.png | Пушок-подсказчик | kitten pointing with paw, thoughtful pose |
| ui/star.png | Звезда прогресса | golden five-point star |

---

## 5. Требования к озвучке

- **Голос:** тёплый женский/детский добрый голос, как в Азбуке (см. `azbuka-src/VOICES.md`).
- **Темп:** медленно и чётко, аудитория 3–6 лет.
- **Формат:** MP3 44.1 kHz, моно, нормализация −16 LUFS, без клиппинга.
- **Интонация:** задания — вопросительно-бодро; похвала — восторженно; подсказки — тихо, «шёпотом помощника»; неуспех — мягко, успокаивающе.
- Каждая фраза — отдельный файл, тишина 0.3 c в начале/конце.

---

## 6. Скрипты озвучки — задания и подсказки

### Экран 1 — Разноцветный пикник `[01_colors]`
| NN | Задание (файл task_NN) | Подсказка (hint_NN) |
|---|---|---|
| 01 | Покажи красный предмет! | Красный, как ягода граната. |
| 02 | Покажи синий предмет! | В ней спрятано письмо. |
| 03 | Найди жёлтое! | Его любит есть мартышка. |
| 04 | Где зелёный предмет? | Снаружи зелёный, внутри красный. |
| 05 | Покажи розовую ракушку! | Она нежного цвета, как цветок. |
| 06 | Найди коричневый предмет! | Он растёт на пальме. |

### Экран 2 — Всё наоборот `[02_opposites]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Покажи тяжёлое! | Оно тянет корабль на дно. |
| 02 | Что холодное? | В нём плавают льдинки. |
| 03 | Найди маленькое! | Помещается на ладошке. |
| 04 | Покажи пустой мешок! | Внутри ничего нет. |
| 05 | Что длинное? | Ею привязывают лодку. |
| 06 | Найди сладкое! | Его делают пчёлы. |
| 07 | Покажи несъедобное! | Это стреляют из пушки. |
| 08 | Что мягкое? | На нём сладко спится. |

### Экран 3 — Волшебные формы `[03_shapes]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Покажи круг! | Круглое окошко в борту корабля. |
| 02 | Покажи квадрат! | В нём хранят сокровища. |
| 03 | Найди треугольник! | Он ловит ветер. |
| 04 | Покажи прямоугольник! | По нему поднимаются на корабль. |
| 05 | Где овал? | Из него скоро вылупится птенец. |
| 06 | Найди ромб! | Сладкая, в красивом фантике. |

### Экран 4 — День юнги `[04_day]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Покажи подъём! | Утром звучит судовой колокол. |
| 02 | Что будет после зарядки? | Брызги воды и мыльные пузыри. |
| 03 | Что идёт после завтрака? | Юнга учит морские карты. |
| 04 | Куда отправимся после обеда? | Гамак и тихая колыбельная. |
| 05 | Что будет после ужина? | Плюх! Тёплая вода. |
| 06 | А что в самом конце дня? | Все котята уже зевают. |

### Экран 5 — Считаем сокровища `[05_counting]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Посчитай монеты — тапай каждую! | Жёлтые круглые блестяшки. |
| 02 | Сколько ракушек? Тапай по одной! | Белые, как пенны волны. |
| 03 | Посчитай морских звёзд! | Розовые пятиногие красавицы. |
| 04 | Сколько бочонков на палубе? | Коричневые, с обручами. |

### Экран 6 — Рация капитана `[06_radio]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Позвони Пушку — набери его номер! | Пушок третий в списке слева. |
| 02 | Позвони попугаю Боцману! | Четвёртая строка списка. |
| 03 | Позвони крабу Клешне! | Он пятый по счёту. |
| 04 | Позвони дельфину Спарку! | Восемь — два кружка друг на друге. |
| 05 | Позвони киту Бублику! | Семь — как флажок-галочка. |

### Экран 7 — Хвостик настроения `[07_emotions]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Кто нашёл клад? Покажи радость! | Улыбка до ушей. |
| 02 | Море было очень-очень чудесным! Найди восторг. | Радость в квадрате! |
| 03 | Из-за волны выглянул огромный кит. Кто ахнул? | Глаза стали большими-большими. |
| 04 | Грянул гром. Кто испугался? | Хвост распушился и дрожит. |
| 05 | Игрушка упала за борт. Кто загрустил? | Ушки опустились вниз. |
| 06 | У котёнка забрали рыбку. Покажи обиду. | Губки надули и отвернулись. |
| 07 | Котёнку сказали ложиться спать. Кто недоволен? | Брови домиком, хвост трубой. |

### Экран 8 — Кто плывёт, летает, едет `[08_transport]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Покажи батискаф! | Ныряет глубже всех и не боится давления. |
| 02 | Где дирижабль? | Огромный, как сигара, летит медленно. |
| 03 | Найди ракету! | Летает к звёздам. |
| 04 | Покажи гидроцикл! | Мотоцикл, который бегает по волнам. |
| 05 | Где фуникулёр? | Вагончик поднимается в гору по рельсам. |
| 06 | Найди тук-тук! | Маленькая машина с тремя колёсами. |
| 07 | Покажи паром! | Перевозит машины через море. |
| 08 | Где воздушный шар? | Внизу висит корзинка. |

### Экран 9 — Корабельный оркестр `[09_concert]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Покажи синтезатор! | Электрический, с кнопочками-клавишами. |
| 02 | Где укулеле? | Совсем маленькая, с четырьмя струнами. |
| 03 | Найди бубен! | Кружок с колокольчиками по краю. |
| 04 | Покажи шарманку! | Крутишь ручку — играет мелодия. |
| 05 | Где тромбон? | У него выдвигается длинная труба. |
| 06 | Найди литавры! | Медные котлы, в них бьют палками. |
| 07 | Покажи арфу! | Выше котёнка ростом, струн — видимо-невидимо. |

### Экран 10 — Круглый год за бортом `[10_seasons]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Найди зиму! | Самое холодное время года. |
| 02 | Когда тает снег и бегут ручейки? | После зимы приходит весна. |
| 03 | В какое время купаются в море? | Самое жаркое и солнечное. |
| 04 | Когда падают жёлтые листья? | Потом придёт зима. |
| 05 | Когда лепят снежную бабу? | Нужен снег и варежки. |

### Экран 11 — Спорт на палубе `[11_sport]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Покажи турник! | На нём подтягиваются. |
| 02 | Где бадминтон? | Ракетка и воланчик-ракушка. |
| 03 | Найди ролики! | Обувь на колёсиках. |
| 04 | Покажи батут! | Прыгаешь высоко-высоко. |
| 05 | Где самокат? | Отталкиваешься ножкой и едешь. |
| 06 | Найди гребной тренажёр! | Как грести вёслами, только на месте. |

### Экран 12 — Кем стать коту? `[12_jobs]`
| NN | Задание | Подсказка |
|---|---|---|
| 01 | Кто лечит больных зверят? | Доктор для котиков и собачек. |
| 02 | Кто показывает фокусы? | Достаёт кролика из пустой шляпы. |
| 03 | Кто печёт торты и пирожные? | Шапочка из крема ему к лицу. |
| 04 | Кто выращивает цветы и деревья? | Лейка и лопатка — его инструменты. |
| 05 | Кто ведёт корабль через море? | Стоит у штурвала в белой форме. |
| 06 | Кто спасает тех, кто тонет? | Дежурит на пляже со спасательным кругом. |
| 07 | Кто поёт песни на сцене? | Микрофон — его лучший друг. |
| 08 | Кто летает к звёздам на ракете? | Носит скафандр и шлем. |

---

## 7. Общие фразы `[common]`

| Файл | Текст | Интонация |
|---|---|---|
| praise_01 | Мяу! Верно! | радостно |
| praise_02 | Да, молодец, капитан! | восторженно |
| praise_03 | Точно в цель! Ус-пех! | чеканя по слогам |
| praise_04 | Вот это глазастый! | удивлённо-радостно |
| praise_05 | Так держать, юнга! | бодро |
| wrong_01 | Почти! Попробуй ещё. | мягко |
| wrong_02 | Не-а, посмотри внимательнее. | ласково |
| wrong_03 | Есть ещё варианты! | подбадривающе |
| wrong_think | Подумай ещё немного... | тихо |
| reward_01 | Ура! Экран пройден! Ты настоящий пират! | торжественно |
| reward_02 | Все задания решены! Так держать! | гордо |
| menu_title | Котята-пираты! Выбирай игру! | звонко |

## 8. Ответы контактов рации `[radio]`
Проигрываются при верном номере: «На связи! …»

| Файл | Текст |
|---|---|
| radio_answer_3 | На связи! Юнга Пушок слушает! |
| radio_answer_4 | Кар-раул! Попугай Боцман на связи! |
| radio_answer_5 | Кла-кла! Краб Клешня отвечает! |
| radio_answer_8 | Свисти-и-и! Дельфин Спарк тут! |
| radio_answer_7 | Ууу-ууу! Кит Бублик слышит тебя! |

*(для остальных контактов 1, 2, 6, 9 — записать такие же, пригодятся при расширении)*

---

## 9. Сводка объёмов

| Блок | Кол-во |
|---|---|
| Картинки-предметы (уникальных файлов) | 90 |
| — в т.ч. счёт вместо 23 кнопок | 4 файла (переиспользуются) |
| Аватары контактов + рация | 10 |
| UI (опционально) | 4 |
| **Итого картинок** | **≈104** |
| Озвучка заданий | 76 |
| Озвучка подсказок | 76 |
| Общие фразы | 12 |
| Реплики рации | 5–9 |
| **Итого аудио** | **≈170** |

**Порядок работ:** 1) экран 3 «Формы» (MVP-экран) → 2) экран 1 «Цвета» → 3) транспорт/спорт/профессии → 4) остальное. Звуки интерфейса (тап, звонок рации, фанфары награды) — синтезируются кодом/берутся из бесплатных библиотек, актёру не нужны.
