"""Pivot-local clay person and seven existing hair/hat choices; no skeleton/animation."""
import sys,json,math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent.parent))
import bpy
from mathutils import Vector
import common as C
import p1b_common as P
it=int(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else 1
folder=Path(f'art_src/p1b_review2/iteration_{it}/person');C.clean_scene();parts={}
REF=['FFFFFF','E3B590','8C8F96','4B5566','3A2A20','3A3330','3D8CD9','C65A3A','E8573A','D89A8E','F4F1E8']
def egg(n,c,r,region,segs=8,rings=4):return P.ellipsoid(n,c,r,REF[region],segs,rings,region)
def group(name,objs):
 def paint(ob,p):
  return C.linear_rgb(ob['colour'])*(.72 if ob.get('cuff',False) and P.g(p).y<-.435 else 1)
 o,_=P.finish(objs,name,folder/'source_parts'/f'{name}.glb',paint);parts[name]=o;return o
# Torso is pivot-local to upper/torso, y=.85 in the existing rig.
body=egg('Shirt',(0,.31,0),(.273,.34,.229),2,12,6)
for v in body.data.vertices:
 p=P.g(v.co);p.x*=1+.045*math.cos((p.y-.15)*23);p.z*=1+.035*math.cos(p.y*27);v.co=P.b(p)
group('Torso',[body,egg('Neck',(0,.65,0),(.10,.10,.10),1,6,4)])
for side,label in [(-1,'L'),(1,'R')]:
 sleeve=P.lathe('Sleeve',[(.025,.025),(-.035,.115),(-.18,.105),(-.35,.079),(-.46,.081),(-.48,.078)],8,REF[2],region=2);sleeve['cuff']=True
 for vert in sleeve.data.vertices:
  p=P.g(vert.co);p.x-=side*.12*max(0,min(1,(p.y+.20)/.245));vert.co=P.b(p)
 group('Arm'+label,[sleeve,egg('Hand',(0,-.575,.005),(.079,.087,.075),1,6,4)])
 leg=P.lathe('Trouser',[(0,.06),(-.10,.125),(-.30,.118),(-.60,.083),(-.75,.085)],8,REF[3],centre=(side*.02,0,0),region=3)
 group('Leg'+label,[leg,egg('Shoe',(side*.025,-.791,.049),(.12,.055,.175),5,8,4)])
head=[egg('Head',(0,.12,0),(.265,.33,.17),1,18,8),egg('Nose',(0,.15,.176),(.036,.04,.04),1,6,4)]
for side in [-1,1]:
 head.append(egg('Ear',(.257*side,.12,-.015),(.038,.058,.036),1,6,3))
 head.append(egg('Blush',(.163*side,.105,.138),(.035,.025,.003),9,6,3))
group('Head',head)
for label in ['L','R']:
 eye=P.ellipsoid('Eye',(0,0,0),(.024,.028,.013),'20202A',8,4)
 glint=P.mesh('Catchlight',[(-.007,.015,.011),(.001,.015,.011),(-.003,.019,.012),(-.003,.011,.014)],[(0,1,2),(0,3,1)],'FFF7E5')
 group('Eye'+label,[eye,glint])
group('Mouth',[P.ellipsoid('Mouth',(0,0,0),(.029,.011,.009),'76483C',6,3)])

def hair(kind):
 verts=[(0,.502,-.015)];sides=16;rings=5
 for j in range(1,rings+1):
  for k in range(sides):
   az=k*math.tau/sides;front=max(0,math.sin(az));theta=(1.80-.58*front)*j/rings
   x=.302*math.sin(theta)*math.cos(az);y=.12+.382*math.cos(theta);z=-.015+.216*math.sin(theta)*math.sin(az)
   if kind=='long' and j==rings:y-=.18*(1-front);z-=.022*(1-front)
   if kind=='beanie':y+=.025
   verts.append((x,y,z))
 faces=[(0,1+k,1+(k+1)%sides) for k in range(sides)]
 for j in range(rings-1):
  for k in range(sides):
   a=1+j*sides+k;n=1+j*sides+(k+1)%sides;faces.append((a,n,n+sides,a+sides))
 # Hair is a closed mass with its bottom cap buried inside the skull.
 outer=1+(rings-1)*sides;inner=len(verts)
 for k in range(sides):
  x,y,z=verts[outer+k];verts.append((x*.76,.12+(y-.12)*.76,z*.76))
 for k in range(sides):faces.append((outer+k,outer+(k+1)%sides,inner+(k+1)%sides,inner+k))
 faces.append(tuple(reversed(range(inner,inner+sides))))
 region=6 if kind in ['cap','sunhat','beanie'] else 4
 objs=[P.mesh('Hair',verts,faces,REF[region],region)]
 if kind=='bun':objs.append(egg('Bun',(0,.410,-.19),(.105,.10,.09),4,8,4))
 if kind=='cap':objs.append(P.panel('Bill',(0,.257,.18),(.34,.035,.22),REF[6],.015,6))
 if kind=='sunhat':objs.append(P.lathe('Brim',[(.24,.29),(.26,.37),(.285,.29)],10,REF[6],region=6))
 if kind=='beanie':objs.append(egg('Pom',(0,.49,-.02),(.056,.056,.056),6,6,3))
 group('Hair_'+kind,objs)
for kind in ['short','bun','long','cap','beanie','sunhat']:hair(kind)
def strap(name,side,region,start=.70,end=3.0):
 verts=[]
 for j in range(7):
  a=start+(end-start)*j/6
  for dx in [-.021,.021]:
   x=side*.107+dx;f=math.sqrt(1-(x/.283)**2)
   verts.append((x,.31+.365*f*math.sin(a),.279*f*math.cos(a)))
 return P.mesh(name,verts,[(2*j,2*j+1,2*j+3,2*j+2) for j in range(6)],REF[region],region)

# A closed, curved bib: rounded bevel edge and a centre fan follow the belly.
bib=P.panel('Bib',(0,.35,0),(.33,.46,.014),REF[10],.035,10)
verts=[P.g(v.co) for v in bib.data.vertices]
for p in verts:
 p.x*=1-.24*max(0,(p.y-.12)/.46)
 p.z+=.265*math.sqrt(max(.01,1-(p.x/.281)**2-((p.y-.31)/.352)**2))+.025
faces=[tuple(f.vertices) for f in bib.data.polygons if len(f.vertices)==4]
for offset in [0,12]:
 centre=Vector((0,.35,.265*math.sqrt(1-(.04/.352)**2)+.025+(-.007 if offset==0 else .007)))
 c=len(verts);verts.append(centre)
 for j in range(12):faces.append((c,offset+j,offset+(j+1)%12))
bpy.data.objects.remove(bib,do_unlink=True)
bib=P.mesh('Bib',verts,faces,REF[10],10)
band=P.lathe('Waistband',[(.13,1),(.185,1)],12,REF[10],region=10)
for v in band.data.vertices:
 p=P.g(v.co);p.x*=.278;p.z*=.245;v.co=P.b(p)
group('Apron',[bib,band]+[strap('ApronStrap',s,10) for s in [-1,1]])
group('Pack',[egg('Pack',(0,.35,-.285),(.17,.22,.10),7,8,5)]+[strap('PackStrap',s,7,-.5,3.4) for s in [-1,1]])

# Open-front garment shell fits around the torso, with its folded edges buried.
verts=[]
for y,rx,rz in [(.02,.165,.141),(.16,.259,.223),(.44,.263,.226),(.60,.159,.14)]:
 for j in range(11):
  a=.43+(math.tau-.86)*j/10;verts.append((rx*1.13*math.sin(a),y,rz*1.13*math.cos(a)))
faces=[(j*11+k,j*11+k+1,(j+1)*11+k+1,(j+1)*11+k) for j in range(3) for k in range(10)]
for edge in [0,10]:
 ids=[]
 for j in range(4):
  x,y,z=verts[j*11+edge];ids.append(len(verts));verts.append((x*.94,y,z*.92))
 for j in range(3):faces.append((j*11+edge,(j+1)*11+edge,ids[j+1],ids[j]))
group('Vest',[P.mesh('Vest',verts,faces,REF[8],8)])

glasses=[]
for side in [-1,1]:glasses.append(P.panel('Lens',(.09*side,.2,.174),(.085,.065,.015),'3A3D48',.014))
glasses.append(P.box('Bridge',(0,.203,.174),(.10,.009,.012),'3A3D48'))
group('Glasses',glasses)
mat=C.vertex_material('PersonClay')
for o in parts.values():o.data.materials.clear();o.data.materials.append(mat)
C.export_glb(list(parts.values()),'game/assets/models/person_parts.glb',texcoords=True)
base_names=['Torso','ArmL','ArmR','LegL','LegR','Head','EyeL','EyeR','Mouth']
counts={n:C.triangle_count([o]) for n,o in parts.items()};maximum=sum(counts[n] for n in base_names)+max(counts[n] for n in parts if n.startswith('Hair_'))+sum(counts[n] for n in ['Apron','Pack','Vest','Glasses'])
assert maximum<=1800,maximum
stats={'parts_triangles':counts,'base_triangles':sum(counts[n] for n in base_names),'max_style_triangles':maximum,'draw_parts':9,'material':1}
C.output_path(folder/'stats.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')

positions={'Torso':(0,.85,0),'ArmL':(-.35,1.40,0),'ArmR':(.35,1.40,0),'LegL':(-.11,.85,0),'LegR':(.11,.85,0),'Head':(0,1.62,0),'EyeL':(-.09,1.82,.16),'EyeR':(.09,1.82,.16),'Mouth':(0,1.665,.17)}
for n in parts:
 if n.startswith('Hair_') or n=='Glasses':positions[n]=(0,1.62,0)
 if n in ['Apron','Pack','Vest']:positions[n]=(0,.85,0)
 for o in [parts[n]]:o.location=P.b(positions[n])
P.turn([parts[n] for n in base_names+['Hair_short']],folder/'turntable')
styles=[{'skin':'E3B590','shirt':'879B82','pants':'4B5566','hair_style':'short'},
 {'skin':'C98F65','shirt':'D96D5F','pants':'596A80','hair_style':'bun','apron':True},
 {'skin':'7A4B33','shirt':'D9B25F','pants':'3A3F4A','hair_style':'long','backpack':True},
 {'skin':'F0C6A0','shirt':'7396A8','pants':'586169','hair_style':'cap','hat':'B97967','scale':.7},
 {'skin':'B98762','shirt':'E8E2D2','pants':'4B5566','hair_style':'bald','glasses':True,'vest':True,'fat':1.2},
 {'skin':'E3B590','shirt':'9EA9BC','pants':'4B5566','hair_style':'beanie','hat':'D5B574'},
 {'skin':'C98F65','shirt':'C9A6A5','pants':'596A60','hair_style':'sunhat','hat':'D8C69B'},
 {'skin':'F0C6A0','shirt':'9AB6AD','pants':'6E5E53','hair_style':'bun','hair':'8A725B','backpack':True,'fat':1.1}]
C.output_path('art_src/p1b/cast_styles.json').write_text(json.dumps(styles,indent=2),encoding='utf-8')
cast=[]
for i,st in enumerate(styles):
 names=base_names.copy();hs=st.get('hair_style','short')
 if hs!='bald':names+=['Hair_'+hs]
 for key,part in [('apron','Apron'),('vest','Vest'),('backpack','Pack'),('glasses','Glasses')]:
  if st.get(key):names.append(part)
 target=REF.copy()
 for region,key in [(1,'skin'),(2,'shirt'),(3,'pants'),(4,'hair'),(5,'shoes'),(6,'hat'),(7,'pack_color'),(8,'vest_color')]:target[region]=st.get(key,REF[region])
 for n in names:
  src=parts[n];o=src.copy();o.data=src.data.copy();bpy.context.scene.collection.objects.link(o);o.hide_render=False
  c=o.data.color_attributes.active_color;uv=o.data.uv_layers.active
  for k in range(len(c.data)):
   r=round(uv.data[k].uv.x*15);rgb=c.data[k].color[:];wanted=C.linear_rgb(target[r]);ref=C.linear_rgb(REF[r]);c.data[k].color=(*[rgb[j]*wanted[j]/max(ref[j],.001) for j in range(3)],1)
  if n in ['Torso','Vest','Apron','Pack']:
   for v in o.data.vertices:
    p=P.g(v.co);p.x*=st.get('fat',1);p.z*=st.get('fat',1);v.co=P.b(p)
  sc=st.get('scale',1);o.scale=(sc,sc,sc);o.location=P.b(Vector(positions[n])*sc+Vector(((i%4-1.5)*1.25,(i//4)*2.6,0)));cast.append(o)
P.cast(cast,folder/'eight_styles.png',width=512,height=470,scale=6.2)
print('[P1B PERSON]',stats)
