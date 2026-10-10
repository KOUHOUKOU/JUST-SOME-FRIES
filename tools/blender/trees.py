"""Five deterministic, one-surface tree variants. Wind weight lives in COLOR_0 alpha."""
import sys,json,math,random
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector
import common as C
import p1b_common as P
it=int(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else 1
folder=Path(f'art_src/p1b_review2/iteration_{it}/trees');C.clean_scene();objects=[];stats={}
for kind in ['leaf','pine']:
 for v in range(3 if kind=='leaf' else 2):
  name=f'tree_{kind}_{v}';pieces=[];rng=random.Random(420+v)
  if kind=='leaf':
   trunk=P.lathe('Trunk',[(0,.48),(.30,.29),(3.8,.21),(6.3,.11)],6,'775034')
   for vert in trunk.data.vertices:
    p=P.g(vert.co);p.x+=.12*math.sin(p.y*.42);vert.co=P.b(p)
   pieces.append(trunk)
   for side in [-1,1]:
    start=Vector((.10,4.05,0));end=Vector((side*.98,5.85,.15));axis=end-start
    branch=P.lathe('Fork',[(0,.14),(axis.length,.075)],6,'775034')
    rotation=Vector((0,1,0)).rotation_difference(axis.normalized())
    for vert in branch.data.vertices:vert.co=P.b(start+rotation@P.g(vert.co))
    pieces.append(branch)
   lobes=[
    [((-1.0,6.85,-.1),(1.50,1.50,1.55)),((1.0,6.7,-.2),(1.5,1.45,1.55)),((0,6.2,1.0),(1.55,1.35,1.5)),((0,7.2,-1.0),(1.55,1.45,1.5))],
    [((0,7.30,0),(1.40,1.35,1.35)),((-.80,6.35,-.2),(1.2,1.48,1.2)),((.80,6.10,.2),(1.25,1.45,1.2)),((0,5.65,.90),(1.05,1.08,1.05))],
    [((-1.45,6.80,-.15),(1.55,1.1,1.55)),((1.45,6.8,-.1),(1.55,1.1,1.55)),((0,7.35,-1.0),(1.8,1.3,1.4)),((0,6.55,1.1),(1.9,1.05,1.45))]
   ][v]
   for i,(centre,radii) in enumerate(lobes):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=13,ring_count=5,radius=1);o=bpy.context.object
    for vert in o.data.vertices:
     p=P.g(vert.co);bump=1+.020*math.sin(p.x*4+v)*math.cos(p.z*4+.8)
     vert.co=P.b(Vector(centre)+Vector([p[j]*radii[j]*bump for j in range(3)]))
    P.register(o,'Crown','6DBE6A',1);o['cy']=centre[1];o['ry']=radii[1];o['shade']=1-.035*(i%3)
    pieces.append(o)
  else:
   pieces.append(P.lathe('Trunk',[(0,.36),(.3,.26),(7.3,.15)],5,'684832'))
   for k in range(4):
    r=(2.6-k*.5)*(1 if v==0 else .94)
    tier=P.lathe('Tier',[(-1.5,r*.74),(-1.30,r),(-.98,r*.97),(.20,r*.48),(1.5,.04)],11,'408955',centre=(.08*math.sin(k),2.5+k*2,0),scallop=.045,region=1)
    tier['cy']=2.5+k*2;tier['ry']=1.5;tier['shade']=.93+.025*k;pieces.append(tier)
  def paint(o,p):
   y=P.g(p).y
   if o.name.startswith(('Trunk','Fork')):return C.linear_rgb('684832').lerp(C.linear_rgb('A27848'),min(1,y/7)*.60)
   t=max(0,min(1,(y-o['cy']+o['ry'])/(2*o['ry'])))
   low,mid,top=('296D49','47A64C','A3CD58') if kind=='leaf' else ('245846','398653','70AC67')
   split=.82 if kind=='leaf' else .68
   colour=C.linear_rgb(low).lerp(C.linear_rgb(mid),min(1,t/split)) if t<split else C.linear_rgb(mid).lerp(C.linear_rgb(top),(t-split)/(1-split))
   return colour*o['shade']
  ymax=max(P.g(v.co).y for o in pieces for v in o.data.vertices)
  ob,ao=P.finish(pieces,name,f'game/assets/models/{name}.glb',paint,lambda o,p:max(0,min(1,(p.y-.1)/(ymax-.1))))
  tris=C.triangle_count([ob]);assert tris<=(500 if kind=='leaf' else 450),(name,tris)
  objects.append(ob);stats[name]={'tris':tris,'parts':1,'materials':1,'ao':ao}
# Canonical deciduous and pine turntables; all five seeded forms on the cast sheet.
P.turn([objects[0]],folder/'leaf_turntable');P.turn([objects[3]],folder/'pine_turntable')
for i,o in enumerate(objects):o.location=P.b(((i-2)*6.2,0,0))
P.cast(objects,folder/'five_variants.png',scale=32,height=260)
C.output_path(folder/'stats.json').write_text(json.dumps(stats,indent=2),encoding='utf-8')
print('[P1B TREES]',{k:v['tris'] for k,v in stats.items()})
