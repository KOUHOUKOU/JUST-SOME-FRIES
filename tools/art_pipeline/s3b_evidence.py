"""Raw real-game evidence, fixed crop metrics, and non-retouched comparison sheets."""
from pathlib import Path
import hashlib,json,re,sys
import numpy as np
from PIL import Image,ImageDraw,ImageOps
R=Path(__file__).resolve().parents[2];S=R/'art_src/s3b';label=sys.argv[1]
B=S/'baseline';A=S/label;O=S/(label+'_review');O.mkdir(exist_ok=True)
C=Image.open(R/'art_src/reference/cover.jpg').convert('RGB')
CROPS={'roof':(180,450,1672,941),'pier':(1010,435,1672,941),'town':(0,0,825,560),'flight':(955,295,1672,941),'cafe':(660,510,1125,800),'beach':(850,400,1250,690),'headland':(1300,302,1600,490),'gull':(190,355,590,694)}
# Fixed screen rectangles below the sky; no recolour, selection-by-result or remasking.
# Mixed sun/shadow surfaces, NOT ground-truth illumination labels.
REGIONS={
 'town':('town_golden',(115,215,930,470),(95,140,655,408)),
 'cafe':('cafe_15m_golden',(100,100,880,455),(660,510,1125,800)),
 'wood':('roof_golden',(335,340,715,425),(1200,684,1630,735)),
 'water':('pier_golden',(15,405,550,520),(1400,458,1660,530)),
 'headland':('headland_golden',(220,280,660,505),(1310,399,1583,472)),
 'paving':('cafe_15m_golden',(102,142,365,249),(1080,550,1260,655)),
}
def img(p):return Image.open(p).convert('RGB')
def fit(im,w,h):return ImageOps.contain(im,(w,h),Image.Resampling.LANCZOS)
def sheet(names,file):
    out=Image.new('RGB',(960,len(names)*204),'#20202a');d=ImageDraw.Draw(out)
    for row,name in enumerate(names):
        group=name.split('_')[0]
        for col,(im,txt) in enumerate([(img(B/(name+'.png')),'S3 BEFORE'),(img(A/(name+'.png')),'S3b '+label),(C.crop(CROPS[group]),'COVER CROP')]):
            x=col*320;y=row*204;d.text((x+5,y+4),name+' / '+txt,fill='white');im=fit(im,320,180)
            out.paste(im,(x+(320-im.width)//2,y+24+(180-im.height)//2))
    out.save(O/file)
if label!='baseline':
    for g in ['roof','pier','town','flight']:sheet([g+'_golden',g+'_dusk'],g+'_before_after_cover.png')
    sheet(['cafe_3m_golden','cafe_15m_golden','cafe_60m_golden'],'cafe_before_after_cover.png')
    sheet(['beach_golden','headland_golden'],'ground_before_after_cover.png')
    sheet(['roof_golden','pier_golden','cafe_15m_golden','headland_golden'],'summary_before_after_cover.png')
    sheet(['gull_noon','gull_golden','gull_dusk'],'gull_before_after_cover.png')
paths=sorted(A.glob('*.png'))
for page in range((len(paths)+3)//4):
    out=Image.new('RGB',(960,588),'#20202a');d=ImageDraw.Draw(out)
    for k,p in enumerate(paths[page*4:page*4+4]):
        x=k%2*480;y=k//2*294;d.text((x+5,y+3),p.stem,fill='white');out.paste(fit(img(p),480,270),(x,y+24))
    out.save(O/f'capture_page{page}.jpg')
def stats(im):
    ar=np.asarray(im,dtype=float)/255;mx=ar.max(2);mn=ar.min(2);sat=(mx-mn)/np.maximum(mx,1e-8)
    lum=ar@np.array([.2126,.7152,.0722])
    return {'saturation_mean':float(sat.mean()),'luma_std':float(lum.std()),'luma_mean':float(lum.mean())}
measure={};out=Image.new('RGB',(960,204*len(REGIONS)),'#20202a');d=ImageDraw.Draw(out)
for row,(key,(name,gb,cb)) in enumerate(REGIONS.items()):
    ims=[img(B/(name+'.png')).crop(gb),img(A/(name+'.png')).crop(gb),C.crop(cb)]
    data={tag:stats(im) for tag,im in zip(['before','after','cover'],ims)}
    data['game_roi']=gb;data['cover_roi']=cb
    data['relative_error_after']={m:data['after'][m]/data['cover'][m]-1 for m in ['saturation_mean','luma_std']}
    measure[key]=data
    for col,(im,tag) in enumerate(zip(ims,['before','after','cover'])):
        x=col*320;y=row*204;v=data[tag];d.text((x+5,y+4),f'{key} {tag} S={v["saturation_mean"]:.3f} sdY={v["luma_std"]:.3f}',fill='white')
        im=fit(im,320,180);out.paste(im,(x+(320-im.width)//2,y+24+(180-im.height)//2))
out.save(O/'material_crops.png')
(O/'colour_measurements.json').write_text(json.dumps({'method':'HSV S mean, display Rec709 luma standard deviation (0..1), fixed rectangles, no masks; mixed sun/shadow; not matched 3D lighting labels','regions':measure},indent=2))
if label!='baseline':
    b=json.loads((B/'metrics.json').read_text());a=json.loads((A/'metrics.json').read_text());s3=json.loads((S/'s3_reference/metrics.json').read_text());pairs=[]
    for x,y,z in zip(b['samples'],a['samples'],s3['samples']):
        assert [x[k] for k in ['view','time','governor','camera']]==[y[k] for k in ['view','time','governor','camera']]
        pairs.append({'view':y['view'],'time':y['time'],'governor':y['governor'],'before':x,'after':y,'s3':z,'draw_pass':y['draw_calls']<=min(x['draw_calls'],z['draw_calls']),'tri_pass':y['triangles']<=min(x['triangles'],z['triangles'])})
    def build(n):return int(re.search(r'island was built in (\d+) ms',(S/(n+'_Cams.log')).read_text(encoding='utf-8-sig'))[1])
    hashes=json.loads((B/'source_hashes.json').read_text());changed=[f for f,v in hashes.items() if hashlib.sha256((R/f).read_bytes()).hexdigest()!=v]
    audit={'pairs':pairs,'build_ms':{'s3':build('s3_reference'),'before':build('baseline'),'after':build(label)},'colliders':[b['colliders'],a['colliders']],'physics_identical':b['physics_shapes_sha256']==a['physics_shapes_sha256'],'anchors_identical':b['anchors']==a['anchors'],'changed_files':changed,'draws_pass':all(p['draw_pass'] for p in pairs),'tris_pass':all(p['tri_pass'] for p in pairs)}
    (O/'audit.json').write_text(json.dumps(audit,indent=2))
    print(json.dumps({k:v for k,v in audit.items() if k not in ['pairs','changed_files']},indent=2))
print(json.dumps({k:{m:round(v[m],3) for m in v} for k,v in ((k,v['relative_error_after']) for k,v in measure.items())},indent=2))
