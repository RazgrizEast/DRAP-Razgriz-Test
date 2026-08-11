"""Copy a working tree into the game install for testing.

Both halves are required. source/autorun becomes reframework/autorun, and
source/data becomes reframework/data -- SharedData reads drdr_shared.json from
there at runtime. Copying only the autorun half leaves the mod running against
stale data, which looks exactly like a code bug: a table reads empty and every
lookup silently misses. That cost a debugging session once already.

Usage:
    py -3.12 deploy_dev.py [game_dir]

Defaults to the Steam install; override with DRAP_GAME_DIR or the argument.
"""
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
SRC_AUTORUN = os.path.join(REPO, "source", "autorun")
SRC_DATA = os.path.join(REPO, "source", "data")

DEFAULT_GAME = (
    r"C:\Program Files (x86)\Steam\steamapps\common\DEAD RISING DELUXE REMASTER"
)

# Contributor notes rather than runtime assets; build_release skips these too.
SKIP_DATA = {".md", ".txt"}


def copy_tree(src: str, dst: str) -> int:
    n = 0
    for root, dirs, files in os.walk(src):
        dirs[:] = [d for d in dirs if d != "__pycache__"]
        for name in files:
            full = os.path.join(root, name)
            rel = os.path.relpath(full, src)
            out = os.path.join(dst, rel)
            os.makedirs(os.path.dirname(out), exist_ok=True)
            shutil.copyfile(full, out)
            n += 1
    return n


def main() -> int:
    game = (sys.argv[1] if len(sys.argv) > 1
            else os.environ.get("DRAP_GAME_DIR", DEFAULT_GAME))
    fw = os.path.join(game, "reframework")
    if not os.path.isdir(fw):
        print(f"no reframework directory under {game}")
        return 1

    n_lua = copy_tree(SRC_AUTORUN, os.path.join(fw, "autorun"))

    n_data = 0
    data_out = os.path.join(fw, "data")
    os.makedirs(data_out, exist_ok=True)
    for name in os.listdir(SRC_DATA):
        full = os.path.join(SRC_DATA, name)
        if not os.path.isfile(full):
            continue
        if os.path.splitext(name)[1].lower() in SKIP_DATA:
            continue
        shutil.copyfile(full, os.path.join(data_out, name))
        n_data += 1

    print(f"  {n_lua} script(s) -> reframework/autorun")
    print(f"  {n_data} data file(s) -> reframework/data")
    print(f"  deployed to {game}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
