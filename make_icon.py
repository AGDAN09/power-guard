import sys 
from pathlib import Path
from PIL import Image

SIZE = 1024
OUT = Path("assets/icon/icon.png")

def main():
    if len(sys.argv) < 2:
        print("Cara pakai: python make_icon.py foto.jpg")
        return

    src = Path(sys.argv[1])
    if not src.exists():
        print(f"File {src} tidak ditemukan")
        return

    img = Image.open(src).convert("RGBA")

    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    img = img.crop((left, top, left + side, top + side))

    img = img.resize((SIZE, SIZE), Image.LANCZOS)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Icon berhasil dibuat: {OUT} ({SIZE}x{SIZE})")

if __name__ == "__main__":
    main()