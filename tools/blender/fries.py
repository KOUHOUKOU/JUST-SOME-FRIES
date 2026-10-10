"""P2 fry sets: two surfaces, painted seasoning, deterministic soft sticks."""
import sys, math, json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector,Matrix
import common as C
import p1b_common as P

# Keep canonical GLB node names when authoring several assets in one Blender scene.
_original_finish=P.finish
def canonical_finish(objects,name,*args,**kwargs):
 for ob in list(bpy.data.objects):
  if ob.name==name and ob not in objects:ob.name='Archived_'+name
 return _original_finish(objects,name,*args,**kwargs)
P.finish=canonical_finish

it=int(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else 1
review2='--review2' in sys.argv
folder=Path(f'art_src/p2_review2/iteration_{it}/fries_blender' if review2 else f'art_src/p2/iteration_{it}/fries');C.clean_scene();catalog={};sets={}

def fry_frame(centre,length,rot,x,y,z):
 t=y/length+.5
 twist=Matrix.Rotation((t-.5)*.24,3,'Y')
 rr=Matrix.Rotation(rot[2],3,'Z')@Matrix.Rotation(rot[0],3,'X')@Matrix.Rotation(rot[1],3,'Y')
 p=twist@Vector((x,y,z));p.x+=.004*math.sin(t*math.pi);p.z+=.002*math.sin(t*math.pi*1.4)
 return Vector(centre)+rr@p

def stick(n,centre,length=.43,width=.072,rot=(0,0,0),colour='F2B53A'):
 # Chamfered square cross-sections and rounded/tapered caps: 60 triangles.
 v=[];w=width*.5;b=w*.28
 cross=[(-w+b,-w),(w-b,-w),(w,-w+b),(w,w-b),(w-b,w),(-w+b,w),(-w,w-b),(-w,-w+b)]
 rr=Matrix.Rotation(rot[2],3,'Z')@Matrix.Rotation(rot[0],3,'X')@Matrix.Rotation(rot[1],3,'Y')
 for j,(y,k) in enumerate([(-length/2,.68),(-length/2+width*.23,1),(length/2-width*.23,1),(length/2,.68)]):
  for i,(x,z) in enumerate(cross):
   v.append(fry_frame(centre,length,rot,x*k,y,z*k))
 f=[tuple(reversed(range(8))),tuple(range(24,32))]
 for j in range(3):
  for i in range(8):f.append((8*j+i,8*j+(i+1)%8,8*(j+1)+(i+1)%8,8*(j+1)+i))
 o=P.mesh(n,v,f,colour,1);o['stick']=True;o['centre']=centre;o['length']=length;o['width']=width;o['rot']=rot
 return o

def bake(objs,name,path):
 tips={}
 def paint(o,p):
  c=C.linear_rgb(o['colour'])
  if o.get('stick',False):
   rot=o['rot'];rr=Matrix.Rotation(rot[2],3,'Z')@Matrix.Rotation(rot[0],3,'X')@Matrix.Rotation(rot[1],3,'Y')
   local=rr.transposed()@(P.g(p)-Vector(o['centre']));t=local.y/o['length']+.5
   untwist=Matrix.Rotation(-(t-.5)*.24,3,'Y')@local
   side=min(1,max(0,(abs(untwist.x)/(o['width']*.5)-.68)/.32))
   c=C.linear_rgb('F0AC24').lerp(C.linear_rgb('B96B1B'),side*.64)
   c=c.lerp(C.linear_rgb('FFD15B'),max(0,(t-.70)/.30)*.36)
   tips[tuple(round(v,6) for v in p)]=max(0,min(1,t))
  return c
 o,_=P.finish(objs,name,path,paint)
 # Axial coordinate supports cached, per-kind tip paint without extra surfaces.
 if name=='Sticks':
  uv=o.data.uv_layers.active
  for k,loop in enumerate(o.data.loops):
   pos=o.matrix_world@o.data.vertices[loop.vertex_index].co
   uv.data[k].uv.y=tips.get(tuple(round(v,6) for v in pos),0)
 return o

for kind in ['box','plate','cone','hand','star','ordinary']:
 if review2 and kind=='ordinary':continue # Plain fry asset and all rules are untouched.
 carrier=[];sticks=[]
 if kind=='box':
  carrier=[P.box('Carton',(0,.135,0),(.38,.27,.19),'D96554',0,taper=1.2,region=2),P.panel('CreamLabel',(0,.145,-.108),(.22,.10,.012),'FFF0D4',.025),P.panel('Rim',(0,.269,-.105),(.43,.045,.035),'ED8B6D',.017,2)]
  carrier += [P.panel('LabelMark',(x,.145,-.117),(.016,.055,.004),'D96554',.006,2) for x in [-.035,0,.035]]
 elif kind=='plate':
  carrier=[P.lathe('Plate',[(.006,.31),(.019,.39),(.048,.39),(.057,.33),(.024,.29)],16,'F7EFDE'),P.lathe('DipCup',[(.04,.054),(.12,.07),(.13,.069),(.11,.052)],8,'FFF0D4',centre=(.27,0,.13)),P.lathe('Dip',[(.113,.05),(.118,.05)],8,'B94B3C',centre=(.27,0,.13))]
 elif kind in ['cone','hand']:
  carrier=[P.lathe('Twist',[(.01,.035),(.06,.067),(.27,.15),(.29,.147),(.25,.13)],10,'F0D5AE'),P.panel('Seal',(0,.19,-.128),(.095,.07,.016),'D96554',.018,2)]
 elif kind=='star':carrier=[P.lathe('Ribbon',[(-.22,.09),(-.185,.13),(-.15,.10)],10,'D96554',region=2)]
 if kind=='ordinary':
  sticks=[stick('Plain',(0,.06,0),.72,.10,(math.pi/2,.35,0),'E3A93A')]
 else:
  for k in range(5 if kind=='plate' else 6):
   x=(k-2.5)*.054;h=.37+.07*math.sin(k*2.1)
   c=(x,.35+h*.10,(k%2-.5)*.062);rot=(.10*(-1)**k,0,-x*.8)
   if kind=='plate':c=((k-2)*.048,.105+.026*(k%3),0);rot=(1.02,(-.40+k*.20),.35)
   if kind=='star':c=(x,.005,(k%2-.5)*.045)
   sticks.append(stick('Fry'+str(k),c,h,.068,rot))
  # Eight little grains sit ON the transformed stick faces, never in free space.
  salt=[]
  for k in range(8):
   fry=sticks[k%len(sticks)];side=-1 if k<4 else 1
   y=fry['length']*(.12+.075*(k%3));z=side*(fry['width']*.5+.002)
   pts=[fry_frame(fry['centre'],fry['length'],fry['rot'],x,yy,z) for x,yy in [(-.008,y),(.007,y+.002),(-.003,y+.013)]]
   salt.append(P.mesh('Salt',pts,[(0,1,2) if side>0 else (0,2,1)],'FFF2CD',0))
  sticks+=salt
 parts=[]
 if carrier:parts.append(bake(carrier,'Carrier',folder/'parts'/f'{kind}_carrier.glb'))
 parts.append(bake(sticks,'Sticks',folder/'parts'/f'{kind}_sticks.glb'))
 # One material definition per mesh; the loader preserves separate legacy glow strengths.
 path=f'game/assets/models/fry_{kind}.glb';C.export_glb(parts,path,texcoords=True)
 count=C.triangle_count(parts);assert count<=600,(kind,count)
 catalog[kind]={'tris':count,'draws':len(parts),'bytes':C.output_path(path).stat().st_size};sets[kind]=parts

# All carriers plus three actual accent identities, five-angle review as one family.
cast=[]
for i,(kind,parts) in enumerate(sets.items()):
 for src in parts:
  o=src.copy();o.data=src.data.copy();bpy.context.scene.collection.objects.link(o);o.location=P.b(((i-2.5)*.85,0,0));cast.append(o)
for i,hex_ in enumerate(['E8453C','4FBF5A','3D6FE0']):
 for src in sets['box']:
  o=src.copy();o.data=src.data.copy();bpy.context.scene.collection.objects.link(o);o.location=P.b(((i-1)*1.1,0,1.1));cast.append(o)
  col=o.data.color_attributes.active_color;uv=o.data.uv_layers.active
  for k in range(len(col.data)):
   if round(uv.data[k].uv.x*15)==2:
    a=col.data[k].color[:];ref=C.linear_rgb('D96554');t=C.linear_rgb(hex_);col.data[k].color=(*[a[j]*t[j]/ref[j] for j in range(3)],1)
if review2:P.cast(cast,folder/'fry_cast.png',512,300,5.3)
else:P.turn(cast,folder/'turntable')
C.output_path(folder/'stats.json').write_text(json.dumps(catalog,indent=2))
print('[P2 FRIES]',catalog)
