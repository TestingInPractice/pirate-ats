#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generation manifest for pirate-cats-book FLUX2 art regeneration.

Targets: screens 08_transport, 09_concert, 10_spring, 10_winter (all items),
06_radio contacts (9), plus a new cover illustration.

Each item: fixed seed for style consistency across a screen. Output filenames
match existing assets so they can be wired in later (NOT overwritten now; placed
in assets/art/generated/<screen>/).

kind: 'obj'   -> OBJECT_TPL (no face in negative)
      'cat'   -> 4 legs, one tail, two ears (kitten)
      'bird'  -> one body, two legs, two wings, one beak
      'insect'-> butterfly/pollinator: exactly two wings, two antennae, six legs
      'crab'  -> exactly two claws and eight legs
      'jelly' -> single dome body with tentacles, no legs
      'whale' -> one body, one tail fin (no legs)
      'dolphin'-> one body, one tail fin, two side flippers
      'octo'  -> one head, exactly eight tentacles
      'cover' -> full scene illustration (title/cover art)
"""
import json, os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "assets", "art", "generated")

# Fixed seeds per screen (arbitrary unique ints) -> per-item seed = base + index
SEED_BASE = {
    "08_transport": 102401,
    "09_concert":   102501,
    "10_spring":    102601,
    "10_winter":    102701,
    "06_radio":     102801,
}

# (slug, kind, ru_label, en_description)
ITEMS = {
    "08_transport": [
        ("car",        "obj", "Машина",  "a cute red cartoon car for a children's picture, simple rounded body, round wheels, friendly vehicle, no driver"),
        ("bus",        "obj", "Автобус", "a cute yellow cartoon city bus for a children's picture, rounded body, clean windows, wheels, no driver"),
        ("tram",       "obj", "Трамвай", "a cute cartoon tram for a children's picture, rounded blue tram car on rails, wheels, no driver"),
        ("train",      "obj", "Поезд",   "a cute cartoon train for a children's picture, engine with passenger cars, round wheels, no driver"),
        ("bicycle",    "obj", "Велосипед", "a cute cartoon bicycle for a children's picture, two round wheels, simple frame, handlebars, no rider"),
        ("scooter",    "obj", "Самокат", "a cute cartoon kick scooter for a children's picture, two small wheels, simple deck and handlebar, no rider"),
        ("airplane",   "obj", "Самолёт", "a cute cartoon airplane for a children's picture, rounded fuselage, two wings, tail, no pilot"),
        ("helicopter", "obj", "Вертолёт", "a cute cartoon helicopter for a children's picture, rounded body, one main rotor and tail rotor, no pilot"),
    ],
    "09_concert": [
        ("balalaika", "obj", "Балалайка", "a cute balalaika for a children's picture, triangular wooden body with three strings and a long neck, folk instrument"),
        ("domra",     "obj", "Домра",     "a cute domra for a children's picture, round wooden body with a long neck and three strings, folk instrument"),
        ("gusli",     "obj", "Гусли",     "a cute gusli for a children's picture, flat wooden zither with strings, ancient slavic instrument"),
        ("bayan",     "obj", "Баян",      "a cute bayan accordion for a children's picture, large button accordion with rounded sides and bellows"),
        ("accordion", "obj", "Гармонь",   "a cute accordion for a children's picture, smaller accordion with buttons and bellows"),
        ("rozhok",    "obj", "Рожок",     "a cute wooden horn (rozhok) for a children's picture, curved wooden shepherd horn"),
        ("svirel",    "obj", "Свирель",   "a cute svirel flute for a children's picture, simple wooden pipe flute, folk instrument"),
        ("spoons",    "obj", "Ложки",     "a pair of cute wooden spoons for a children's picture, carved folk music spoons held together"),
        ("rattle",    "obj", "Трещотки",  "a cute wooden rattle (treshchotka) for a children's picture, slatted folk percussion instrument"),
    ],
    "10_spring": [
        ("sun",      "obj",  "Солнышко", "a cute smiling cartoon sun for a children's picture, round yellow sun with soft rays, kind face"),
        ("flower",   "obj",  "Цветочек", "a cute spring flower for a children's picture, a single cheerful flower with petals, stem and leaves"),
        ("butterfly","insect","Бабочка", "a cute cartoon butterfly for a children's picture, blue and orange wings with simple patterns"),
        ("rain",     "obj",  "Дождик",   "a cute cartoon rain cloud for a children's picture, fluffy cloud with raindrops falling, friendly"),
        ("kitten",   "cat",  "Котик в плащике", "a cute kitten wearing a small yellow raincoat for a children's picture, holding an umbrella"),
    ],
    "10_winter": [
        ("snowflake","obj", "Снежинка", "a cute snowflake for a children's picture, six-pointed white snowflake, simple symmetric crystal"),
        ("snowman",  "obj", "Снеговик", "a cute cartoon snowman for a children's picture, three snow balls, carrot nose, coal eyes, scarf and hat"),
        ("sled",     "obj", "Санки",    "a cute wooden sleigh for a children's picture, simple sled with runners, no rider"),
        ("scarf",    "obj", "Шарф",     "a cute knitted winter scarf for a children's picture, striped cozy scarf, flat lay"),
        ("kitten",   "cat", "Котик в шубке", "a cute kitten wearing a cozy winter coat for a children's picture, happy"),
    ],
    "06_radio": [
        ("contact_1", "cat",   "Капитан Барсик",  "a friendly cartoon captain pirate kitten portrait, wearing a captain hat with a tiny anchor"),
        ("contact_2", "cat",   "Матрос Мурзик",   "a friendly cartoon sailor pirate kitten portrait, wearing a sailor hat and striped collar"),
        ("contact_3", "cat",   "Юнга Пушок",      "a friendly cartoon young cabin boy kitten portrait, wearing a small bandana"),
        ("contact_4", "bird",  "Попугай Боцман",  "a friendly cartoon bosun parrot portrait, wearing a tiny sailor hat"),
        ("contact_5", "crab",  "Краб Клешня",     "a friendly cartoon red crab portrait, cheerful with two claws"),
        ("contact_6", "jelly", "Медуза Зефирка",  "a friendly cartoon pink jellyfish portrait, rounded dome with soft tentacles"),
        ("contact_7", "whale", "Кит Бублик",      "a friendly cartoon blue whale portrait, smiling, round body"),
        ("contact_8", "dolphin","Дельфин Спарк",  "a friendly cartoon dolphin portrait, smiling, smooth gray body"),
        ("contact_9", "octo",  "Осьминог Осип",   "a friendly cartoon orange octopus portrait, round head with eight tentacles"),
    ],
}

# Negative prompt base
NEG_BASE = (
    "photorealistic, 3d render, photo, complex background, gradient, multiple objects, "
    "text, letters, watermark, blurry, cropped, partial object, logo, extra legs, extra tail, "
    "extra head, duplicate limbs, duplicate body parts, mutation, deformed anatomy, two heads, "
    "three legs, forked tail"
)
NEG_OBJ_EXTRA = ", face, eyes, smile, cartoon face"
NEG_ANIM = NEG_BASE

# Anatomy tail per kind
ANATOMY = {
    "cat":    "Anatomy (MANDATORY): exactly one head with exactly two ears, exactly two eyes, exactly one mouth, exactly one nose. EXACTLY FOUR LEGS (two front, two back) - never more, never fewer. EXACTLY ONE TAIL - a single tail only, no forked tail. No extra limbs, no duplicate body parts, no mutation. The head, legs and tail must all attach to the single body.",
    "bird":   "Anatomy (MANDATORY): exactly one head with a single beak, exactly two eyes. EXACTLY TWO LEGS and EXACTLY TWO WINGS - never more. EXACTLY ONE TAIL - a single tail of feathers only. No extra limbs, no duplicate wings, no mutation.",
    "insect": "Anatomy (MANDATORY): exactly one head with exactly TWO ANTENNAE and exactly two eyes. EXACTLY SIX LEGS and EXACTLY TWO WINGS - never more, no extra legs. No extra limbs, no duplicate wings, no mutation.",
    "crab":   "Anatomy (MANDATORY): exactly one body with exactly TWO CLAWS and EXACTLY EIGHT LEGS - never more. No extra legs, no extra claws, no mutation.",
    "jelly":  "Anatomy (MANDATORY): exactly one round dome body with soft tentacles flowing below, exactly two eyes, a gentle smile. No legs, no fins, no extra tentacles beyond the lower skirt, no mutation.",
    "whale":  "Anatomy (MANDATORY): exactly one rounded body with a single head and EXACTLY ONE TAIL FIN, exactly two eyes, a gentle smile. No legs, no flippers, no extra fins, no mutation.",
    "dolphin":"Anatomy (MANDATORY): exactly one streamlined body with a single head and EXACTLY ONE TAIL FIN and EXACTLY TWO side flippers, exactly two eyes, a gentle smile. No legs, no extra fins, no mutation.",
    "octo":   "Anatomy (MANDATORY): exactly one rounded head with exactly two eyes, and EXACTLY EIGHT TENTACLES - never more. No legs, no extra tentacles, no mutation.",
    "obj":    "",
    "cover":  "",
}

OBJECT_TPL = """Isolated children's book vector clipart, single object only, solid flat light blue background, centered composition.

