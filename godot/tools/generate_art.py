#!/usr/bin/env python3
"""Генерация картинок для «Котят-пиратов» через Pollinations.ai (бесплатно, без ключа).

Запуск: python3 tools/generate_art.py [--dry-run]
Для конкретного экрана: python3 tools/generate_art.py --screen 08_transport
Для конкретного предмета: python3 tools/generate_art.py --item jetski
"""
import argparse, json, os, subprocess, sys, time, urllib.parse
from pathlib import Path

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

# Pollinations.ai — бесплатный FLUX без API ключа
API_URL = "https://image.pollinations.ai/prompt/{prompt}?model=flux&width=1024&height=1024&nologo=true&seed={seed}"
TIMEOUT = 120  # 2 мин на картинку (обычно 3-10 с)
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "art")
SCREENS_JSON = os.path.join(os.path.dirname(__file__), "..", "data", "screens.json")

# --- Единый стиль для ВСЕХ картинок «Котят-пиратов» ---
STYLE = (
    "cute children's book illustration, flat vector style, thick soft outlines, "
    "bright cheerful colors, simple shapes, toddler-friendly, single object centered, "
    "isolated on solid flat light blue background, no text, no letters, no watermark, "
    "pirate kitten theme, storybook art"
)

# Промпты для типов сущностей
ANIM_TPL = (
    "A cute pirate kitten {desc}. {extra} "
    "Kind expressive eyes, cheerful friendly expression. "
    "ANATOMY (MANDATORY): exactly one head, exactly two eyes, exactly one mouth, "
    "exactly one nose. EXACTLY FOUR LEGS (two front and two back) — never more, never fewer. "
    "EXACTLY ONE TAIL. No extra limbs, no duplicate body parts, no mutation. "
    "Stylized and child-friendly, simplified shapes for preschool educational materials. "
    "Slightly whimsical and magical, fairy-tale children's book style. "
    "Only the kitten. No extra body parts. No grass, no flowers, no scenery, no extra objects.\n\n"
    "{style}"
)

OBJECT_TPL = (
    "A cute {desc}. {extra} "
    "Simple clean outlines, smooth flat color fills, charming storybook style.\n\n"
    "{style}\n\n"
    "no face, no eyes, no mouth, no smile, no cartoon face"
)

NEGATIVE_ANIM = (
    "photorealistic, 3d render, photo, complex background, gradient, multiple objects, "
    "text, letters, watermark, blurry, cropped, partial object, logo, "
    "extra legs, extra tail, extra head, duplicate limbs, duplicate body parts, "
    "mutation, deformed anatomy, two heads, three legs, forked tail"
)

NEGATIVE_OBJ = NEGATIVE_ANIM + ", face, eyes, smile, cartoon face"

