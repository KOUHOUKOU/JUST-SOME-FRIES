"""Unretouched fixed-camera contact and cover comparison sheets."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
import sys,json
root=Path(__file__).resolve().parents[2];phase=root/'art_src/s6';label=sys.argv[1] if len(sys.argv)>1 else 'baseline'
out=phase/'review';out.mkdir(exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
files=sorted((phase/label/'game').glob('*.png'))
for page in range((len(files)+5)//6):
    sheet=Image.new('RGB',(1440,588),'#23232b');d=ImageDraw.Draw(sheet)
    for i,p in enumerate(files[page*6:page*6+6]):
        x=(i%3)*480;y=(i//3)*294
        sheet.paste(Image.open(p).convert('RGB').resize((480,270)),(x,y+24));d.text((x+5,y+3),p.stem+' / '+label,font=font,fill='white')
    sheet.save(out/f'{label}_page_{page+1}.jpg',quality=94)
print(label,len(files),'captures; pages ready')
ranking=[
 ('15_headland','1. Headland: giant brown cone, broad plain facets','headland'),
 ('13_windmill','2. Farm: rectangular crop bars, blank barn / mill','town'),
 ('06_marina','3. Marina: office appears unsupported over sea','pier'),
 ('09_town_stairs','4. Town banks: continuous grey strips / repeated rocks','town'),
 ('07_harbor_cranes','5. Harbor: blank warehouse, bare yard, block containers','pier'),
 ('08_church','6. Church / summit: grey roofs, bare tower and plinth','town'),
 ('16_far_islands','7. Horizon: identical domes, lighthouse on grey lump','headland'),
 ('05_playground','8. Playground: box hut, flat blue slide, empty sand','pier'),
 ('01_opening_roof','9. Opening: large plain roof, flat distant illumination','cafe'),
 ('17_sea_low','10. Sea: streaky bands, weak scene reflections','water')]
cover=Image.open(root/'art_src/reference/cover.jpg').convert('RGB')
crops={'headland':(1240,255,1672,490),'town':(130,30,610,300),'pier':(1060,435,1600,740),'cafe':(640,535,1130,820),'water':(1350,660,1650,920)}
if label=='baseline':
    (phase/'ranking.json').write_text(json.dumps(ranking,indent=2))
    for pg in range(2):
        sheet=Image.new('RGB',(1280,5*384),'#23232b');d=ImageDraw.Draw(sheet)
        for i,(stem,title,roi) in enumerate(ranking[pg*5:pg*5+5]):
            y=i*384;d.text((8,y+3),title+' | COVER reference',fill='white',font=font)
            sheet.paste(Image.open(phase/'baseline/game'/f'{stem}_golden.png').resize((640,360)),(0,y+24))
            sheet.paste(ImageOps.contain(cover.crop(crops[roi]),(640,360)),(640,y+24))
        sheet.save(out/f'ranking_{pg+1}.jpg',quality=94)
else:
    for pg in range(4):
        sheet=Image.new('RGB',(1440,6*294),'#23232b');d=ImageDraw.Draw(sheet)
        for i,p in enumerate(files[pg*6:pg*6+6]):
            name=p.stem;y=i*294
            roi=next((r[2] for r in ranking if name.startswith(r[0])),'town')
            if name.startswith(('02_','20_','21_')):roi='cafe'
            if name.startswith(('03_','04_','19_','22_')):roi='pier'
            for j,(im,caption) in enumerate([(Image.open(phase/'baseline/game'/p.name),'BEFORE'),(Image.open(p),'AFTER '+label),(cover if name=='23_title' else cover.crop(crops[roi]),'COVER crop')]):
                d.text((j*480+4,y+3),name+' / '+caption,font=font,fill='white')
                im=ImageOps.contain(im.convert('RGB'),(480,270));sheet.paste(im,(j*480,y+24))
        sheet.save(out/f'{label}_comparison_{pg+1}.jpg',quality=94)
