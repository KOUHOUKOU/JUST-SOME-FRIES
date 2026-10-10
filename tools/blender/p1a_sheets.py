"""Compose existing P1a captures only. No render, no engine invocation."""
from pathlib import Path
import json
import hashlib
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'art_src/p1a'
FINAL = BASE / 'iteration_4'
BG = '#eee7dd'

def tile(path, size):
    im = Image.open(path).convert('RGBA')
    im.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new('RGB', size, BG)
    canvas.paste(im, ((size[0]-im.width)//2, (size[1]-im.height)//2), im)
    return canvas

def sheet(items, dest, size=(256,144), cols=2):
    rows = (len(items)+cols-1)//cols
    canvas = Image.new('RGB',(size[0]*cols,(size[1]+18)*rows),BG)
    assert max(canvas.size) <= 512
    draw = ImageDraw.Draw(canvas)
    for i,(path,label) in enumerate(items):
        x,y=(i%cols)*size[0],(i//cols)*(size[1]+18)
        canvas.paste(tile(path,size),(x,y+18))
        draw.text((x+5,y+3),label,fill='#3a3d48')
    dest.parent.mkdir(parents=True,exist_ok=True)
    canvas.save(dest)

sheet([(FINAL/f'{v}_noon_3m_{style}.png',f'{v} / {style}')
       for v in ('chase','flare','perch') for style in ('before','after')], BASE/'before_after.png')
sheet([(FINAL/f'palette_{m}.png',m) for m in ('noon','golden','dusk')],BASE/'palette.png',size=(384,144),cols=1)
for m in ('noon','golden','dusk'):
    sheet([(FINAL/f'{v}_{m}_3m_after.png',f'{v} / {m}')
           for v in ('side','chase','flare','perch','snatch','portrait')],BASE/f'views_{m}.png')
sheet([(FINAL/f'flare_{m}_{d}m_after.png',f'{m} / {d} m')
       for m in ('noon','golden','dusk') for d in (3,15,60)],BASE/'distances.png',size=(170,96),cols=3)
sheet([(FINAL/'blender'/f'pose_{p}.png',p) for p in ('up','level','flare','perched')],BASE/'pose_sheet.png',size=(256,224))
silhouette = Image.new('RGB',(512,146),BG)
draw=ImageDraw.Draw(silhouette)
for i,p in enumerate(('up','level','flare','perched')):
    im=Image.open(FINAL/'blender'/f'pose_{p}.png').convert('RGBA').resize((128,128),Image.Resampling.LANCZOS)
    black=Image.new('RGB',(128,128),'#3a3d48')
    silhouette.paste(black,(128*i,18),im.getchannel('A'))
    draw.text((128*i+5,3),p,fill='#3a3d48')
silhouette.save(BASE/'silhouette_128.png')
if (FINAL/'vn_noon_fixed.png').exists():
    sheet([(FINAL/f'vn_{m}{"_fixed" if m=="noon" else ""}.png',f'VN / {m}')
           for m in ('noon','golden','dusk')],BASE/'portraits.png',size=(170,170),cols=3)
if (FINAL/'cam_b1a_matched_spawn.png').exists():
    sheet([(ROOT/'shots/cam_b1a.png','historical shots/cam_b1a'),
           (FINAL/'cam_b1a_matched_spawn.png','authored / same camera+spawn')],BASE/'historical_comparison.png',size=(512,220),cols=1)

# All output PNGs are reviewed by opening them; write inventory only after that step.
print('Composed P1a review sheets from existing PNGs.')
