"""Final same-camera before/after/cover panels and measured image evidence."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageChops
import json,hashlib
import numpy as np
root=Path('art_src/s2');out=root/'review';out.mkdir(exist_ok=True)
cover=Image.open('art_src/reference/cover.jpg').convert('RGB')
crops={'roof':(0,270,1672,941),'pier':(755,370,1672,941),'town':(0,0,790,545),'flight':(600,280,1672,941)}
measure=[]
for view in crops:
    sheet=Image.new('RGB',(960,832),(27,28,38));draw=ImageDraw.Draw(sheet)
    for row,tm in enumerate(['morning','afternoon','golden','dusk']):
        for col,(label,img) in enumerate([
            ('BEFORE / '+tm,Image.open(root/'baseline'/f'{view}_{tm}.png')),
            ('S2 AFTER / '+tm,Image.open(root/'iteration_4'/f'{view}_{tm}.png')),
            ('COVER TARGET / dusk mood',cover.crop(crops[view]))]):
            img.thumbnail((320,180));x=col*320;y=row*208;sheet.paste(img,(x+(320-img.width)//2,y+24+(180-img.height)//2));draw.text((x+7,y+6),label,fill='white')
        a=np.asarray(Image.open(root/'baseline'/f'{view}_{tm}.png').convert('RGB'))/255.
        b=np.asarray(Image.open(root/'iteration_4'/f'{view}_{tm}.png').convert('RGB'))/255.
        def stats(im):
            luma=im@np.array([.2126,.7152,.0722])
            return {'all_channels_ge_250_pct':float((im.min(2)>=250/255).mean()*100),'mean_luma':float(luma.mean()),'luma_std':float(luma.std())}
        measure.append({'view':view,'time':tm,'before':stats(a),'after':stats(b)})
    sheet.save(out/f'{view}_before_after_cover.png')
sheet=Image.new('RGB',(960,648),(27,28,38));draw=ImageDraw.Draw(sheet)
for row,view in enumerate(['roof','town','flight']):
    for col,(label,img) in enumerate([('BEFORE',Image.open(root/'baseline'/f'{view}_dusk.png')),('S2 AFTER',Image.open(root/'iteration_4'/f'{view}_dusk.png')),('COVER CROP',cover.crop(crops[view]))]):
        img.thumbnail((320,180));x=col*320;y=row*216;sheet.paste(img,(x+(320-img.width)//2,y+28+(180-img.height)//2));draw.text((x+6,y+7),f'{view} / {label}',fill='white')
sheet.save(out/'summary_before_after_cover.png')
# Gull paint: current keys vs the approved S1 close view and target crop (not a matched camera).
sheet=Image.new('RGB',(960,628),(27,28,38));draw=ImageDraw.Draw(sheet)
items=[('APPROVED S1 / different camera',Image.open('art_src/s1/round_2/game/dusk_after.png')),('COVER GULL',cover.crop((0,177,849,789)))]
items += [(tm,Image.open(root/'iteration_4'/f'gull_{tm}.png')) for tm in ['morning','afternoon','golden','dusk']]
for i,(label,img) in enumerate(items):
    img.thumbnail((320,278));x=i%3*320;y=i//3*314;sheet.paste(img,(x+(320-img.width)//2,y+28+(278-img.height)//2));draw.text((x+6,y+8),label,fill='white')
sheet.save(out/'gull_palette_cover.png')
bloom={}
for folder in ['baseline','iteration_4']:
    a=Image.open(root/folder/'native_glow_on.png').convert('RGB');b=Image.open(root/folder/'native_glow_off.png').convert('RGB')
    bloom[folder]={'pixel_difference_bbox':ImageChops.difference(a,b).getbbox(),'byte_identical':a.tobytes()==b.tobytes(),'mean_abs_rgb_255':float(np.abs(np.asarray(a).astype(float)-np.asarray(b).astype(float)).mean())}
(root/'image_measurements.json').write_text(json.dumps({'images':measure,'native_bloom_ab':bloom},indent=2),encoding='utf8')
print(json.dumps(bloom,indent=2))
