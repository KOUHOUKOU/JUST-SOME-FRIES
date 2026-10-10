from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
import json
root=Path(__file__).resolve().parents[2];out=root/'art_src/final'
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
cover=Image.open(root/'art_src/reference/cover.jpg').convert('RGB')
crops={'headland':(1240,255,1672,490),'town':(130,30,610,300),'pier':(1060,435,1600,740),'cafe':(640,535,1130,820),'water':(1350,660,1650,920),'gull':(0,175,820,815),'fries':(0,680,280,941),'person':(820,640,960,775)}
views=json.loads((out/'cameras.json').read_text())
names=[v[0] for v in views]+['vn_portrait']
roi=['cafe','cafe','cafe','pier','pier','pier','pier','town','town','headland','water','pier','gull','fries','person']
for page in range(4):
    batch=names[page*4:page*4+4]
    sheet=Image.new('RGB',(1920,50+len(batch)*390),'#21222b');d=ImageDraw.Draw(sheet)
    d.text((12,10),'ORIGINAL (pre-art code)  |  FINAL (S7 approved)  |  COVER reference crop - not gameplay',font=font,fill='white')
    for row,name in enumerate(batch):
        y=50+row*390;ix=names.index(name)
        for col,label in enumerate(['original','final','cover']):
            im=cover.crop(crops[roi[ix]]) if label=='cover' else Image.open(out/label/(name+'.png')).convert('RGB')
            im=ImageOps.contain(im,(640,360));sheet.paste(im,(col*640+(640-im.width)//2,y+28+(360-im.height)//2))
            d.text((col*640+8,y+2),name+' / '+label.upper(),font=font,fill='white')
    sheet.save(out/f'original_vs_final_{page+1:02}.jpg',quality=95)
print('4 sheets, 1920 px wide; all 30 source screenshots included.')
