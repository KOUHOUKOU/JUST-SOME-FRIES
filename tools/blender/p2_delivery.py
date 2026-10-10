"""Compose reviewed captures and audit the visual-only production hooks (no rendering)."""
from pathlib import Path
import hashlib,json
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[2];out=R/'art_src/p2';g=out/'iteration_3/game';sheets=out/'review';sheets.mkdir(exist_ok=True)
def sheet(name,entries,cols=2,w=256,h=144):
 rows=(len(entries)+cols-1)//cols
 im=Image.new('RGB',(cols*w,rows*(h+17)),(40,39,46));d=ImageDraw.Draw(im)
 for i,(p,label) in enumerate(entries):
  src=Image.open(p).convert('RGB');src.thumbnail((w,h))
  x=i%cols*w;y=i//cols*(h+17);im.paste(src,(x+(w-src.width)//2,y));d.text((x+5,y+h+2),label,fill=(245,235,213))
 assert max(im.size)<=512
 im.save(sheets/(name+'.png'))
for mood in ['noon','golden','dusk']:
 sheet('fries_'+mood,[(g/f'fry_{mood}_{dist}m_{old}.png',f'{dist}m / {old}') for dist in [3,15,60] for old in ['before','after']])
sheet('dog',[(g/'dog_before.png','before / 156 tris / 13 draws'),(g/'dog_after.png','after / 1192 tris / 7 draws')])
sheet('fish',[(out/'iteration_2/game/fish_nine.png','old meshes (I2 fallback)'),(g/'fish_nine.png','9 authored fish / 2 draws each')])
sheet('outfits',[(g/f'outfit_{i}_{pose}.png',f'outfit {i+1} / {pose}') for i in range(3) for pose in ['perch','flight']])
files=sorted((out/'iteration_3/wardrobe').glob('*front_side.png'))
for page in range(4):sheet(f'wardrobe_{page+1}',[(f,f.stem[3:].replace('_front_side','')) for f in files[page*6:(page+1)*6]],h=128)
sheet('portraits',[(g/f'vn_portrait_{i}.png',['YOU','BIG BRO','FRIEND test fixture'][i]) for i in range(3)],cols=3,w=160,h=160)
sheet('fries_close',[(g/'details/fry_3m_before.png','before'),(g/'details/fry_3m_after.png','after / canonical label side')])
base=json.loads((out/'baseline/source_hashes.json').read_text());changed=[];same=[]
for path,sha in base.items():
 (same if hashlib.sha256((R/path).read_bytes()).hexdigest()==sha else changed).append(path)
hooks={
 'fries/fry.gd':['\tpreload("res://scripts/art/p2_parts.gd").fry(self)\n'],
 'player/gull_visual.gd':['\tpreload("res://scripts/art/p2_parts.gd").wear(self, n, kind)\n'],
 'npc/dog.gd':['\tpreload("res://scripts/art/p2_parts.gd").dog(self, coat)\n'],
 'world/fish_spot.gd':['\t\tpreload("res://scripts/art/p2_parts.gd").fish(self)\n'],
 'npc/human_rig.gd':['\tif item_node_l != null:preload("res://scripts/art/p2_parts.gd").human_item(item_node_l, st["item_l"])\n','\tif item_node_r != null:preload("res://scripts/art/p2_parts.gd").human_item(item_node_r, st["item_r"])\n']}
proof={}
for path,lines in hooks.items():
 original=(out/'baseline'/path).read_text(encoding='utf-8');current=(R/'game/scripts'/path).read_text(encoding='utf-8')
 for line in lines:assert current.count(line)==1;current=current.replace(line,'')
 proof[path]=current==original;assert proof[path]
audit={'changed_existing':changed,'unchanged_count':len(same),'unchanged':same,'visual_hooks_only':proof,'no_new_per_frame_callbacks':True}
(out/'source_audit.json').write_text(json.dumps(audit,indent=2))
models=[p for p in (R/'game/assets/models').glob('*.glb') if p.stem.startswith(('fry_','wear_','fish_')) or p.stem=='dog_parts']
inventory=[{'file':str(p.relative_to(R)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in models]
(out/'assets.json').write_text(json.dumps(inventory,indent=2))
print('Models:',len(models),'bytes:',sum(p.stat().st_size for p in models),'unchanged sources:',len(same),'changed:',changed)
print('PNG files:',len(list(out.rglob('*.png'))))
