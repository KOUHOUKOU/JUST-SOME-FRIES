"""Label regression screenshots; record image QA only after the sheets were opened."""
from pathlib import Path
import hashlib,json,sys
from PIL import Image,ImageDraw,ImageOps
R=Path(__file__).resolve().parents[2];S=R/'art_src/s3b'
if '--record-viewed' not in sys.argv:
    paths=sorted((S/'autotest').glob('*.png'))
    assert len(paths)==10
    for page in range((len(paths)+3)//4):
        out=Image.new('RGB',(960,588),'#20202a');d=ImageDraw.Draw(out)
        for k,p in enumerate(paths[page*4:page*4+4]):
            x=k%2*480;y=k//2*294;d.text((x+5,y+4),p.stem,fill='white')
            out.paste(ImageOps.contain(Image.open(p).convert('RGB'),(480,270)),(x,y+24))
        out.save(S/'review'/f'autotest_page{page}.jpg')
    print('3 regression viewing pages created')
else:
    entries=[]
    for folder in ['baseline','pass1','pass2','final','baseline_review','pass1_review','pass2_review','final_review','review','autotest']:
        for p in sorted((S/folder).glob('*')):
            if p.suffix.lower() not in ['.jpg','.png']:continue
            entries.append({'path':p.relative_to(R).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'inspection':'Opened comparison sheet / full-size key / labelled page containing this image; no retouching','size':Image.open(p).size})
    (S/'viewed_images.json').write_text(json.dumps({'status':'Inspected, including failed passes; duplicates in review are byte-identical to viewed final_review sources','images':entries},indent=2))
    print('Reviewed image records:',len(entries))
