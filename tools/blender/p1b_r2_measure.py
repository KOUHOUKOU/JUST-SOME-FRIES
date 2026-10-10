"""Geometry-masked colour measurements of existing captures; no rendering/retouching."""
from pathlib import Path
import json,sys,colorsys
import numpy as np
from PIL import Image,ImageFilter,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
folder=ROOT/f'art_src/p1b_review2/iteration_{int(sys.argv[1])}/game'
def rgb(path):return np.asarray(Image.open(path).convert('RGB'),dtype=float)/255
def erode(mask):return np.asarray(Image.fromarray((mask*255).astype('uint8')).filter(ImageFilter.MinFilter(3)))>250
def saturation(a):return (a.max(axis=-1)-a.min(axis=-1))/np.maximum(a.max(axis=-1),1e-6)
result={'method':'960x540 same frozen camera, sky and instance poses. All visible crown and same-material hedge foliage, identified by geometry/UV or original batch material (not beauty RGB); 1px eroded white mask. HSV mean pixel S. Full-frame display-sRGB Rec709 luma std-dev (0..1). No pixel retouching. Palms and grass excluded.', 'street':{}}
for mood in ['noon','golden']:
 for distance in [15,60]:
  pair={}
  for state in ['before','after']:
   a=rgb(folder/f'street_{mood}_{distance}m_{state}.png')
   mask=erode(np.min(rgb(folder/f'mask_{distance}m_{state}.png'),axis=-1)>.98)
   assert mask.sum()>10000,(distance,state,mask.sum())
   luma=a@np.array([.2126,.7152,.0722])
   pair[state]={'foliage_pixels':int(mask.sum()),'mean_saturation':float(saturation(a[mask]).mean()),'luma_std':float(luma.std()),'foliage_mean_RGB_255':(a[mask].mean(axis=0)*255).tolist()}
  pair['S_ratio']=pair['after']['mean_saturation']/pair['before']['mean_saturation']
  pair['contrast_ratio']=pair['after']['luma_std']/pair['before']['luma_std']
  pair['pass']=pair['S_ratio']>=.9 and pair['contrast_ratio']>=.95
  result['street'][f'{mood}_{distance}m']=pair
result['gull']={}
for name in ['noon_3m','golden_15m']:
 a=rgb(folder/f'colour_{name}.png');m=rgb(folder/f'colour_{name}_mask.png')
 mask=erode((m[:,:,0]>.96)&(m[:,:,1]<.12)&(m[:,:,2]>.96));pix=a[mask];mean=pix.mean(axis=0)
 result['gull'][name]={'pixels':int(mask.sum()),'mean_RGB_255':(mean*255).tolist(),'S_of_mean_pct':float(saturation(mean)*100),'mean_pixel_S_pct':float(saturation(pix).mean()*100)}
(folder/'colour_measurements.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
if '--sheets' in sys.argv:
 for label,pair in result['street'].items():
  sheet=Image.new('RGB',(960,324),'#eee7dd');d=ImageDraw.Draw(sheet)
  for i,state in enumerate(['before','after']):
   d.text((i*480+8,7),label+' / '+('old procedural' if i==0 else 'revised authored'),fill='#3a3d48')
   im=Image.open(folder/f'street_{label}_{state}.png').convert('RGB');im.thumbnail((480,270),Image.Resampling.LANCZOS);sheet.paste(im,(480*i,27))
  d.text((8,306),f"Foliage S ratio {pair['S_ratio']:.3f} (>=.90) | Luma contrast ratio {pair['contrast_ratio']:.3f} (>=.95)",fill='#3a3d48')
  sheet.save(folder.parent/f'before_after_{label}.png')
