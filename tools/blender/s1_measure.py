"""Reference silhouette IoU: opaque white backgrounds, alpha model renders.
No anisotropic stretch, warp, contour fitting, or best-of-camera search.
Uniformly scale each foreground's longest bbox edge to 460px and centre its
bbox on 512px. Alpha > .5; reference max RGB deviation from white > 12, then
keep largest connected component and fill enclosed white facet holes.
"""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[2]
ap=argparse.ArgumentParser();ap.add_argument('iteration',type=int);args=ap.parse_args()
folder=ROOT/f'art_src/s1/iteration_{args.iteration}'
def refmask(path):
    a=np.asarray(Image.open(path).convert('RGB'));m=np.min(a,axis=2)<243
    lab,n=ndimage.label(m);sizes=np.bincount(lab.ravel());sizes[0]=0
    return ndimage.binary_fill_holes(lab==sizes.argmax())
def normalise(m):
    y,x=np.where(m);box=(int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1))
    im=Image.fromarray(m).crop(box);scale=460/max(im.size)
    im=im.resize(tuple(round(v*scale) for v in im.size),Image.Resampling.NEAREST)
    out=Image.new('1',(512,512));out.paste(im,((512-im.width)//2,(512-im.height)//2))
    return np.asarray(out),{'bbox':box,'uniform_scale':scale}
result={'method':__doc__,'views':{}}
sheet=Image.new('RGB',(960,540),'#eee8df');draw=ImageDraw.Draw(sheet)
for i,name in enumerate(['front','left','top']):
    r,ra=normalise(refmask(ROOT/f'art_src/hero_gull/gull_{name}.png'))
    im=Image.open(folder/f'blender/{name}.png').convert('RGBA');m,ma=normalise(np.asarray(im)[:,:,3]>127)
    inter=np.count_nonzero(r&m);union=np.count_nonzero(r|m);iou=inter/union
    result['views'][name]={'iou':iou,'intersection':inter,'union':union,'reference':ra,'model':ma,'pass_085':iou>=.85}
    rgb=np.full((512,512,3),246,dtype=np.uint8);rgb[r]=[222,90,104];rgb[m]=[53,155,192];rgb[r&m]=[49,56,65]
    panel=Image.fromarray(rgb).resize((320,320),Image.Resampling.NEAREST);sheet.paste(panel,(i*320,50))
    draw.text((i*320+12,15),f'{name} IoU {iou:.4f}',fill='black')
    ref=Image.open(ROOT/f'art_src/hero_gull/gull_{name}.png').convert('RGB');ref.thumbnail((155,155));sheet.paste(ref,(i*320,380))
    model=Image.new('RGBA',im.size,'#eee8df');model.alpha_composite(im);model=model.convert('RGB');model.thumbnail((155,155));sheet.paste(model,(i*320+160,380))
draw.text((12,355),'Red: reference only | Blue: model only | Charcoal: intersection',fill='black')
sheet.save(folder/'silhouette_comparison.png')
(folder/'silhouette_iou.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result['views'],indent=2))
