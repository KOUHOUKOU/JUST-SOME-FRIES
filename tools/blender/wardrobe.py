"""All 19 existing wardrobe items and four brother variants, socket-local.
Current default fits the S1 head/body. --legacy-fit is historical P2 only.
"""
import sys,math,json
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

TORSO=['hawaii','stripes','coat','bro_coat']
it=int(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else 1
s1='--legacy-fit' not in sys.argv
folder=Path('art_src/s1/round_2/wardrobe' if '--round2' in sys.argv else (f'art_src/s1/iteration_{it}/wardrobe' if s1 else f'art_src/p2/iteration_{it}/wardrobe'));C.clean_scene();items={};stats={}
def egg(n,c,r,col,s=8,q=4):return P.ellipsoid(n,c,r,col,s,q)
def ring(n,c,rx,ry,t,col,sides=12,axis='Z',start=0,end=math.tau):
 v=[]
 for i in range(sides+1):
  a=start+(end-start)*i/sides
  for j in range(3):
   b=j*math.tau/3;x=(rx+t*math.cos(b))*math.cos(a);y=(ry+t*math.cos(b))*math.sin(a);z=t*math.sin(b)
   v.append(Vector(c)+Vector((x,y,z) if axis=='Z' else (x,z,y)))
 f=[(i*3+j,i*3+(j+1)%3,(i+1)*3+(j+1)%3,(i+1)*3+j) for i in range(sides) for j in range(3)]
 return P.mesh(n,v,f,col)
def finish(kind,groups,paint=None):
 if '--round2' in sys.argv and kind not in ['necklace','bro_necklace','glasses','shades','bro_shades']:return
 if s1:
  # Bake tailoring in mesh coordinates; every original root/slot stays intact.
  base=kind.replace('bro_','')
  for objs in groups.values():
   for ob in objs:
    for v in ob.data.vertices:
     p=P.g(v.co)
     if kind in TORSO:pass
     elif base in ['hat','sailor','topper','beret']:
      # round 15: the head is 26 % smaller (radius .255 -> .188), centre (0,.30,-.30); item origin = gull (0,.2,-.36)
      p.x*=1.22;p.z=p.z*1.22+.062;p.y+=.204
     elif base in ['glasses','shades']:
      p.x*=1.37;p.y+=.192;p.z=p.z*1.25+.057
     elif base=='pipe':p.y+=.115;p.z-=.043
     elif base=='bowtie':p.x*=1.5;p.y=p.y*1.5+.098;p.z+=.045
     elif base=='necklace':
      # Original neck root remains (0,-.015,-.27). Wrap the chain around the
      # actual chest/coat ellipsoid, instead of leaving it on a floating plane.
      p.x*=1.65;p.y=p.y*1.05+.055
      yy=p.y-.015
      rx,ry,rz,cy,cz=(.256,.217,.245,.01,-.175) if kind=='bro_necklace' else (.232,.196,.222,.01,-.175)
      surface=cz-rz*math.sqrt(max(.04,1-(p.x/rx)**2-((yy-cy)/ry)**2))
      p.z=surface+.27-.008+(p.z+.043)*.5
     elif base=='scarf':
      if ob.name.startswith('Collar'):p.x*=1.4;p.y+=.18;p.z=p.z*1.3-.037
      else:p.x=p.x*1.7;p.y+=.27;p.z=p.z*.8-.12
     v.co=P.b(p)
 parts=[]
 for n,objs in groups.items():parts.append(P.finish(objs,n,folder/'parts'/f'{kind}_{n}.glb',paint)[0])
 C.export_glb(parts,f'game/assets/models/wear_{kind}.glb',texcoords=True)
 count=C.triangle_count(parts);assert count<=(700 if kind in TORSO else 300),(kind,count)
 items[kind]=parts;stats[kind]={'tris':count,'draws':len(parts)}
for kind in ['hat','sailor','topper','beret','bro_topper']:
 if kind=='beret':
  objs=[egg('Beret',(0,.039,0),(.147,.051,.139),'B95151',12,5),P.lathe('Stalk',[(.071,.014),(.103,.012)],6,'803944')]
 else:
  col='E7CFA0' if kind=='hat' else ('F5EFE4' if kind=='sailor' else '30303B')
  h=.10 if kind in ['hat','sailor'] else (.25 if kind=='bro_topper' else .19)
  objs=[P.lathe('Hat',[(.012,.126),(.023,.185 if kind!='sailor' else .145),(.04,.184 if kind!='sailor' else .15),(.045,.126),(.04+h,.112),(.052+h,.095)],10,col),P.lathe('Band',[(.045,.128),(.073,.125)],10,'B87966' if kind=='hat' else ('486C91' if kind=='sailor' else 'C6A878'))]
  if kind=='hat':objs.append(P.panel('Ribbon',(.112,.061,-.075),(.05,.06,.015),'B87966',.01))
  if kind=='sailor':objs.append(egg('Pom',(0,h+.06,0),(.026,.022,.026),'B95151',6,3))
  if kind=='bro_topper':objs.append(egg('Plume',(.115,.15,.02),(.027,.095,.022),'B77C7A',6,3))
 finish(kind,{'Item':objs})
for kind in ['glasses','shades','bro_shades']:
 objs=[];col='A78C64' if kind=='bro_shades' else '5F4D4C'
 for side in [-1,1]:
  if kind=='glasses':objs.append(ring('Rim',(.079*side,.034,-.118),.037,.035,.0055,col,10))
  else:objs.append(egg('Lens',(.079*side,.034,-.115),(.041,.032,.013),'303440',8,4))
  objs.append(P.box('Temple',(.118*side,.041,-.045),(.010,.010,.139),col))
 objs.append(P.box('Bridge',(0,.045,-.12),(.08,.009,.010),col));finish(kind,{'Item':objs})
for kind in ['necklace','bro_necklace']:
 objs=[]
 for i in range(8):
  a=i*math.tau/8;objs.append(egg('Bead',(.112*math.cos(a),-.055+.08*math.sin(a),-.043),(.03,.027,.024),'F0C94A' if kind=='necklace' else 'E2B73C',6,3))
 objs.append(ring('Thread',(0,-.055,-.043),.112,.08,.009,'D9A92E',8))
 if kind=='bro_necklace':objs.append(egg('Medal',(0,-.158,-.053),(.05,.05,.02),'E8BE3A',6,3))
 finish(kind,{'Item':objs})
finish('bowtie',{'Item':[egg('Bow',(-.046,-.025,.045),(.048,.03,.02),'BC686C'),egg('Bow',(.046,-.025,.045),(.048,.03,.02),'BC686C'),egg('Knot',(0,-.025,.030),(.021,.024,.021),'824754',6,3)]})
scarf=[ring('Collar',(0,.005,-.01),.12,.11,.036,'BA6860',12,'Y')]
tail=[P.panel('Tail',(.07,-.078,.145),(.072,.28,.018),'BA6860',.02)]
# Tail lies along the body/back, fringe emerges from its end.
for o in tail:
 for v in o.data.vertices:
  p=P.g(v.co);v.co=P.b((p.x,-.073+p.z-.145,.145-(p.y+.078)))
for i in range(4):tail.append(P.box('Fringe',(.043+i*.017,-.068,.29),(.009,.012,.038),'D5AC92'))
finish('scarf',{'Item':scarf,'ScarfTail':tail})
finish('pipe',{'Item':[P.panel('Stem',(.05,-.065,-.16),(.016,.016,.15),'775A47',.004),P.lathe('Bowl',[(-.074,.023),(-.06,.033),(-.018,.035),(-.012,.028)],8,'785342',centre=(.05,0,-.215)),egg('Ash',(.05,-.017,-.215),(.022,.004,.022),'3E3540',6,3)]})

# ROUND 15: the shirts and coats are shells that follow the real body + chest exactly (a few mm outside the feathers), with a hole where the head comes out.
# Every pattern is a function of (band along the body, sector around it), so stripes / flowers / plaid run in one piece over the whole garment.
BODY=((0,.015,.075),(.30,.23,.38));CHEST=((0,.01,-.175),(.225,.19,.215));HEAD=((0,.30,-.30),(.188,.188,.184))
ZF=-.39;ZB=.455;NB=14;NS=18;DZ=(ZB-ZF)/NB
def section(z):
 lo=1e9;hi=-1e9;rx=0
 for c,r in (BODY,CHEST):
  f=1-((z-c[2])/r[2])**2
  if f<=0:continue
  f=math.sqrt(f);lo=min(lo,c[1]-r[1]*f);hi=max(hi,c[1]+r[1]*f);rx=max(rx,r[0]*f)
 return None if hi<lo else ((lo+hi)/2,rx,(hi-lo)/2)
def pattern(kind,kb,sec):
 if kind=='stripes':return 'F1EEE4' if kb%2==0 else '2F527F'
 if kind=='hawaii':
  if kb%2==1 and (sec+kb//2*2)%4==0:return 'E39AA0'
  if kb%2==0 and (sec+kb//2*2)%4==2:return 'F0CF82'
  return '4F9A92'
 if kind=='coat':
  if kb%4==0 and sec%3==0:return 'D2AD4C'
  if kb%4==0 or sec%3==0:return '7A7E9A'
  return '3F4260'
 return '985D72' if sec%2==0 else '85415B'          # bro_coat: pinstripes along the body
def paint_torso(kind,scale):
 def paint(o,p):
  x,y,z=P.g(p);sc=section(min(max(z,ZF+.001),ZB-.001))
  kb=int(math.floor((z-ZF)/DZ));cy=sc[0] if sc else .02
  sec=int(math.floor((math.atan2(x,y-cy)%math.tau)/(math.tau/NS)))
  return C.linear_rgb(pattern(kind,kb,sec))
 return paint
def shell(kind,grow,tails):
 verts=[];faces=[];nudge=.008
 rings=[]
 for k in range(NB+1):
  z=ZF+k*DZ;sc=section(min(max(z,ZF+1e-4),ZB-1e-4))
  rings.append([(grow*sc[1]*math.sin(2*math.pi*i/NS)+0,sc[0]+grow*sc[2]*math.cos(2*math.pi*i/NS)+(.006 if grow>1.06 else 0),z) for i in range(NS)])
 def inside_head(c):
  return ((c[0]/(HEAD[1][0]*1.2))**2+((c[1]-HEAD[0][1])/(HEAD[1][1]*1.2))**2+((c[2]-HEAD[0][2])/(HEAD[1][2]*1.2))**2)<1
 def add(quad):
  c=[sum(v[j] for v in quad)/len(quad) for j in range(3)]
  if inside_head(c):return
  base=len(verts)
  for v in quad:verts.append(tuple(v[j]+(c[j]-v[j])*nudge for j in range(3)))
  faces.append(tuple(range(base,base+len(quad))))
 for k in range(NB):
  for i in range(NS):
   a=rings[k][i];b2=rings[k][(i+1)%NS];c2=rings[k+1][(i+1)%NS];d=rings[k+1][i]
   if k==0:add([a,c2,d])
   elif k==NB-1:add([a,b2,d])
   else:add([a,b2,c2,d])
 # every facet is its own island (so its colour can be read from its position): orient each one outward by hand (a normals recalculation works per island and would flip them at random)
 fixed=[]
 for f in faces:
  pts=[Vector(verts[i]) for i in f];c=sum(pts,Vector())/len(pts)
  n=(pts[1]-pts[0]).cross(pts[2]-pts[0])
  mid=Vector((0,.02,.03))
  fixed.append(tuple(reversed(f)) if n.dot(c-mid)<0 else f)
 m=bpy.data.meshes.new('Cloth');m.from_pydata([P.b(v) for v in verts],[],fixed);m.update()
 body=bpy.data.objects.new('Cloth',m);bpy.context.scene.collection.objects.link(body)
 P.register(body,'Cloth','FFFFFF',0)
 objs=[body]
 if tails:
  # the long coat: two skirts that hang behind and under the tail
  for side in [-1,1]:
   fl=P.panel('Tail',(side*.095,-.055,.52),(.17,.03,.36),'FFFFFF',.012)
   objs.append(fl)
 return objs
for kind in TORSO:
 grow={'hawaii':1.045,'stripes':1.045,'coat':1.06,'bro_coat':1.12}[kind]
 objs=shell(kind,grow,'coat' in kind)
 if 'coat' in kind:
  for j in range(3):objs.append(egg('Button',(0,.05-j*.045,-.382+j*.018),(.012,.012,.012),'C5AB7B',3,3))
 finish(kind,{'Item':objs},paint_torso(kind,grow))
finish('balloon',{'Item':[P.lathe('String',[(.05,.0028),(.72,.0028)],5,'DDD6C7')],'Balloon':[egg('Balloon',(0,.83,.02),(.158,.19,.154),'C98680',12,6),P.lathe('Knot',[(.641,.014),(.668,.008)],5,'B36D70')]})
sock=egg('Sock',(0,0,.13),(.159,.065,.222),'D7DACA',10,6)
def sockpaint(o,p):return C.linear_rgb('B96E69' if int((P.g(p).z+.2)*35)%3==0 else 'E6DED0')
finish('socks',{'Item':[sock]},sockpaint)
finish('cloud',{'Item':[egg('Cloud',(x,y,z),(r,r*.74,r*.85),'F4EEE9',8,4) for x,y,z,r in [(0,0,0,.16),(.17,-.02,.02,.12),(-.17,-.03,0,.12),(.07,.07,0,.10),(-.08,.06,0,.10)]]})
objs=[egg('Sun',(0,0,0),(.105,.105,.037),'D3B879',10,5)]
for i in range(8):
 a=i*math.tau/8;objs.append(P.box('Ray',(.155*math.cos(a),.155*math.sin(a),0),(.055,.018,.018),'C9A578',rot=(0,0,math.degrees(a))))
finish('sun',{'Item':objs})
objs=[]
for i,col in enumerate(['C87573','D8A775','D8CA8D','8FB292','86ADBF','8C94B5','AB9BB6']):objs.append(ring('Bow',(0,0,0),.30+i*.024,.26+i*.024,.009,col,5,'Z',0,math.pi))
finish('skybow',{'Item':objs})
v=[(0,0,-.015),(0,0,.015)]
for z in [-.01,.01]:
 for i in range(10):
  a=math.pi/2+i*math.pi/5;r=.115 if i%2==0 else .052;v.append((math.cos(a)*r,math.sin(a)*r,z))
faces=[]
for i in range(10):faces.extend([(0,2+i,2+(i+1)%10),(1,12+(i+1)%10,12+i),(2+i,12+i,12+(i+1)%10,2+(i+1)%10)])
finish('meteor',{'Spin':[P.mesh('Star',v,faces,'CEB483')]})
C.output_path(folder/'stats.json').write_text(json.dumps(stats,indent=2))
if s1:
 print('[S1 WARDROBE] mesh-local refit; in-engine fitting review:',stats)
 sys.exit(0)

# Import the approved gull for wardrobe fitting; no edits/export to the hero.
bpy.ops.import_scene.gltf(filepath=str(C.output_path('game/assets/models/hero_gull_parts.glb')))
hero=[o for o in bpy.context.selected_objects if o.type=='MESH']
piv={'Body':(0,0,0),'Chest':(0,0,0),'Head':(0,.1,-.36),'Tail':(0,0,.38),'Legs':(0,0,0)}
for o in hero:
 if o.name=='Body':o.scale=(1,1.9,.9)
 o.location=P.b(piv.get(o.name,(0,0,0)))
bpy.context.view_layer.update()
bpy.context.scene.view_settings.exposure=-2.0
# Head/body/tail/feet fitting sheet: wings intentionally excluded to expose clothes.
hero=[o for o in hero if o.name in piv]
socket={'hat':(0,.2,-.36),'sailor':(0,.2,-.36),'topper':(0,.2,-.36),'beret':(.02,.205,-.36),'glasses':(0,.1,-.36),'shades':(0,.1,-.36),'pipe':(0,.1,-.36),'bowtie':(0,.025,-.43),'necklace':(0,-.015,-.27),'scarf':(0,-.015,-.25),'socks':(0,0,.38),'cloud':(0,.66,.1),'sun':(0,.14,.3),'skybow':(0,.2,-.12),'meteor':(0,.02,.36)}
for idx,(kind,parts) in enumerate(items.items()):
 objects=[];basekind=kind.replace('bro_','');off=Vector(socket.get(basekind,(0,0,0)))
 for angle,x in [(math.pi,-.62),(math.pi/2,.62)]:
  rot=Matrix.Rotation(angle,3,'Y')
  for src in hero+parts:
   o=src.copy();o.data=src.data.copy();bpy.context.scene.collection.objects.link(o)
   # Bake the parent/scale transform before applying the review-only orientation.
   for ve in o.data.vertices:
    p=P.g(src.matrix_world@ve.co) if src in hero else P.g(ve.co)+off
    ve.co=P.b(rot@p+Vector((x,0,0)))
   o.matrix_world=Matrix.Identity(4);objects.append(o)
 P.cast(objects,folder/f'{idx:02d}_{kind}_front_side.png',width=512,height=256,scale=2.65)
 for o in objects:bpy.data.objects.remove(o,do_unlink=True)
print('[P2 WARDROBE]',stats)

