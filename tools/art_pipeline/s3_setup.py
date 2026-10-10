"""Freeze S2 provenance before S3 visual edits; in-project only."""
from pathlib import Path
import hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[2]
out=ROOT/'art_src/s3/baseline/source'
assert not out.exists(), 'Do not overwrite S2 baseline'
files=list((ROOT/'game/scripts').rglob('*.gd'))+list((ROOT/'game/shaders').glob('*'))+[ROOT/'game/project.godot']
hashes={}
for p in files:
    if not p.is_file(): continue
    rel=p.relative_to(ROOT)
    dest=out/rel; dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
    hashes[str(rel).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest()
(out.parent/'source_hashes.json').write_text(json.dumps(hashes,indent=2))
