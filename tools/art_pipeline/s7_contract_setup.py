from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[2]
# Reference scripts use only their own baseline dependencies. Assets are unchanged
# except new S7 files; the original S6 headland and terrain resource are retained.
src=R/'art_src/s7/baseline/source/game/scripts';dst=R/'art_src/s7/contract_baseline/scripts'
for p in src.rglob('*.gd'):
 q=dst/p.relative_to(src);q.parent.mkdir(parents=True,exist_ok=True)
 q.write_text(p.read_text(encoding='utf8').replace('res://scripts/','res://../art_src/s7/contract_baseline/scripts/'),encoding='utf8')
