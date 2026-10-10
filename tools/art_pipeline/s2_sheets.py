"""Lossless-source review layout; no paint/retouch. Every tile identifies its capture."""
from pathlib import Path
from PIL import Image, ImageDraw
import sys
folder=Path('art_src/s2')/sys.argv[1]
for tm in ['morning','afternoon','golden','dusk']:
    sheet=Image.new('RGB',(960,588),(25,26,35));draw=ImageDraw.Draw(sheet)
    for j,view in enumerate(['roof','pier','town','flight']):
        im=Image.open(folder/(view+'_'+tm+'.png'));im.thumbnail((480,270))
        x=j%2*480;y=j//2*294;sheet.paste(im,(x,y+24));draw.text((x+8,y+5),view+' / '+tm,fill='white')
    sheet.save(folder/('sheet_'+tm+'.png'))
extras=[p for p in folder.glob('*.png') if not p.stem.startswith(('roof_','pier_','town_','flight_','sheet_'))]
for start in range(0,len(extras),6):
    group=extras[start:start+6];sheet=Image.new('RGB',(960,294*((len(group)+1)//2)),(25,26,35));draw=ImageDraw.Draw(sheet)
    for j,p in enumerate(group):
        im=Image.open(p);im.thumbnail((480,270));x=j%2*480;y=j//2*294
        sheet.paste(im,(x,y+24));draw.text((x+8,y+5),p.stem,fill='white')
    sheet.save(folder/('sheet_checks_'+str(start//6)+'.png'))