# Дескрипторы предметов (key=item_id из screens.json)
ITEMS = {
    # ── 01_colors ──
    "pomegranate":     ("cute red pomegranate fruit", "round with small crown on top"),
    "bottle_mail":     ("blue glass bottle with a rolled letter inside", "cork stopper, tiny paper scroll"),
    "banana":          ("yellow banana", "slightly curved, bright yellow peel"),
    "watermelon":      ("green striped watermelon", "round, dark green stripes"),
    "pink_shell":      ("pink seashell", "fan-shaped, delicate ridges"),
    "coconut":         ("brown coconut", "round with hairy shell"),
    # ── 02_opposites ──
    "anchor":          ("heavy iron ship anchor", "large, rusty, with chain links"),
    "feather":         ("tiny light fluffy feather", "soft pastel color, floating"),
    "hot_cocoa":       ("mug of hot cocoa with steam swirls", "white ceramic mug"),
    "cold_compote":    ("glass of compote with ice cubes", "tall glass, red berry drink"),
    "big_ship":        ("huge tall sailing galleon", "three masts, white sails"),
    "small_boat":      ("tiny wooden rowboat", "small, brown, with oars"),
    "full_bag":        ("stuffed full burlap sack bulging with gold", "tied rope, round"),
    "empty_bag":       ("flat empty deflated burlap sack", "no contents, wrinkled"),
    "long_rope":       ("very long coiled ship rope", "thick, brown, coiled"),
    "short_pencil":    ("tiny short pencil stub", "well-used, colorful"),
    "sweet_honey":     ("honey pot with dripping golden honey", "ceramic pot, bees nearby"),
    "bitter_remedy":   ("bottle of green herbal medicine", "glass bottle with label"),
    "cracker":         ("tasty biscuit cracker", "round, golden brown"),
    "cannonball":      ("black iron cannonball", "round, shiny, heavy"),
    "soft_pillow":     ("soft fluffy pillow", "white, with a dent"),
    "hard_nut":        ("hard walnut", "round with rough shell"),
    # ── 03_shapes ──
    "porthole":        ("round ship porthole window", "circular, brass frame, blue glass"),
    "chest":           ("square treasure chest", "wooden with gold trim, open lid"),
    "sail":            ("triangular white sail", "on wooden mast, catching wind"),
    "gangway":         ("long rectangular wooden gangway plank", "brown, with rope railing"),
    "parrot_egg":      ("oval egg", "speckled, colorful, in nest"),
    "candy":           ("rhombus shaped wrapped candy", "colorful wrapper, twisted ends"),
    # ── 04_day ──
    "wake":            ("kitten waking up stretching in bed", "sun through porthole, morning"),
    "exercise":        ("kitten doing morning exercises on deck", "stretching arms, sailor bandana"),
    "washing":         ("kitten washing face with soap bubbles", "cute, bubbles floating"),
    "dressing":        ("kitten putting on sailor shirt", "white shirt, blue collar"),
    "breakfast":       ("kitten eating fish porridge breakfast", "bowl, spoon, morning"),
    "study":           ("kitten studying a treasure map", "map spread out, curious eyes"),
    "lunch":           ("kitten eating soup lunch", "bowl of soup, spoon"),
    "nap":             ("kitten sleeping in a hammock", "peaceful, ocean background"),
    "games":           ("kittens playing with a ball on deck", "two kittens, colorful ball"),
    "supper":          ("kitten having evening dinner", "plate with food, candle"),
    "bath":            ("kitten swimming in the sea", "near ship, waves, happy"),
    "sleep":           ("kitten sleeping under a blanket", "moon and stars through porthole"),
    # ── 05_counting ──
    "coin":            ("shiny gold doubloon coin", "skull emblem, pirate treasure"),
    "shell":           ("white spiral seashell", "delicate, ocean find"),
    "star":            ("cute pink five-point starfish", "ocean creature, simple shape"),
    "barrel":          ("small wooden barrel", "iron hoops, rum barrel style"),
    # ── 07_emotions ──
    "joy":             ("kitten face with huge happy smile", "eyes closed in joy"),
    "delight":         ("kitten face squealing with delight", "sparkling eyes, open mouth"),
    "surprise":        ("kitten face astonished", "wide open eyes and mouth"),
    "fear":            ("kitten face scared", "fluffy trembling tail visible"),
    "sadness":         ("kitten face sad", "drooping ears, teary eyes"),
    "offense":         ("kitten face pouting", "turned away, offended"),
    "displeasure":     ("kitten face grumpy frowning", "brows angled"),
    # ── 08_transport ──
    "boat":            ("small motor speedboat", "blue, fast, on water"),
    "ferry":           ("car ferry ship", "carrying little cars, white"),
    "jetski":          ("colorful jet ski", "water scooter, sporty"),
    "balloon_air":     ("hot air balloon", "colorful, with wicker basket"),
    "airship":         ("vintage blimp airship", "zeppelin shape, with fins"),
    "tuk_tuk":         ("three-wheeled tuk-tuk taxi", "colorful, cute"),
    "tram":            ("cute retro city tram", "colorful, with windows"),
    "funicular":       ("funicular cable car", "climbing a hill, on rails"),
    "bathyscaphe":     ("deep-sea bathyscaphe submersible", "round, with portholes"),
    "rocket":          ("cartoon space rocket", "taking off, flames"),
    # ── 09_concert ──
    "synthesizer":     ("toy electronic synthesizer keyboard", "colorful buttons"),
    "ukulele":         ("tiny ukulele guitar", "four strings, small body"),
    "tambourine":      ("tambourine with jingles", "round, with metal discs"),
    "barrel_organ":    ("vintage street barrel organ", "with crank handle"),
    "trombone":        ("brass trombone", "slide extended, shiny"),
    "timpani":         ("copper kettledrum timpani", "with mallets, round"),
    "xylophone":       ("colorful toy xylophone", "rainbow bars, mallets"),
    "harp":            ("golden concert harp", "many strings, ornate"),
    "rattle":          ("wooden ratchet percussion noisemaker", "hand-held, clicking"),
    # ── 10_seasons ──
    "spring":          ("kitten sailing among blooming spring trees", "flowers, butterflies"),
    "summer":          ("kitten sunbathing on beach", "umbrella, bright sun, sand"),
    "autumn":          ("kitten playing in falling autumn leaves", "orange red leaves"),
    "winter":          ("kitten in warm hat building a snowman", "snow, scarf, cold"),
    # ── 11_sport ──
    "trampoline":      ("round trampoline", "bouncy, colorful edge"),
    "barbell":         ("barbell with round plates", "gym equipment"),
    "rollers":         ("roller skates", "colorful, with wheels"),
    "rower":           ("rowing machine exerciser", "indoor, with seat and handle"),
    "badminton":       ("badminton racket with shuttlecock", "white feathers"),
    "pullup_bar":      ("horizontal pull-up bar", "metal, simple"),
    "volleyball":      ("volleyball ball over a net", "white ball, blue net"),
    "scooter":         ("kick scooter", "colorful, with handlebars"),
    # ── 12_jobs ──
    "vet":             ("kitten veterinarian", "stethoscope, holding puppy"),
    "magician":        ("kitten magician", "top hat, magic wand, sparkles"),
    "confectioner":    ("kitten confectioner", "decorating a cake, chef hat"),
    "gardener":        ("kitten gardener", "watering can, flowers"),
    "captain":         ("kitten sea captain", "at ship wheel, tricorn hat"),
    "lifeguard":       ("kitten lifeguard", "lifebuoy ring, beach tower"),
    "singer":          ("kitten singer", "microphone, stage spotlight"),
    "astronaut":       ("kitten astronaut", "spacesuit, helmet, stars"),
}


