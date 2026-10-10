"""Compact, labelled native render comparisons; no synthetic image content."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[2]
source=ROOT/'art_src/p1b/iteration_3/game'
for asset in ['tree','house','person']:
    sheet=Image.new('RGB',(432,512),'#e0dbd1');draw=ImageDraw.Draw(sheet)
    for row,state in enumerate(['before','after']):
        y=row*256
        draw.text((6,y+1),f'{asset.upper()} - {state.upper()} / same camera',fill='#34353a')
        image=Image.open(source/f'{asset}_{state}.png').convert('RGB')
        image.thumbnail((432,240),Image.Resampling.LANCZOS)
        sheet.paste(image,((432-image.width)//2,y+16))
    sheet.save(ROOT/f'art_src/p1b/{asset}_before_after.png')