{CapDESC} for a children's picture book. Simple clean outlines, smooth flat color fills, gentle natural color palette, charming storybook style, educational illustration. Stylized and child-friendly, with simplified shapes suitable for preschool educational materials. Slightly whimsical and magical, matching the visual style of a fairy-tale children's book. Balanced proportions and consistent level of detail.

Only the {PlainDESC}. Only ONE object. No extra objects, no grass, no flowers, no trees, no ground, no landscape, no scenery, no text, no letters.

Clean flat vector illustration. SVG style. No texture. No noise. No gradients. No realism. No 3D. No shadows. High-quality children's educational clipart."""

ANIM_TPL = """Isolated children's book vector clipart, single character only, solid flat light blue background, centered composition.

{CapDESC}, for a children's picture book. Friendly fairy-tale character with soft rounded shapes, simple clean outlines, smooth flat color fills, gentle natural color palette, charming storybook style, educational illustration.

The character should have {DESC}, kind expressive eyes, and a cheerful friendly expression. {ANATOMY} Stylized and child-friendly, with simplified shapes suitable for preschool educational materials. Slightly whimsical and magical, matching the visual style of a fairy-tale children's book. Balanced proportions and consistent level of detail.

Only the {PlainDESC}. Only ONE character. No extra characters, no extra limbs, no extra tails, no extra heads, no duplicate body parts. No grass, no flowers, no trees, no ground, no landscape, no scenery, no extra objects, no text, no letters.

Clean flat vector illustration. SVG style. No texture. No noise. No gradients. No realistic fur. No photorealism. No 3D. No shadows. High-quality children's educational clipart."""