def check_server():
    try:
        result = subprocess.run(
            ["curl", "-s", "-m", "15", "-o", "/dev/null", "-w", "%{http_code}",
             "https://image.pollinations.ai/prompt/test?model=flux&width=64&height=64&nologo=true"],
            capture_output=True, text=True, timeout=20
        )
        if result.stdout.strip() == "200":
            print("✓ Pollinations.ai доступен")
            return True
        else:
            print(f"✗ Pollinations.ai: HTTP {result.stdout.strip()}")
            return False
    except Exception as e:
        print(f"✗ Pollinations.ai недоступен: {e}")
        return False


def generate_one(item_id: str, desc: str, extra: str, kind: str = "object",
                 seed: int = 42, dry_run: bool = False) -> str | None:
    folder = "misc"
    for sid, items_list in SCREEN_ITEMS.items():
        if item_id in items_list:
            folder = sid
            break

    out_dir = os.path.join(OUT_DIR, folder)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{item_id}.png")

    if os.path.exists(out_path):
        print(f"  ✓ Уже есть: {out_path}")
        return out_path

    if kind == "anim":
        prompt = ANIM_TPL.format(desc=desc, extra=extra, style=STYLE)
    else:
        prompt = OBJECT_TPL.format(desc=desc, extra=extra, style=STYLE)

    if dry_run:
        print(f"  [dry-run] seed={seed} → {out_path}")
        return out_path

    encoded_prompt = urllib.parse.quote(prompt)
    url = API_URL.format(prompt=encoded_prompt, seed=seed)

    print(f"  → {item_id} (seed={seed})...", end=" ", flush=True)
    t0 = time.time()

    try:
        result = subprocess.run(
            ["curl", "-s", "-m", str(TIMEOUT), "-o", out_path, "-w", "%{http_code}",
             url],
            capture_output=True, text=True, timeout=TIMEOUT + 10
        )
        if result.stdout.strip() == "200" and os.path.exists(out_path):
            # Pollinations возвращает JPEG — конвертируем в настоящий PNG
            if HAS_PIL:
                try:
                    img = Image.open(out_path)
                    if img.mode != "RGBA":
                        img = img.convert("RGBA")
                    img.save(out_path, "PNG")
                except Exception as ce:
                    print(f"(конвертация: {ce})", end=" ")
            file_size = os.path.getsize(out_path)
            elapsed = time.time() - t0
            print(f"✓ {file_size//1024}KB {elapsed:.0f}s")
            return out_path
        else:
            print(f"✗ HTTP {result.stdout.strip()}")
            if os.path.exists(out_path):
                os.remove(out_path)
            return None
    except Exception as e:
        print(f"✗ {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description="Генерация арта для Котят-пиратов")
    parser.add_argument("--screen", help="Только указанный экран (id, напр. 08_transport)")
    parser.add_argument("--item", help="Только указанный предмет (id, напр. jetski)")
    parser.add_argument("--seed", type=int, default=42, help="Базовый seed")
    parser.add_argument("--dry-run", action="store_true", help="Только показать план, не генерировать")
    args = parser.parse_args()

    if not args.dry_run and not check_server():
        sys.exit(1)

    # Загружаем screens.json для маппинга screen_id → items
    with open(SCREENS_JSON) as f:
        data = json.load(f)
    global SCREEN_ITEMS
    SCREEN_ITEMS = {}
    for scr in data.get("screens", []):
        sid = scr.get("id", "")
        SCREEN_ITEMS[sid] = {it["id"] for it in scr.get("items", [])}

    # Фильтрация
    items_to_gen = {}
    if args.item:
        if args.item not in ITEMS:
            print(f"Неизвестный item_id: {args.item}")
            sys.exit(1)
        items_to_gen[args.item] = ITEMS[args.item]
    elif args.screen:
        if args.screen not in SCREEN_ITEMS:
            print(f"Неизвестный screen_id: {args.screen}")
            sys.exit(1)
        for iid in ITEMS:
            if iid in SCREEN_ITEMS[args.screen]:
                items_to_gen[iid] = ITEMS[iid]
    else:
        items_to_gen = ITEMS

    # Определяем тип (anim/object): эмоции, день, профессии, сезоны = anim
    ANIM_SCREENS = {"04_day", "07_emotions", "10_seasons", "12_jobs"}
    # Контакты рации — отдельно (не в screens.json items)
    RADIO_CONTACTS = {
        "contact_1": ("cute pirate captain kitten with tricorn hat", "black coat, gold trim"),
        "contact_2": ("cute sailor kitten with bandana", "white shirt, blue scarf"),
        "contact_3": ("tiny cabin-boy kitten", "small, eager, with bucket"),
        "contact_4": ("friendly cartoon pirate parrot", "eye patch, colorful feathers"),
        "contact_5": ("friendly cartoon crab", "red, with big claws"),
        "contact_6": ("cute smiling jellyfish", "pink, translucent, tentacles"),
        "contact_7": ("friendly smiling whale", "blue, round, spout"),
        "contact_8": ("playful dolphin", "gray, jumping, happy"),
        "contact_9": ("kind octopus in sailor hat", "purple, eight arms, friendly"),
    }

    # Генерация
    print(f"\n=== Генерация {len(items_to_gen)} картинок ===\n")
    generated = 0
    failed = 0

    for i, (iid, (desc, extra)) in enumerate(items_to_gen.items()):
        # Определяем kind
        kind = "anim"
        for sid, item_set in SCREEN_ITEMS.items():
            if iid in item_set and sid not in ANIM_SCREENS:
                kind = "object"
                break

        seed = args.seed + i * 7  # Уникальный seed на каждый предмет
        result = generate_one(iid, desc, extra, kind, seed, args.dry_run)
        if result:
            generated += 1
        else:
            failed += 1

    # Контакты рации
    if args.screen in (None, "06_radio") and not args.item:
        print(f"\n=== Аватары контактов ({len(RADIO_CONTACTS)}) ===\n")
        radio_dir = os.path.join(OUT_DIR, "06_radio")
        os.makedirs(radio_dir, exist_ok=True)
        for cid, (desc, extra) in RADIO_CONTACTS.items():
            out_path = os.path.join(radio_dir, f"{cid}.png")
            if os.path.exists(out_path):
                print(f"  ✓ Уже есть: {out_path}")
                continue
            seed = args.seed + 1000 + list(RADIO_CONTACTS.keys()).index(cid) * 7
            kind = "anim" if "kitten" in desc else "object"
            result = generate_one(cid, desc, extra, kind, seed, args.dry_run)
            if result:
                generated += 1
            else:
                failed += 1

    STICKERS = {
        "01_colors":     ("cute pirate kitten hugging a rainbow balloon", "sparkles, celebration"),
        "02_opposites":  ("cute pirate kitten holding a balance scale", "stars, balanced"),
        "03_shapes":     ("cute pirate kitten with geometric blocks", "building, playful"),
        "04_day":        ("cute pirate kitten yawning with a nightcap", "sleepy, cozy"),
        "05_counting":   ("cute pirate kitten counting gold coins", "paws up, treasure"),
        "06_radio":      ("cute pirate kitten speaking into a walkie-talkie", "ahoy, signal waves"),
        "07_emotions":   ("cute pirate kitten with heart eyes", "love, joy"),
        "08_transport":  ("cute pirate kitten driving a tiny boat", "wind in fur, waves"),
        "09_concert":    ("cute pirate kitten playing a tiny guitar", "musical notes, stage"),
        "10_seasons":    ("cute pirate kitten in a pirate costume with autumn leaves", "festive, seasonal"),
        "11_sport":      ("cute pirate kitten doing a victory pose with a medal", "sports, champion"),
        "12_jobs":       ("cute pirate kitten wearing a captain hat saluting", "proud, professional"),
    }

    if not args.item:
        print(f"\n=== Стикеры награды ({len(STICKERS)}) ===\n")
        for sid, (desc, extra) in STICKERS.items():
            sticker_dir = os.path.join(OUT_DIR, sid)
            os.makedirs(sticker_dir, exist_ok=True)
            out_path = os.path.join(sticker_dir, "sticker.png")
            if os.path.exists(out_path):
                print(f"  ✓ Уже есть: {out_path}")
                continue
            seed = args.seed + 5000 + list(STICKERS.keys()).index(sid) * 7
            result = generate_one(f"{sid}_sticker", desc, extra, "anim", seed, args.dry_run)
            if result:
                final_path = os.path.join(sticker_dir, "sticker.png")
                if result != final_path and os.path.exists(result):
                    os.rename(result, final_path)
                    result = final_path
                generated += 1
            else:
                failed += 1

    print(f"\n=== Итого: сгенерировано {generated}, ошибок {failed} ===")


# Глобальная переменная заполняется в main()
SCREEN_ITEMS: dict[str, set[str]] = {}

if __name__ == "__main__":
    main()
