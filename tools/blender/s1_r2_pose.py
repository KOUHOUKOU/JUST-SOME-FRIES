"""Rigid reference-pose registration; no mesh/image deformation.

Review 8 explicitly asks for raised side wings and spread top wings. Register
camera azimuth/elevation and existing shoulder/elbow rotations only. Back
retains its original camera/pose. Report all parameters. These are
pose-conditioned silhouette scores, not independent shape-validation scores.
Bounded CPU raster fits guide registration; final scores use Blender alpha.
"""
import json,math,argparse
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
from scipy import ndimage,optimize
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art_src/s1/round_2'
def refmask(name):
 a=np.asarray(Image.open(ROOT/f'art_src/hero_gull/gull_{name}.png').convert('RGB'))
 lab,_=ndimage.label(a.min(2)<243);sizes=np.bincount(lab.ravel());sizes[0]=0
 return ndimage.binary_fill_holes(lab==sizes.argmax())
def normalise(m,n=512):
 y,x=np.where(m);box=(int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1))
 im=Image.fromarray(m).crop(box);scale=(460*n/512)/max(im.size)
 im=im.resize(tuple(max(1,round(v*scale)) for v in im.size),Image.Resampling.NEAREST)
 out=Image.new('1',(n,n));out.paste(im,((n-im.width)//2,(n-im.height)//2))
 return np.asarray(out)
def rz(t):
 c,s=math.cos(t),math.sin(t);return np.array([[c,-s,0],[s,c,0],[0,0,1]])
def ry(t):
 c,s=math.cos(t),math.sin(t);return np.array([[c,0,s],[0,1,0],[-s,0,c]])
def posed(geo,config):
 verts=[];faces=[]
 for name,data in geo.items():
  v=np.array(data['vertices']);off=np.zeros(3)
  if name=='Body':v*=np.array([1,.9,1.9])
  elif name=='Head':off=np.array([0,.1,-.36])
  elif name=='Tail':off=np.array([0,0,.38])
  elif name.startswith(('Upper','Fore','Hand')):
   side=-1 if name.endswith('L') else 1
   values=config['left' if side==-1 else 'right'];a,e=values[:2];s=values[2] if len(values)>2 else 0
   r=ry(-s*side)@rz(a*side)
   off=np.array([side*.14,.07,-.06])
   if not name.startswith('Upper'):
    off+=r@np.array([side*.32,0,0]);r=r@rz(-e*side)
   v=v@r.T
  start=len(verts);verts.extend(v+off);faces.extend([[i+start for i in f] for f in data['faces']])
 return np.array(verts),faces
def render(geo,c,n=256):
 v,f=posed(geo,c);d=np.array(c['camera']);d=d/np.linalg.norm(d)
 if c.get('top'):right=np.array([-1,0,0]);up=np.array([0,0,1])
 else:
  right=np.cross([0,1,0],d);right/=np.linalg.norm(right);up=np.cross(d,right)
 xy=np.column_stack((v@right,-v@up))
 roll=c.get('roll',0);cr,sr=math.cos(roll),math.sin(roll)
 xy=xy@np.array([[cr,-sr],[sr,cr]]).T
 lo=xy.min(0);hi=xy.max(0)
 xy=(xy-(lo+hi)/2)*((n-12)/(hi-lo).max())+n/2
 im=Image.new('1',(n,n));dr=ImageDraw.Draw(im)
 for face in f:dr.polygon([tuple(xy[i]) for i in face],fill=1)
 return normalise(np.asarray(im),n)
def iou(a,b):return np.count_nonzero(a&b)/np.count_nonzero(a|b)
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--fit',action='store_true');args=ap.parse_args()
 geo=json.loads((OUT/'blender/geometry.json').read_text())
 configs={'front':{'camera':[0,.06,-1],'left':[.72,.72],'right':[.72,.72]},'back':{'camera':[0,.06,1],'left':[.72,.72],'right':[.72,.72]}}
 if args.fit:
  # Near wing is higher than the far wing in both side references. They are
  # different illustrated poses; forcing one pose was the round-1 error.
  def sideconfig(x):
   az,el,na,ne,fa,fe,ns,fs,roll=x
   return {'camera':[-math.sin(az)*math.cos(el),math.sin(el),-math.cos(az)*math.cos(el)],'left':[na,ne,ns],'right':[fa,fe,fs],'roll':roll}
  r=normalise(refmask('left'),256)
  def cost(x):return 1-iou(r,render(geo,sideconfig(x)))
  x0=[.98,.26,1.10,.75,.60,.5,0,-.3,0]
  # Keep the far wing raised and visible, not hidden behind the face merely
  # to improve the union score. Existing sweep DOF resolves its foreshortening.
  result=optimize.minimize(cost,x0,method='Powell',bounds=[(.75,1.3),(.12,.40),(.8,1.4),(.3,1.1),(.4,.9),(0,.65),(-.55,.55),(-.65,.1),(-.12,.12)],options={'maxiter':6,'maxfev':650,'xtol':.006,'ftol':.0005})
  configs['left']=sideconfig(result.x)
  configs['right']={'camera':[-configs['left']['camera'][0],*configs['left']['camera'][1:]],'left':configs['left']['right'],'right':configs['left']['left']}
  configs['right']['roll']=-configs['left']['roll']
  r=normalise(refmask('top'),256)
  def topconfig(x):return {'camera':[0,1,0],'top':True,'left':list(x),'right':list(x)}
  result=optimize.minimize(lambda x:1-iou(r,render(geo,topconfig(x))),[.12,.3],method='Powell',bounds=[(-.15,.45),(-.10,.6)],options={'maxiter':4,'maxfev':160,'xtol':.005})
  configs['top']=topconfig(result.x)
  r=normalise(refmask('front'),256)
  def frontconfig(x):return {'camera':[0,float(x[2]),-1],'left':list(x[:2]),'right':list(x[:2])}
  result=optimize.minimize(lambda x:1-iou(r,render(geo,frontconfig(x))),[.72,.72,.06],method='Powell',bounds=[(.60,.82),(.62,.9),(-.12,.15)],options={'maxiter':4,'maxfev':200,'xtol':.004})
  configs['front']=frontconfig(result.x)
  (OUT/'reference_poses.json').write_text(json.dumps(configs,indent=2))
 else:configs=json.loads((OUT/'reference_poses.json').read_text())
 sheet=Image.new('RGB',(960,540),'#eee8df');dr=ImageDraw.Draw(sheet);scores={}
 for i,name in enumerate(['front','left','right','back','top']):
  m=render(geo,configs[name],512);r=normalise(refmask(name));score=iou(r,m);scores[name]=score
  rgb=np.full((512,512,3),246,np.uint8);rgb[r]=[222,90,104];rgb[m]=[53,155,192];rgb[r&m]=[49,56,65]
  sheet.paste(Image.fromarray(rgb).resize((192,192)),(i*192,40));dr.text((i*192+4,10),f'{name} CPU {score:.4f}',fill='black')
  ref=Image.open(ROOT/f'art_src/hero_gull/gull_{name}.png');ref.thumbnail((192,192));sheet.paste(ref,(i*192,260))
 dr.text((8,490),'Rigid pose registration only. Final acceptance uses Blender alpha, not this CPU approximation.',fill='black')
 sheet.save(OUT/'review/pose_registration.png');print(json.dumps(scores,indent=2))
if __name__=='__main__':main()
