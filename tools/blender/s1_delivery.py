"""Compose small review figures from captured evidence; no new renders."""
from pathlib import Path
import json, hashlib
from PIL import Image,ImageDraw,ImageOps
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art_src/s1/review';OUT.mkdir(exist_ok=True)
F=ROOT/'art_src/s1/iteration_4'
def tile(sheet,path,rect,alpha=True):
    im=Image.open(path).convert('RGBA');bg=Image.new('RGBA',im.size,'#e9e4df');bg.alpha_composite(im);im=bg.convert('RGB')
    im.thumbnail((rect[2],rect[3]),Image.Resampling.LANCZOS)
    sheet.paste(im,(rect[0]+(rect[2]-im.width)//2,rect[1]+(rect[3]-im.height)//2))
sheet=Image.new('RGB',(960,540),'#eee8df');d=ImageDraw.Draw(sheet)
for i,view in enumerate(['front','left','right','back','top']):
    d.text((i*192+8,12),view+' / model',fill='black')
    tile(sheet,F/f'blender/{view}.png',(i*192,35,192,220))
    d.text((i*192+8,280),view+' / reference',fill='black')
    tile(sheet,ROOT/f'art_src/hero_gull/gull_{view}.png',(i*192,303,192,220))
sheet.save(OUT/'five_views.png')
sheet=Image.new('RGB',(960,540),'#eee8df');d=ImageDraw.Draw(sheet)
cover=Image.open(ROOT/'art_src/reference/cover.jpg').crop((0,170,830,815));cover.thumbnail((310,320))
sheet.paste(cover,((320-cover.width)//2,45+(320-cover.height)//2))
d.text((12,14),'TARGET / cover gull crop',fill='black')
for i,name in enumerate(['before','after'],start=1):
    d.text((i*320+12,14),('REJECTED smooth gull' if name=='before' else 'S1 faceted gull / NOT APPROVED'),fill='black')
    tile(sheet,F/f'game/corrected/perch_dusk_{name}.png',(i*320,45,320,320))
d.text((12,393),'Same existing dusk light / matched before-after roof camera. Cover lighting is still stronger.',fill='black')
d.text((12,422),'IoU: front 0.8629 PASS | left 0.4552 FAIL | top 0.7221 FAIL (target >= 0.85 each)',fill='black')
d.text((12,452),'Open: wing hinge seams / folding plates, cropped VN head and hat, floating necklace.',fill='black')
d.text((12,482),'714 tris / 11 parts / 1 shared material. Four asset iterations; STOP S1.',fill='black')
sheet.save(OUT/'cover_before_after.png')
sheet=Image.new('RGB',(960,540),'#eee8df');d=ImageDraw.Draw(sheet)
for i,name in enumerate(['straw_glasses','topper_shades','sailor_scarf','beret_bowtie','vn_you','vn_big_bro']):
    x=i%3*320;y=i//3*270;d.text((x+8,y+5),name,fill='black');tile(sheet,F/f'game/{name}.png',(x,y+25,320,235))
sheet.save(OUT/'wardrobe_and_vn.png')
asset_paths=[ROOT/'game/assets/models/hero_gull_parts.glb']+sorted((ROOT/'game/assets/models').glob('wear_*.glb'))
assets=[{'file':str(p.relative_to(ROOT)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in asset_paths]
(ROOT/'art_src/s1/assets.json').write_text(json.dumps(assets,indent=2))
print('Created 3 review sheets; open all before adding the viewed inventory.')
