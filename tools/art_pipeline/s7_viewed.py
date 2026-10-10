"""Create unretouched autoplay contacts; record hashes after visual inspection."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib,sys
R=Path(__file__).resolve().parents[2];S=R/'art_src/s7'
if '--record' not in sys.argv:
 files=sorted((S/'autotest').glob('*.png'))
 for page in range((len(files)+5)//6):
  items=files[page*6:page*6+6];im=Image.new('RGB',(960,290*((len(items)+1)//2)),(25,27,32));d=ImageDraw.Draw(im)
  for j,p in enumerate(items):
   x=j%2*480;y=j//2*290;d.text((x+5,y+4),p.name,fill='white');im.paste(Image.open(p).convert('RGB').resize((480,270)),(x,y+20))
  im.save(S/'review'/f'autotest_{page+1}.jpg',quality=93)
 print(len(files),'autoplay screenshots in',page+1,'sheets')
else:
 files=[p for p in S.rglob('*') if p.suffix.lower() in ['.png','.jpg'] and 'runtime' not in p.parts]
 (S/'viewed_images.json').write_text(json.dumps({'method':'Every generated capture inspected through full contact sheets; three final headland sources and actual ending also inspected directly. Sheets are unretouched resized originals. This is builder inspection, not director approval.','files':{p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files}},indent=2))
 print('Recorded',len(files),'inspected source/sheet hashes')
