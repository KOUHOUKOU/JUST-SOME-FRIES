"""S5 cover people. Flat facets, round dot-eyed heads, nine original rig parts.

Blender --background --threads 4 --python tools/blender/person.py -- --iteration 1
Mesh coordinates are pivot-local; animation and style keys belong to human_rig.
The old smooth generator is retained in archive/person_smooth_pre_s5.py.
"""
import sys, math, json, argparse
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector, Matrix
import common as C

ap=argparse.ArgumentParser();ap.add_argument('--iteration',type=int,choices=range(1,5),default=1)
ap.add_argument('--no-render',action='store_true')
args=ap.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
folder=Path(f'art_src/s5/iteration_{args.iteration}/blender')
scene=C.clean_scene();mat=C.vertex_material('CoverPerson');parts={};groups={}
REF=['FFFFFF','E3B590','8C8F96','4B5566','3A2A20','3A3330','3D8CD9','C65A3A','E8573A','D89A8E','F4F1E8']
G=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
def b(p):return G@Vector(p)
def g(p):return G.transposed()@p

def paint(ob,group,region=0,col=None):
    C.activate(ob);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
    m=ob.data;m.materials.clear();m.materials.append(mat)
    ca=m.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='CORNER');m.color_attributes.active_color=ca;m.color_attributes.render_color_index=0
    uv=m.uv_layers.active or m.uv_layers.new();uv.name='TintRegion'
    base=C.linear_rgb(col or REF[region])
    for face in m.polygons:
        face.use_smooth=False
        # Tiny, face-constant pigment variation: the normals provide the facets.
        rgb=base*(1-((face.index*7)%5)*.004)
        for i in face.loop_indices:ca.data[i].color=(*rgb,1);uv.data[i].uv=(region/15,0)
    groups.setdefault(group,[]).append(ob)
    return ob

def mesh(group,verts,faces,region=0,col=None):
    m=bpy.data.meshes.new(group);m.from_pydata([b(v) for v in verts],[],faces);m.update()
    o=bpy.data.objects.new(group,m);scene.collection.objects.link(o);return paint(o,group,region,col)

def egg(group,c,r,region,n=12,rings=6,col=None):
    v=[(c[0],c[1]+r[1],c[2])]
    for j in range(1,rings):
        a=math.pi*j/rings
        for k in range(n):
            q=math.tau*k/n+math.pi/n
            v.append((c[0]+r[0]*math.sin(a)*math.cos(q),c[1]+r[1]*math.cos(a),c[2]+r[2]*math.sin(a)*math.sin(q)))
    v.append((c[0],c[1]-r[1],c[2]));f=[(0,1+k,1+(k+1)%n) for k in range(n)]
    for j in range(rings-2):
        for k in range(n):
            a=1+j*n+k;d=1+j*n+(k+1)%n;f.append((a,a+n,d+n,d))
    for k in range(n):f.append((len(v)-1,1+(rings-2)*n+(k+1)%n,1+(rings-2)*n+k))
    return mesh(group,v,f,region,col)

def box(group,c,size,bevel,region=0,col=None):
    bpy.ops.mesh.primitive_cube_add(size=1);o=bpy.context.object;o.scale=(size[0],size[2],size[1]);C.activate(o)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('SingleFacetCorners','BEVEL');mod.width=bevel;mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for ve in o.data.vertices:ve.co+=b(c)
    return paint(o,group,region,col)

# Head diameter .66 m / total bare height 2.04 m = 32.4%, nearly one third.
# Lower shirt hem masks the top of the original hip pivots, shortening the legs
# visually without moving the seat, walk, hand or collision reference points.
box('Torso',(0,.275,0),(.59,.76,.43),.105,2)
egg('Torso',(0,.64,0),(.10,.10,.10),1,8,4)
for side,suf in [(-1,'L'),(1,'R')]:
    # The sleeve ends in a broad mitten, whose palm contains the held-item socket.
    box('Arm'+suf,(0,-.235,0),(.215,.51,.225),.065,2)
    egg('Arm'+suf,(0,-.55,.025),(.105,.12,.105),1,8,4)
    egg('Arm'+suf,(-side*.075,-.53,.065),(.046,.068,.055),1,6,3)
    box('Leg'+suf,(side*.033,-.365,0),(.235,.76,.245),.05,3)
    box('Leg'+suf,(side*.036,-.777,.075),(.26,.14,.36),.045,5)
