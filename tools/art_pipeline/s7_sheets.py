from pathlib import Path
from PIL import Image,ImageDraw
import sys,json
R=Path(__file__).resolve().parents[2];S=R/'art_src/s7';label=sys.argv[1]
files=sorted((S/label/'game').glob('*.png'));out=S/'review';out.mkdir(exist_ok=True)
sheet=Image.new('RGB',(960,290*((len(files)+1)//2)),(25,27,32));d=ImageDraw.Draw(sheet)
for i,p in enumerate(files):
 x=(i%2)*480;y=(i//2)*290;d.text((x+6,y+4),p.stem,fill='white');sheet.paste(Image.open(p).convert('RGB').resize((480,270)),(x,y+20))
sheet.save(out/(label+'_contact.jpg'),quality=93)
cover=Image.open(R/'art_src/reference/cover.jpg').crop((1256,296,1630,489)).convert('RGB')
if label!='baseline':
 sheet=Image.new('RGB',(1440,858),(25,27,32));d=ImageDraw.Draw(sheet)
 for j,name in enumerate(['headland_east','headland_sea','headland_west']):
  for i,lab in enumerate(['baseline',label,'cover']):
   d.text((i*480+5,j*286+4),name+' / '+lab,fill='white')
   im=cover if lab=='cover' else Image.open(S/lab/'game'/(name+'_golden.png')).convert('RGB')
   im.thumbnail((480,266));sheet.paste(im,(i*480+(480-im.width)//2,j*286+20+(266-im.height)//2))
 sheet.save(out/(label+'_before_after_cover.jpg'),quality=94)
print(len(files),'screenshots included')
