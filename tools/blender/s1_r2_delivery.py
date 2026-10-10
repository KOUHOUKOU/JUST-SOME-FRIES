"""Review 8 evidence: real alpha IoU, masked colour stats and bounded sheets."""
import sys,json,hashlib,struct,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
from scipy import ndimage
import s1_r2_pose as M
ROOT=M.ROOT;OUT=M.OUT;REV=OUT/'review';REV.mkdir(exist_ok=True)
def load(path):return Image.open(path).convert('RGB')
def panel(sheet,path,box,label='',crop=None,alpha=False):
 im=Image.open(path)
 if alpha:
  bb=im.getchannel('A').getbbox();im=im.crop((bb[0]-8,bb[1]-8,bb[2]+8,bb[3]+8))
  bg=Image.new('RGBA',im.size,'#eee8df');bg.alpha_composite(im);im=bg.convert('RGB')
 elif crop:im=im.crop(crop)
 w,h=box[2]-box[0],box[3]-box[1];im.thumbnail((w,h-22))
 sheet.paste(im,(box[0]+(w-im.width)//2,box[1]+22+(h-22-im.height)//2))
 ImageDraw.Draw(sheet).text((box[0]+5,box[1]+5),label,fill='#292831')
def new():return Image.new('RGB',(960,540),'#eee8df')
def save(im,n):im.save(REV/(n+'.png'))
views=['front','left','right','back','top'];res={'method':M.__doc__,'views':{},'before_pose':'Round-1 cameras/poses retained','after_pose':json.loads((OUT/'reference_poses.json').read_text())}
sil=new();dr=ImageDraw.Draw(sil);five=new()
for i,n in enumerate(views):
 r=M.normalise(M.refmask(n));a=np.asarray(Image.open(OUT/f'blender/{n}.png'));m=M.normalise(a[:,:,3]>127)
 before=np.asarray(Image.open(ROOT/f'art_src/s1/iteration_4/blender/{n}.png'));bm=M.normalise(before[:,:,3]>127)
 res['views'][n]={'before':M.iou(r,bm),'after':M.iou(r,m),'intersection':int((r&m).sum()),'union':int((r|m).sum()),'threshold':.75 if n in ['left','right'] else .85}
 rgb=np.full((512,512,3),246,np.uint8);rgb[r]=[222,90,104];rgb[m]=[53,155,192];rgb[r&m]=[49,56,65]
 sil.paste(Image.fromarray(rgb).resize((192,192)),(i*192,40));dr.text((i*192+4,12),f'{n} {M.iou(r,m):.4f}',fill='black')
 panel(sil,ROOT/f'art_src/hero_gull/gull_{n}.png',(i*192,260,(i+1)*192,500),'Reference')
 panel(five,OUT/f'blender/{n}.png',(i*192,0,(i+1)*192,260),'Model / '+n,alpha=True)
 panel(five,ROOT/f'art_src/hero_gull/gull_{n}.png',(i*192,270,(i+1)*192,540),'Reference / '+n)
dr.text((10,515),'Red reference only | Blue model only | Dark overlap. Uniform bbox scaling, no shape warp.',fill='black')
save(sil,'silhouettes');save(five,'five_views')
(OUT/'silhouette_iou.json').write_text(json.dumps(res,indent=2))

colours={};colorsheet=new()
for i,n in enumerate(['noon','golden','dusk']):
 mask=np.asarray(load(OUT/f'game/{n}_body_mask.png'));mm=(mask.min(2)>250)
 lab,_=ndimage.label(mm);size=np.bincount(lab.ravel());size[0]=0;mm=ndimage.binary_erosion(lab==size.argmax(),iterations=2)
 colours[n]={}
 for j,stage in enumerate(['before','after']):
  a=np.asarray(load(OUT/f'game/{n}_{stage}.png'))/255.;sat=(a.max(2)-a.min(2))/np.maximum(a.max(2),.001)
  pix=a[mm&(sat<.18)&(a.min(2)>.3)];luma=pix@np.array([.2126,.7152,.0722])
  lit=pix[luma>=np.percentile(luma,80)];shade=pix[luma<=np.percentile(luma,25)]
  colours[n][stage]={'pixels':len(pix),'luma_median_255':float(np.median(luma)*255),'lit_top20_rgb_255':list(np.mean(lit,axis=0)*255),'shadow_bottom25_rgb_255':list(np.mean(shade,axis=0)*255),'lit_saturation':float(np.mean((lit.max(1)-lit.min(1))/lit.max(1)))}
  panel(colorsheet,OUT/f'game/{n}_{stage}.png',(i*240,j*240,(i+1)*240,(j+1)*240),f'{n} / {stage}',crop=(380,140,610,365))
panel(colorsheet,ROOT/'art_src/reference/cover.jpg',(720,0,960,480),'Cover target',crop=(320,390,570,680))
ImageDraw.Draw(colorsheet).text((10,502),'Same actual island light; eroded body mask, neutral pixels only. Percentiles are image proxies for lit/shadow.',fill='black')
save(colorsheet,'white_before_after');(OUT/'colour_measurements.json').write_text(json.dumps(colours,indent=2))

cover=new();panel(cover,ROOT/'art_src/reference/cover.jpg',(0,0,480,410),'TARGET / cover gull',crop=(0,175,830,805))
panel(cover,OUT/'game/cover_pose.png',(480,0,960,410),'S1 round 2 / actual dusk roof',crop=(275,42,650,405))
ImageDraw.Draw(cover).text((12,430),'Raised wings + fry at the retained beak socket. Whole-island cover lighting is S2 and remains untouched.',fill='black')
ImageDraw.Draw(cover).text((12,456),'Open: far-wing foreshortening, angular joint covers, much flatter dusk light than the cover.',fill='black')
ImageDraw.Draw(cover).text((12,485),'S1 round 2 of maximum 3. Silhouette thresholds met; visual approval remains with the reviewer. STOP.',fill='black')
save(cover,'cover_comparison')
vn=new()
for i,n in enumerate(['vn_you','vn_you_hat','vn_big_bro']):panel(vn,OUT/f'game/{n}.png',(i*320,0,(i+1)*320,350),n)
for i,n in enumerate(['perch_side','topper_shades','bro_necklace']):panel(vn,OUT/f'game/{n}.png',(i*320,350,(i+1)*320,540),n)
save(vn,'portrait_and_fold')
# Inventory sheets make every final raw frame inspectable, including masks.
shots=sorted((OUT/'game').glob('*.png'))
for k in range(0,len(shots),9):
 sheet=new()
 for i,p in enumerate(shots[k:k+9]):panel(sheet,p,((i%3)*320,(i//3)*180,(i%3+1)*320,(i//3+1)*180),p.stem)
 save(sheet,f'frames_{k//9+1}')

def glb(path):
 data=Path(path).read_bytes();jl=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+jl]);binary=data[28+jl:]
 def acc(i):
  a=doc['accessors'][i];v=doc['bufferViews'][a['bufferView']];types={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'};n={'VEC2':2,'VEC3':3,'VEC4':4,'SCALAR':1}[a['type']]
  dt=np.dtype(types[a['componentType']]);start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',dt.itemsize*n)
  return np.ndarray((a['count'],n),dtype=dt,buffer=binary,offset=start,strides=(stride,dt.itemsize)).copy()
 out={}
 for node in doc['nodes']:
  if 'mesh' not in node:continue
  p=doc['meshes'][node['mesh']]['primitives'][0];out[node['name']]={k:acc(v) for k,v in p['attributes'].items()}
 return out
old=glb(OUT/'before/hero_gull_parts.glb');current=glb(ROOT/'game/assets/models/hero_gull_parts.glb')
dimensions={}
for name,parts in [('before',old),('after',current)]:
 h=parts['Head'];region=np.rint(h['TEXCOORD_0'][:,0]*7).astype(int);beak=h['POSITION'][region==6];eyes=h['POSITION'][region==7];eyes=eyes[eyes[:,0]>0]
 dimensions[name]={'beak_xyz_extent':list(map(float,np.ptp(beak,axis=0))),'eye_xyz_extent':list(map(float,np.ptp(eyes,axis=0))),'eye_center_local':list(map(float,(eyes.min(0)+eyes.max(0))/2))}
def necklace(path):
 v=glb(path)['Item']['POSITION'];p=v+np.array([0,-.015,-.27]);surface=.045-.431*np.sqrt(np.maximum(.04,1-(p[:,0]/.351)**2-((p[:,1]-.017)/.251)**2))
 gap=surface-p[:,2]
 return {'median_forward_clearance_m':float(np.median(gap)),'range_m':list(map(float,[gap.min(),gap.max()]))}
dimensions['bro_necklace']={'before':necklace(OUT/'before/game/assets/models/wear_bro_necklace.glb'),'after':necklace(ROOT/'game/assets/models/wear_bro_necklace.glb'),'method':'vertex Z clearance to front coat ellipsoid, in unscaled gull local metres; live bro scale is 2.3'}
geo=json.loads((OUT/'blender/geometry.json').read_text())
for label,upper_y,fore_y in [('before_fit',1,1),('after_fit',.6,.32)]:
 y=[]
 for n,d in geo.items():
  if not n.startswith(('Upper','Fore','Hand')):continue
  upper=n.startswith('Upper');side=-1 if n.endswith('L') else 1
  r=M.ry(-side*(1.25 if upper else 1.50))@M.rz(-side*.12 if upper else 0)
  scale=[1 if upper else .75,upper_y if upper else fore_y,.65 if upper else .55]
  p=np.array(d['vertices'])*scale;p=p@r.T;y.extend(p[:,1]+(.075 if upper else .035))
 dimensions[label]={'folded_wing_min_y':float(min(y)),'folded_wing_max_y':float(max(y)),'height':float(max(y)-min(y))}
(OUT/'dimensions.json').write_text(json.dumps(dimensions,indent=2))
baseline=json.loads((OUT/'before/source_hashes.json').read_text());changed=[p for p,h in baseline.items() if hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
(OUT/'source_audit.json').write_text(json.dumps({'baseline_files':len(baseline),'unchanged':len(baseline)-len(changed),'changed':changed},indent=2))
assets=[ROOT/'game/assets/models/hero_gull_parts.glb']+[ROOT/f'game/assets/models/wear_{n}.glb' for n in ['necklace','bro_necklace','glasses','shades','bro_shades']]
(OUT/'assets.json').write_text(json.dumps({str(p.relative_to(ROOT)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in assets},indent=2))
print(json.dumps({'iou':res['views'],'colours':colours,'dimensions':dimensions,'changed':changed},indent=2))
