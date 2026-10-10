"""Seeded clay houses fitted to the unchanged seed-42 house calls/colliders.
The captured catalogue preserves every wall dimension, opening and chimney position.
"""
import sys,json,math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector,Matrix
import common as C
import p1b_common as P
it=int(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else 1
folder=Path(f'art_src/p1b_review2/iteration_{it}/houses');C.clean_scene()
catalog=json.loads((C.ROOT/'art_src/p1b/baseline/catalog.json').read_text(encoding='utf-8'))['houses']
combos=[('F0DFC0','954D35','527C69'),('DEA08A','32646B','F0DDAD'),('E1C578','A95646','537C76'),('91B5B4','9E5539','E7D5B1'),('C997A1','336C70','E6D9C6'),('EAD6B7','B56946','658453')]
objects=[];stats={};index={}

def arch(name,centre,w,h,depth,col):
 pts=[(-w/2,-h/2),(w/2,-h/2)]
 for i in range(9):
  a=i*math.pi/8;pts.append((math.cos(a)*w/2,h/2-w/2+math.sin(a)*w/2))
 verts=[Vector(centre)+Vector((x,y,z)) for z in [-depth/2,depth/2] for x,y in pts];n=len(pts)
 faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 return P.mesh(name,verts,faces,col,smooth=False)

for i,record in enumerate(catalog):
 p=record['params'];x,z,w,d,h,wall,roof,kind=p[:8];base=record['base'];origin=Vector((x,base,z))
 wallc,roofc,shutter=combos[(i*5+42)%6];pieces=[];window_front=[];window_back=[];flower=[]
 for q,c in enumerate(record['commands']):
  pos=Vector(c['pos'])-origin;size=Vector(c['size']);col=c['colour'].upper()
  if q==0:continue # the existing foundation is wholly underground; collider still unchanged
  if q==1:
   pieces.append(P.box('Wall',pos,size,wallc,.16,taper=.988));continue
  if q==2:
   pieces.append(P.panel('Plinth',pos,size,'AAA08E',.025));continue
  if c['key']=='window':
   (window_front if pos.z>0 else window_back).append(pos);continue
  if c['kind']=='ball':
   flower.append(pos);continue
  if c['kind']=='prism':
   hx,hy,hz=size.x/2,size.y/2,size.z/2;hip=.40 if i%2==0 else 0
   vs=[(-hx,-hy,-hz),(hx,-hy,-hz),(hx,-hy,hz),(-hx,-hy,hz),(-hx+hip,hy,0),(hx-hip,hy,0)]
   fs=[(0,3,2,1),(0,1,5,4),(3,4,5,2),(0,4,3),(1,2,5)]
   o=P.mesh('HipRoof' if hip else 'GableRoof',vs,fs,roofc,smooth=False);C.bevel(o,.12,2);C.smooth(o,True)
   rr=Matrix.Rotation(math.radians(c['rot'][1]),3,'Y')
   for v in o.data.vertices:v.co=P.b(pos+rr@P.g(v.co))
   pieces.append(o)
   ridge=P.ellipsoid('Ridge',(0,0,0),((size.x-hip*2-.1)/2,.07,.10),roofc,8,4)
   for v in ridge.data.vertices:v.co=P.b(pos+Vector((0,hy-.07,0))+rr@P.g(v.co))
   pieces.append(ridge)
   continue
  if c['kind']!='box':continue
  # Rebuild each original front window as one compact framed shutter unit below.
  if (abs(size.x-1.2)<.02 and abs(size.y-1.5)<.02) or abs(size.x-.28)<.02 or (abs(size.x-1.4)<.02 and size.y<.1):continue
  if abs(size.x-.95)<.02 and abs(size.y-2.1)<.02:
   pieces.append(arch('DoorFrame',pos-Vector((0,0,.025)),1.1,2.2,.075,'EAE3D4'))
   pieces.append(arch('Door',pos+Vector((0,0,.025)),.95,2.1,.08,shutter))
   pieces.append(P.panel('Step',(pos.x,.03,pos.z+.12),(1.25,.06,.35),'B8AA95',.02))
   continue
  if size.x<1.21 and size.y<.3 and size.z>.25 and pos.y>2:
   pieces.append(P.panel('FlowerBox',pos,size,'B27D68',.018));continue
  if col==wall.upper():col=wallc
  if col==roof.upper():col=roofc
  if col=='8B6A5A':col='AB8B78'
  bevel=.025 if max(size)>1 else .018
  # Flat parapets keep their exact top, width and clear roof terrace.
  pieces.append(P.panel('Detail',pos,size,col,bevel) if q<9 or size.y>1 else P.box('Detail',pos,size,col))
 for pos in window_front:
  pieces.append(P.panel('WindowFrame',pos-Vector((0,0,.015)),(1.16,1.43,.06),'EDE3D1',.025))
  # Glass and muntins are shallow surfaces; shader remains opaque and shared.
  pieces.append(P.box('Window',pos+Vector((0,0,.027)),(.90,1.20,.03),'587782'))
  for side in [-1,1]:pieces.append(P.box('Shutter',pos+Vector((side*.69,0,.015)),(.28,1.43,.06),shutter))
  pieces.append(P.box('Sill',pos+Vector((0,-.74,.07)),(1.4,.08,.22),'DED3BE'))
 for pos in window_back:pieces.append(P.box('BackWindow',pos,(.90,1.20,.08),'587782'))
 for pos in flower:
  # Small flat petal rosettes, part of the house mesh, not extra draw calls.
  pieces.append(P.ellipsoid('Flower',pos,(.10,.10,.08),['D79183','E1C67B','E4C6CE'][i%3],6,3))
 name=f'house_{i:02d}';o,ao=P.finish(pieces,name,f'game/assets/models/{name}.glb')
 tris=C.triangle_count([o]);assert tris<=1200,(name,tris)
 objects.append(o);stats[name]={'tris':tris,'parts':1,'materials':1,'combo':(i*5+42)%6,'roof':kind if kind=='flat' else ('hip' if i%2==0 else 'gable'),'footprint':[w,d],'wall_height':h,'base':base}
 index[record['signature']]={'file':name+'.glb','triangles':tris,'base':base}
C.output_path('game/assets/models/house_catalog.json').write_text(json.dumps(index,indent=2),encoding='utf-8')
P.turn([objects[1]],folder/'gable_turntable');P.turn([objects[2]],folder/'hip_turntable')
# Six colour combinations, selected from actual fitted houses.
selected=[objects[j] for j in [0,1,2,3,4,5]]
for j,o in enumerate(selected):o.location=P.b(((j%3-1)*13,(j//3)*14,0))
P.cast(selected,folder/'six_combos.png',scale=41,height=370)
C.output_path(folder/'stats.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print('[P1B HOUSES]',len(objects),'range',min(v['tris'] for v in stats.values()),max(v['tris'] for v in stats.values()))