egg('Head',(0,.09,0),(.33,.33,.302),1,12,7)
for side,suf in [(-1,'L'),(1,'R')]:
    # Original eye transforms stay fixed; offsets are baked in mesh space.
    x=side*.035;y=-.087;z=.121
    verts=[(x,y,z)]+[(x+.019*math.cos(k*math.tau/10),y+.020*math.sin(k*math.tau/10),z-.003) for k in range(10)]
    mesh('Eye'+suf,verts,[(0,k+1,(k+1)%10+1) for k in range(10)],0,'08090C')
# Keep the mouth emote interface and ninth surface, fully buried in the skull.
# Cover people have no drawn mouth, cheeks, catchlight, eyebrows or ears.
mesh('Mouth',[(-.001,0,-.16),(.001,0,-.16),(0,.001,-.16)],[(0,1,2)],1)

def hair(kind):
    n=12;rings=4;v=[(0,.453,-.012)]
    for j in range(1,rings+1):
        for k in range(n):
            a=k*math.tau/n+math.pi/n;front=max(0,math.sin(a))
            theta=(1.88-.70*front)*j/rings
            # Broad, quiet facets; the asymmetry is in the hairline, not strands.
            y=.09+.365*math.cos(theta)
            if j==rings:y+=.02*math.cos(a*2+.6)*front
            if kind=='long' and j==rings:y-=.23*(1-front)
            v.append((.350*math.sin(theta)*math.cos(a),y,-.012+.326*math.sin(theta)*math.sin(a)))
    f=[(0,1+k,1+(k+1)%n) for k in range(n)]
    for j in range(rings-1):
        for k in range(n):
            a=1+j*n+k;d=1+j*n+(k+1)%n;f.append((a,d,d+n,a+n))
    v.append((0,.07,0));c=len(v)-1;start=1+(rings-1)*n
    for k in range(n):f.append((c,start+(k+1)%n,start+k))
    reg=6 if kind in ['cap','sunhat','beanie'] else 4;name='Hair_'+kind
    mesh(name,v,f,reg)
    if kind=='bun':egg(name,(0,.37,-.27),(.115,.12,.12),4,8,4)
    if kind=='cap':box(name,(0,.235,.30),(.48,.04,.30),.035,6)
    if kind=='sunhat':egg(name,(0,.19,0),(.47,.055,.43),6,12,3)
    if kind=='beanie':egg(name,(0,.47,-.015),(.065,.065,.065),6,8,4)
for kind in ['short','long','bun','cap','beanie','sunhat']:hair(kind)

# A tapered bib flows into a flared skirt, following the shirt's lower bevel.
v=[]
for zoff in [0,.013]:
    for y,rx,z in [(.535,.107,.253),(.29,.155,.253),(.15,.206,.253),(-.055,.228,.253)]:
        for x in [-rx,0,rx]:v.append((x,y,z+zoff))
f=[]
for layer in [0,12]:
    for j in range(3):
        for k in range(2):
            q=layer+j*3+k;f.append((q,q+1,q+4,q+3))
for edge in [0,2]:
    for j in range(3):q=j*3+edge;f.append((q,q+3,q+15,q+12))
