"""Freeze S6 source baseline and fixed audit cameras before any art changes."""
from pathlib import Path
import json, shutil, hashlib
root=Path(__file__).resolve().parents[2]
out=root/'art_src/s6'
out.mkdir(exist_ok=True)
if not (out/'baseline/hashes.json').exists():
    hashes={}
    for folder in ['game/scripts','game/shaders','game/assets/models','game/assets/art/kenney','tools/blender']:
        for p in (root/folder).rglob('*'):
            if p.is_file() and p.suffix not in ['.pyc','.uid','.import']:
                rel=p.relative_to(root);dest=out/'baseline/source'/rel
                dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
                hashes[rel.as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    (out/'baseline/hashes.json').write_text(json.dumps(hashes,indent=2))
views=[
 ['01_opening_roof',[-19,9,-6],[-1,5,44],64],
 ['02_cafe',[-1,7,20],[-9,1.5,3],58],
 ['03_boardwalk_market',[29,10,33],[12,2,13],62],
 ['04_beach',[67,16,53],[44,2,24],62],
 ['05_playground',[45,6,18],[34,1.5,8],60],
 ['06_marina',[-43,10,50],[-19,1,34],62],
 ['07_harbor_cranes',[129,27,30],[84,8,-10],63],
 ['08_church',[-49,25,-37],[-26,22,-61],60],
 ['09_town_stairs',[6,16,-20],[0,17,-62],61],
 ['10_houses_villas',[-62,15,-31],[-43,9,-44],62],
 ['11_gardens',[34,14,-28],[25,7,-40],60],
 ['12_farm',[115,37,-48],[85,23,-74],64],
 ['13_windmill',[74,30,-58],[86,28,-80],60],
 ['14_hill_summit',[17,28,-63],[0,20,-80],62],
 ['15_headland',[-58,40,86],[-100,17,38],62],
 ['16_far_islands',[10,15,170],[75,12,415],65],
 ['17_sea_low',[30,3,111],[24,4,165],70],
 ['18_sea_high',[58,66,105],[-4,9,-18],68],
 ['19_fast_rush',[8,12,66],[0,8,29],88],
 ['20_ending_floor',[-12.2,1.0,9],[-8.65,.35,3.65],54],
 ['21_opening_close',[-9.2,6.5,6.6],[-8.7,5.7,-1],40],
 ['22_pier',[35,16,82],[-3,7,40],62],
]
(out/'cams.json').write_text(json.dumps(views,indent=2))
print('S6 snapshot and 22 fixed cameras ready')
