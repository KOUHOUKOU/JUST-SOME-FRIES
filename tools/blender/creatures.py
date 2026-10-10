"""P2 dog pivots and the nine existing fish identities; no rigs or animation."""
import sys,math,json,re
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
folder=Path(f'art_src/p2_review2/iteration_{it}/creatures' if review2 else f'art_src/p2/iteration_{it}/creatures');C.clean_scene();stats={}
def egg(n,c,r,col='B98B61',s=10,q=5,region=0):return P.ellipsoid(n,c,r,col,s,q,region)
dog={}
groups={'Body':[egg('Body',(0,.43,0),(.23,.23,.49),region=1),egg('Bib',(0,.46,.375),(.17,.18,.10),'E3D4BB',8,4)],
 'Head':[egg('Skull',(0,0,0),(.195,.182,.199),region=1),egg('Muzzle',(0,-.07,.19),(.13,.09,.125),'E9D8B9'),egg('Nose',(0,-.028,.294),(.05,.034,.031),'494048',8,4)],
 'Tail':[egg('Tail',(0,.065,.005),(.069,.18,.10),region=1)],
 'Leg':[egg('Leg',(0,.059,0),(.086,.209,.089),region=1),egg('Paw',(0,-.088,.031),(.082,.056,.104),'E3D4BB',8,4)]}
for side in [-1,1]:
 groups['Head'] += [egg('Ear',(side*.189,-.031,-.01),(.066,.159,.099),'765843',8,5),egg('Eye',(side*.092,.039,.174),(.029,.034,.019),'38333D',8,4),egg('Glint',(side*.086,.052,.188),(.008,.010,.004),'F9EBD5',5,3)]
for name,objs in groups.items():dog[name]=P.finish(objs,name,folder/'parts'/f'dog_{name}.glb')[0]
if not review2:C.export_glb(list(dog.values()),'game/assets/models/dog_parts.glb',texcoords=True)
total=C.triangle_count([dog['Body'],dog['Head'],dog['Tail']])+4*C.triangle_count([dog['Leg']]);assert total<=1200,total
stats['dog']={'tris':total,'draws':7}
dog['Head'].location=P.b((0,.62,.52));dog['Tail'].location=P.b((0,.6,-.45))
posed=[dog['Body'],dog['Head'],dog['Tail']]
for x in [-.14,.14]:
 for z in [-.3,.3]:
  o=dog['Leg'].copy();o.data=dog['Leg'].data.copy();bpy.context.scene.collection.objects.link(o);o.location=P.b((x,.13,z));posed.append(o)
if not review2:P.turn(posed,folder/'dog')

species=['sardine','mackerel','herring','mullet','flyer','bass','tuna','opah','marlin']
size=[(.16,.20,.85),(.18,.22,.9),(.14,.25,.85),(.20,.26,.8),(.16,.18,.85),(.22,.30,.9),(.30,.36,.95),(.11,.62,.72),(.20,.26,1)]
bodycol=['69AABC','347FA7','6485AC','E75842','2864CD','3E7E65','D7A642','CE365B','16A7C5']
bellycol=['F4FAF9','F9F5DE','F8F3ED','FFE8CF','E7F4FF','F3F1D9','FFF0C7','FFE0E4','E9FDFF']
fishcast=[]
for i,sp in enumerate(species):
 x,y,z=size[i];col=bodycol[i];belly=bellycol[i]
 body=[egg('Fish',(0,0,0),(x*.56,y*.57,z*.52),col,14,8)]
 for side in [-1,1]:
  body += [egg('Eye',(x*.43*side,y*.16,-z*.32),(.018,.025,.027),'333640',8,4),egg('Glint',((x*.43+.018)*side,y*.20,-z*.33),(.005,.011,.012),'FFFAE8',5,3)]
 body.append(egg('Mouth',(0,-y*.07,-z*.50),(x*.20,.012,.015),'806668',6,3))
 body.append(egg('Dorsal',(0,y*.55,.03),(.018,y*.32,z*.18),'8F9D9F',8,4))
 tail=[egg('Tail', (0,side*y*.37,z*.59),(.025,y*.47,z*.14),col,8,4) for side in [-1,1]]
 if sp=='flyer':
  for side in [-1,1]:body.append(egg('Wing',(side*.22,.012,-.03),(.25,.018,.14),'ACCEE3',8,4))
 if sp=='marlin':
  body.append(egg('Bill',(0,0,-.64),(.024,.025,.23),'719CA6',8,4));body.append(egg('Sail',(0,.21,-.08),(.015,.21,.27),'557FAF',8,4))
 if sp=='tuna':
  for j in range(3):body.append(egg('Finlet',(0,y*.25,.38+j*.05),(.012,.05,.02),'B79E68',5,3))
 def paint(o,p):
  pp=P.g(p);c=C.linear_rgb(o['colour'])
  if o.name.startswith('Fish'):
   if sp=='mackerel' and pp.y>0 and math.cos(pp.z*65+pp.y*17)>.20:c*=.53
   if sp=='opah' and math.sin(pp.y*44)*math.cos(pp.z*39)>.65:c=c.lerp(C.linear_rgb('F1C7C4'),.7)
   if sp=='mullet' and abs(pp.y)<.023:c=c.lerp(C.linear_rgb('D9B47C'),.6)
   # Paint the belly on the body itself: no intersecting pale shell or ragged seam.
   c=c.lerp(C.linear_rgb(belly),min(.95,max(0,-pp.y/y-.10)*3.0))
   # Broad painted shoulder sheen survives the matte shared toon material.
   sheen=max(0,1-abs(pp.y/y-.28)/.20)*.24
   c=c.lerp(C.linear_rgb(belly),sheen)
  return c
 parts=[P.finish(body,'Body',folder/'parts'/f'{sp}_body.glb',paint)[0],P.finish(tail,'Tail',folder/'parts'/f'{sp}_tail.glb')[0]]
 # Tail vertices are authored relative to the old mesh pivot; preserve its rotation animation.
 pivot=Vector((0,0,z*.55+.08))
 for v in parts[1].data.vertices:v.co=P.b(Matrix.Rotation(-math.pi/2,3,'X')@(P.g(v.co)-pivot))
 parts[1].rotation_euler=(P.G@Matrix.Rotation(math.pi/2,3,'X')@P.G.transposed()).to_euler()
 parts[1].location=P.b(pivot)
 C.export_glb(parts,f'game/assets/models/fish_{sp}.glb',texcoords=True)
 # The loader uses zero transform meshes and restores this same position.
 count=C.triangle_count(parts);stats[sp]={'tris':count,'draws':2,'tail_pivot':list(pivot)}
 for src in parts:
  o=src.copy();o.data=src.data.copy();bpy.context.scene.collection.objects.link(o)
  if review2:
   rot=(P.G@Matrix.Rotation(math.pi/2,3,'Y')@P.G.transposed()).to_4x4()
   o.matrix_world=Matrix.Translation(P.b(((i%3-1)*.85,(i//3)*.50,0)))@rot@src.matrix_world
  else:o.location+=P.b(((i%3-1)*.85,(i//3)*.50,0))
  fishcast.append(o)
if review2:P.cast(fishcast,folder/'fish_cast.png',512,300,3.1)
else:P.turn(fishcast,folder/'fish')
C.output_path(folder/'stats.json').write_text(json.dumps(stats,indent=2));print('[P2 CREATURES]',stats)