for q in [0,1,9,10]:f.append((q,q+12,q+13,q+1))
mesh('Apron',v,f,10)
# Flat cloth tie follows the perimeter; no protruding bevelled belt blocks.
tie=[(.205,.251),(.32,.126),(.32,-.126),(.20,-.251),(-.20,-.251),(-.32,-.126),(-.32,.126),(-.205,.251)]
verts=[(x,y,z) for y in [.13,.175] for x,z in tie]
mesh('Apron',verts,[(k,(k+1)%8,(k+1)%8+8,k+8) for k in range(8)],10)
for side in [-1,1]:
    # Shoulder ribbons fold across the rounded top, not upright white pegs.
    pts=[]
    for y,z in [(.47,.259),(.55,.243),(.64,.15),(.667,.07),(.667,-.07),(.61,-.185)]:
        for dx in [-.019,.019]:pts.append((side*.103+dx,y,z))
    mesh('Apron',pts,[(2*k,2*k+1,2*k+3,2*k+2) for k in range(5)],10)
    box('Pack',(side*.15,.32,.221),(.038,.53,.026),.008,7)
    box('Pack',(side*.15,.599,0),(.038,.035,.43),.008,7)
box('Pack',(0,.28,-.278),(.37,.48,.18),.065,7)
# Open vest shell, inset edges, no floating sticker and no full box hiding shirt.
v=[]
outline=[(.087,.238),(.19,.238),(.312,.116),(.312,-.116),(.19,-.238),(-.19,-.238),(-.312,-.116),(-.312,.116),(-.19,.238),(-.087,.238)]
for y,fac in [(-.118,.62),(-.007,1),(.55,1),(.673,.62)]:
    for x,z in outline:v.append((x*fac,y,z*fac))
f=[]
for j in range(3):
    for k in range(9):f.append((j*10+k,j*10+k+1,(j+1)*10+k+1,(j+1)*10+k))
mesh('Vest',v,f,8)
# Optional inherited glasses: fine frames around the same dots, not painted eyes.
for side in [-1,1]:
    x=side*.125
    for dx in [-.057,.057]:box('Glasses',(x+dx,.113,.284),(.014,.085,.018),0,0,'272832')
    for dy in [-.043,.043]:box('Glasses',(x,.113+dy,.284),(.12,.014,.018),0,0,'272832')
box('Glasses',(0,.126,.285),(.14,.014,.018),0,0,'272832')

for name,objects in groups.items():
    C.activate(objects[0])
    for o in objects:o.select_set(True)
    if len(objects)>1:bpy.ops.object.join()
    o=bpy.context.object;o.name=name;o.data.materials.clear();o.data.materials.append(mat)
    for f in o.data.polygons:f.material_index=0;f.use_smooth=False
    parts[name]=o
base=['Torso','ArmL','ArmR','LegL','LegR','Head','EyeL','EyeR','Mouth']
counts={n:C.triangle_count([o]) for n,o in parts.items()}
maximum=sum(counts[n] for n in base)+max(counts[n] for n in parts if n.startswith('Hair_'))+sum(counts[n] for n in ['Apron','Pack','Vest','Glasses'])
assert maximum<=1800,(counts,maximum)
path=C.export_glb(list(parts.values()),'game/assets/models/person_parts.glb',texcoords=True)
stats={'parts_triangles':counts,'base_triangles':sum(counts[n] for n in base),'max_style_triangles':maximum,'draw_parts':9,'materials':1,'flat_faces':all(not f.use_smooth for o in parts.values() for f in o.data.polygons),'bytes':path.stat().st_size,'head_height_ratio':.66/2.04}
C.output_path(folder/'stats.json').write_text(json.dumps(stats,indent=2))
print('[S5 PERSON]',stats)
if args.no_render:sys.exit(0)
positions={'Torso':(0,.85,0),'ArmL':(-.35,1.40,0),'ArmR':(.35,1.40,0),'LegL':(-.11,.85,0),'LegR':(.11,.85,0),'Head':(0,1.62,0),'EyeL':(-.09,1.82,.16),'EyeR':(.09,1.82,.16),'Mouth':(0,1.665,.17)}
for n,o in parts.items():
    p=positions.get(n,(0,1.62,0) if n.startswith('Hair_') or n=='Glasses' else (0,.85,0))
    o.location=b(p);o.hide_render=n not in base+['Hair_short']
visible=[o for o in parts.values() if not o.hide_render]
bpy.context.view_layer.update()
paths=C.render_turntable(visible,folder/'turntable',resolution=320,samples=8,framing=1.16)
C.contact_sheet(paths,folder/'turntable/contact.png')
