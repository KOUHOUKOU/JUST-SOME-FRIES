"""Compose key comparisons and an index; never retouch source captures."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import json,hashlib
root=Path(__file__).resolve().parents[2];s=root/'art_src/s6';out=s/'review'
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
cover=Image.open(root/'art_src/reference/cover.jpg').convert('RGB')
crop={'rock':(1240,255,1672,490),'town':(130,30,610,300),'pier':(1060,435,1600,740)}
rows=[('15_headland','rock'),('13_windmill','town'),('09_town_stairs','town'),('07_harbor_cranes','pier')]
sheet=Image.new('RGB',(1440,294*4),'#23232b');d=ImageDraw.Draw(sheet)
for i,(name,roi) in enumerate(rows):
 for j,(label,im) in enumerate([('BEFORE',Image.open(s/'baseline/game'/f'{name}_golden.png')),('AFTER / FINAL',Image.open(s/'iteration_4/game'/f'{name}_golden.png')),('COVER',cover.crop(crop[roi]))]):
  d.text((j*480+5,i*294+3),name+' / '+label,font=font,fill='white');im=ImageOps.contain(im.convert('RGB'),(480,270));sheet.paste(im,(j*480,i*294+24))
sheet.save(out/'summary_before_after_cover.jpg',quality=95)
# Every intermediate comparison was also inspected; smaller pages retain the complete sheets.
for phase in [2,3]:
 sheet=Image.new('RGB',(1440,1764),'#23232b')
 for k in range(4):
  im=Image.open(out/f'iteration_{phase}_comparison_{k+1}.jpg');im=ImageOps.contain(im,(720,882));sheet.paste(im,((k%2)*720,(k//2)*882))
 sheet.save(out/f'intermediate_{phase}_comparisons.jpg',quality=90)
# Gallery of genuine autotest captures, if completed.
files=sorted((s/'autotest').glob('*.png'))
for pg in range((len(files)+5)//6):
 sheet=Image.new('RGB',(1440,588),'#23232b');d=ImageDraw.Draw(sheet)
 for i,p in enumerate(files[pg*6:pg*6+6]):
  x=(i%3)*480;y=(i//3)*294;im=ImageOps.contain(Image.open(p).convert('RGB'),(480,270));sheet.paste(im,(x,y+24));d.text((x+3,y+3),p.name,font=font,fill='white')
 sheet.save(out/f'autotest_{pg+1}.jpg',quality=94)
print('Summary, intermediate evidence galleries,',len(files),'autotest captures')