# Cover is a full illustrated title scene - separate prompt
COVER_TPL = """Original children's book cover illustration, horizontal composition, warm cheerful scene.

A pirate ship 'Murr-Veter' sailing on a friendly blue sea under a bright sun and puffy white clouds. On deck: three cute cartoon pirate kittens - Captain Barsik with his captain hat, Sailor Murzik, and young Puhok - plus a cheerful green parrot. Treasure chest, gold coins, flags and palm trees on a nearby island. Soft rounded shapes, simple clean outlines, smooth flat color fills, gentle natural color palette, charming storybook style, educational children's book art.

Friendly and magical, stylized and child-friendly, no scary elements. No text, no letters, no title words."""

COVER_NEG = (
    "photorealistic, 3d render, photo, complex background, text, letters, watermark, "
    "blurry, cropped, logo, extra limbs, extra legs, deformed anatomy, horror, dark, scary, "
    "blood, skeleton, gun, weapon, multiple heads, mutation, noise, gradients"
)


def build_cover_entry():
    return {
        "screen": "cover",
        "slug": "cover",
        "ru": "Обложка / главное меню",
        "kind": "cover",
        "seed": 102901,
        "prompt": COVER_TPL.strip(),
        "negative": COVER_NEG,
        "out": os.path.join(OUT, "cover", "cover.png"),
        "out_json": os.path.join(OUT, "cover", "cover.json"),
    }


def cap_first(s):
    return s[0].upper() + s[1:] if s else s


def strip_article(s):
    if s.startswith("a ") or s.startswith("an "):
        return s.split(" ", 1)[1]
    return s


def build_manifest():
    manifest = []
    slug_idx = 0
    for screen, items in ITEMS.items():
        base = SEED_BASE.get(screen, 100000 + slug_idx * 100)
        for i, (slug, kind, ru, desc) in enumerate(items):
            tokens = {
                "DESC": desc,
                "CapDESC": cap_first(desc),
                "PlainDESC": strip_article(desc),
            }
            if kind == "obj":
                prompt = OBJECT_TPL
                negative = NEG_BASE + NEG_OBJ_EXTRA
            else:
                prompt = ANIM_TPL.replace("{ANATOMY}", ANATOMY[kind])
                negative = NEG_ANIM
            for k, v in tokens.items():
                prompt = prompt.replace("{" + k + "}", v)
            manifest.append({
                "screen": screen,
                "slug": slug,
                "ru": ru,
                "kind": kind,
                "seed": base + i,
                "prompt": prompt.strip(),
                "negative": negative,
                "out": os.path.join(OUT, screen, slug + ".png"),
                "out_json": os.path.join(OUT, screen, slug + ".json"),
            })
    return manifest


if __name__ == "__main__":
    m = build_manifest()
    m.append(build_cover_entry())
    for it in m:
        print(f"{it['screen']}/{it['slug']:12s} kind={it['kind']:6s} seed={it['seed']}  -> {it['out']}")
    print(f"\nTOTAL: {len(m)} images")
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(m, f, ensure_ascii=False, indent=1)
    print("Manifest written to", os.path.join(OUT, "manifest.json"))
