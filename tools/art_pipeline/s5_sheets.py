"""Unretouched review pages and same-camera cover comparisons; Pillow is installed."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import sys,json,hashlib
root=Path('art_src/s5');label=sys.argv[1] if len(sys.argv)>1 else 'iteration_1'
out=root/label/'review';out.mkdir(parents=True,exist_ok=True)
def sheet(items,path,cols=3,rows=2):
    im=Image.new('RGB',(960,540),'#22232a');d=ImageDraw.Draw(im)
    w=960//cols;h=540//rows
    for i,(name,p) in enumerate(items):
        src=Image.open(p).convert('RGB');src.thumbnail((w,h-23),Image.Resampling.LANCZOS)
        x=(i%cols)*w;y=(i//cols)*h
        im.paste(src,(x+(w-src.width)//2,y+23+(h-23-src.height)//2));d.text((x+5,y+5),name,fill='white')
    im.save(path)
for phase in ['baseline',label]:
    files=sorted((root/phase/'game').glob('*.png'))
    for i in range(0,len(files),6):sheet([(p.stem,p) for p in files[i:i+6]],out/f'{phase}_all_{i//6}.png')
files=sorted((root/label/'blender/turntable').glob('*.png'))
if files:sheet([(p.stem,p) for p in files if p.stem!='contact'],out/'blender_all.png')
for name,ref in [('cafe_people_3m_golden','cafe_people'),('cafe_people_15m_golden','cafe_people'),('pier_crowd_15m_golden','pier_people'),('pier_crowd_60m_golden','pier_people'),('cast_golden','pier_people')]:
    if (root/label/'game'/f'{name}.png').exists():
        sheet([('PREVIOUS / '+name,root/'baseline/game'/f'{name}.png'),('S5 / '+name,root/label/'game'/f'{name}.png'),('COVER crop (enlarged)',root/'reference'/f'{ref}.png')],out/f'{name}_comparison.png',3,1)
print(out)

if label=='iteration_3':
    final=root/'review';final.mkdir(exist_ok=True)
    cover=Image.open('art_src/reference/cover.jpg')
    for name,box in [('cover_headland',(1263,295,1628,485)),('cover_gull',(0,170,835,795)),('cover_cafe',(688,586,1155,778))]:
        cover.crop(box).save(final/f'{name}.png')
    # Clearly labelled crops only; no colour grading or drawn-over game pixels.
    for phase in ['previous','new']:
        Image.open(root/label/'game'/f'cast_close_{phase}.png').crop((35,150,930,392)).save(final/f'cast_{phase}_crop.png')
    sheet([('Previous smooth people',final/'cast_previous_crop.png'),('S5 flat-faceted people',final/'cast_new_crop.png'),('COVER / cafe people',root/'reference/cafe_people.png'),('COVER / pier people',root/'reference/pier_people.png')],final/'people_cover.png',2,2)
    for view,ref in [('cafe_people_3m_golden','cover_cafe'),('cafe_people_15m_golden','cover_cafe'),('pier_crowd_15m_golden',None),('pier_crowd_60m_golden',None),('cafe_paving_golden','cover_cafe'),('headland_golden','cover_headland'),('gull_golden','cover_gull')]:
        p=final/f'{ref}.png' if ref else root/'reference/pier_people.png'
        sheet([('PREVIOUS / '+view,root/'baseline/game'/f'{view}.png'),('S5 / same camera',root/label/'game'/f'{view}.png'),('COVER crop',p)],final/f'{view}.png',3,1)
    sheet([(name,root/phase/'game'/f'portrait_{idx}.png') for idx in [4,3,6] for name,phase in [('previous','baseline'),('S5','iteration_3')]],final/'portraits.png',2,3)
    # Pier pixel crop, identical region for before/after; enlargement cannot add detail.
    for phase in ['baseline',label]:
        Image.open(root/phase/'game/pier_crowd_60m_golden.png').crop((140,255,400,331)).resize((780,228),Image.Resampling.NEAREST).save(final/f'pier_60m_{phase}_pixels.png')
    sheet([('PREVIOUS / 60m native pixels x3',final/'pier_60m_baseline_pixels.png'),('S5 / same pixels x3',final/'pier_60m_iteration_3_pixels.png')],final/'pier_60m_pixels.png',1,2)
