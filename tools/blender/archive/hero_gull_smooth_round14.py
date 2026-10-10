"""P1a reproducible clay gull. Godot coordinates in the authoring helpers.

blender --background --threads 4 --python tools/blender/hero_gull.py -- --iteration 3
UV.x carries a discrete recolour region (0..7 / 7), with no texture sampling.
COLOR_0 contains opaque baked RGB. All surfaces share one material.
"""
import sys
import math
import json
import argparse
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector, Matrix
import common as C

parser = argparse.ArgumentParser()
parser.add_argument('--iteration', type=int, choices=[1,2,3], default=3)
parser.add_argument('--review', choices=['none','poses'], default='poses')
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
folder = Path(f'art_src/p1a_review2/iteration_{args.iteration}/blender')
scene = C.clean_scene()
mat = C.vertex_material('GullClay')
groups = {}
palette = {k: C.linear_rgb(v) for k, v in dict(cream='F7F1E6', lilac='D8CFE6',
    mantle='B9C3D1', fade='B7B2C9', tip='3A3D48', beak='F5B53A',
    dot='E2503A', feet='F28A52', eye='171923', nostril='AD783B').items()}
# Godot +Y up, -Z front -> Blender +Z up, +Y front.
G = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
def b(p): return G @ Vector(p)
def g(p): return G.transposed() @ p

def register(obj, group, colour, region):
    obj['paint'] = colour
    obj['region'] = region
    obj.data.materials.append(mat)
    groups.setdefault(group, []).append(obj)
    C.smooth(obj, weighted=False)
    return obj

def egg(group, centre, radii, colour, region=0, segments=12, rings=8, tilt=0):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1)
    obj = bpy.context.object
    # Bake coordinates into the mesh, leaving an identity transform for AO.
    rot = Matrix.Rotation(tilt, 3, 'Y')
    for v in obj.data.vertices:
        p = g(v.co)
        p = Vector([p[i] * radii[i] for i in range(3)])
        v.co = b(Vector(centre) + rot @ p)
    return register(obj, group, colour, region)

def feather(group, start, end, width, thickness, region, tail=False):
    start, end = Vector(start), Vector(end)
    axis = (end-start).normalized()
    sideways = Vector((-axis.z, 0, axis.x)).normalized()
    verts = [b(start)]
    rings, sides = 5, 8
    for j in range(1, rings+1):
        t = ((0.03, 0.13, 0.45, 0.83, 0.97) if tail else (0.03, 0.13, 0.59, 0.70, 0.97))[j-1]
        cap = min(t, 1-t)
        profile = math.sqrt(max(0, 1-((cap-.14)/.14)**2)) if cap < .14 else 1.0
        p = start.lerp(end, t) + Vector((0, .014*math.sin(math.pi*t), 0))
        for k in range(sides):
            a = k*math.tau/sides
            verts.append(b(p + sideways*(math.cos(a)*width*profile) + Vector((0, math.sin(a)*thickness*profile, 0))))
    verts.append(b(end))
    faces = []
    for k in range(sides):
        faces.append((0, 1+(k+1)%sides, 1+k))
    for j in range(rings-1):
        for k in range(sides):
            a = 1+j*sides+k; d = 1+j*sides+(k+1)%sides
            faces.append((a, d, d+sides, a+sides))
    for k in range(sides):
        faces.append((1+(rings-1)*sides+k, 1+(rings-1)*sides+(k+1)%sides, len(verts)-1))
    mesh=bpy.data.meshes.new(group+'Feather');mesh.from_pydata(verts, [], faces);mesh.update()
    obj=bpy.data.objects.new(group+'Feather',mesh);scene.collection.objects.link(obj)
    register(obj,group,'feather_tail' if tail else 'feather',region)
    obj['start']=list(start);obj['end']=list(end)
    # Recalculate outward normals, including mirrored left wings.
    C.activate(obj);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
    return obj

def blade(group, side, sections):
    """Thin airfoil: rounded leading edge, cambered crown, pinched trailing edge."""
    verts=[]
    for x,lead,trail,y,h in sections:
        chord=trail-lead
        for t,dy in [(0,0),(.07,.75),(.30,1),(.72,.50),(1,0),(.72,-.24),(.30,-.40),(.07,-.35)]:
            verts.append(b((side*x,y+dy*h,lead+t*chord)))
    faces=[tuple(reversed(range(8)))]
    for j in range(len(sections)-1):
        for k in range(8):
            a=j*8+k;d=j*8+(k+1)%8;faces.append((a,d,d+8,a+8))
    faces.append(tuple(range((len(sections)-1)*8,len(sections)*8)))
    mesh=bpy.data.meshes.new(group+'Blade');mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new(group+'Blade',mesh);scene.collection.objects.link(obj)
    register(obj,group,'wing',3)
    C.activate(obj);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
    return obj

egg('Body',(0,.015,.055),(.207,.160,.390),'body',1,16,10)
# Shape the egg: fuller front breast, narrower raised tail end.
for v in groups['Body'][0].data.vertices:
    p=g(v.co);t=max(0,p.z/.365);p.x*=1-.28*t;p.y+=.048*t*t;v.co=b(p)
egg('Chest',(0,-.002,-.208),(.139,.120,.170),'cream',2,12,8)
egg('Chest',(0,.027,-.285),(.095,.115,.100),'cream',2,8,6)
egg('Head',(0,.102,-.36),(.119,.13,.13),'cream',1,16,10)
for side in (-1,1):
    egg('Head',(.079*side,.134,-.447),(.032,.034,.026),'eye',7,12,6)
    egg('Head',(.075*side,.147,-.469),(.008,.009,.006),'cream',0,8,4)
    # Cream brow overlaps the upper edge of the eye: a soft mischievous lid.
    egg('Head',(.080*side,.163,-.444),(.038,.012,.025),'cream',1,8,4,side*.10)
    egg('Head',(.093*side,.101,-.421),(.023,.020,.024),'cream',1,8,4)
egg('Head',(0,.071,-.527),(.037,.029,.095),'beak',6,12,8)
egg('Head',(0,.052,-.594),(.023,.024,.025),'beak',6,10,6)
egg('Head',(0,.032,-.608),(.014,.010,.016),'dot',0,8,4)
for side in (-1,1):
    egg('Head',(.034*side,.076,-.519),(.003,.006,.017),'nostril',0,8,4)

for side, suffix in [(-1,'L'),(1,'R')]:
    blade('Upper'+suffix,side,[(.10,-.14,.16,.064,.026),(.23,-.20,.21,.070,.036),
        (.36,-.18,.20,.070,.027),(.51,-.13,.18,.070,.018)])
    # A rounded covert hides the shoulder hinge without a sausage-like arm.
    egg('Upper'+suffix,(side*.150,.063,-.002),(.130,.052,.167),'wing',3,8,6)
    egg('Upper'+suffix,(side*.445,.070,.025),(.081,.035,.147),'wing',3,8,6)
    blade('Fore'+suffix,side,[(.405,-.09,.13,.070,.012),(.48,-.15,.20,.070,.026),
        (.64,-.13,.20,.067,.020),(.80,-.08,.16,.062,.011)])
    for i in range(5):
        feather('Hand'+suffix,(side*(.72-max(0,i-1)*.026),.064-i*.002,-.110+i*.057),
                (side*(1.160-i*.063),.047-i*.002,-.040+i*.080),.044+i*.001,.010,4)
for i in range(5):
    feather('Tail',((i-2)*.027,.008,.37),((i-2)*.061,.05-abs(i-2)*.008,.77-abs(i-2)*.020),.046,.013,5,True)
for side in (-1,1):
    egg('Legs',(.072*side,-.246,.021),(.014,.140,.014),'feet',0,8,6)
    # One low-poly web, with a scalloped front edge; sole height is unchanged.
    foot=egg('Legs',(.072*side,-.384,-.029),(.047,.014,.070),'feet',0,10,4)
    for v in foot.data.vertices:
        p=g(v.co)
        if p.z<-.055:p.z-=.007*(.5+.5*math.cos((p.x-.072*side)/.047*math.tau))
        v.co=b(p)

def colour(obj, p):
    p=g(p);style=obj['paint']
    if style in ('body','cream'):
        base=palette['cream'].copy()
        if style=='body':
            back=max(0,min(1,(p.y-.055)/.09))*max(0,min(1,(p.z+.20)/.20))
            base=base.lerp(palette['mantle'],back*.65)
        return base.lerp(palette['lilac'],.22*max(0,min(1,(-p.y-.05)/.14)))
    if style=='wing':
        return palette['cream'].lerp(palette['mantle'],max(0,min(1,(p.y-.025)/.05)))
    if style.startswith('feather'):
        start,end=Vector(obj['start']),Vector(obj['end'])
        t=(p-start).dot(end-start)/(end-start).length_squared
        if style=='feather_tail':
            a=palette['cream'].lerp(palette['fade'],max(0,min(1,(t-.20)/.36)))
            return a.lerp(palette['tip'],max(0,min(1,(t-.56)/.22)))
        a=palette['cream'].lerp(palette['mantle'],.65)
        return a.lerp(palette['tip'],max(0,min(1,(t-.60)/.10)))
    return palette[style]

# Bake only static contact within each moving group, never across a bent joint.
stats={}
for name, pieces in groups.items():
    stats[name]=C.bake_vertex_ao(pieces,pieces,colour,samples=16,distance=.055,strength=.12,gradient=.03)
    for obj in pieces:
        uv = obj.data.uv_layers.active or obj.data.uv_layers.new(name='TintRegion')
        for item in uv.data:
            item.uv=(obj['region']/7.0, 0.0)
    C.activate(pieces[0])
    for obj in pieces:obj.select_set(True)
    if len(pieces)>1: bpy.ops.object.join()
    obj=bpy.context.object;obj.name=name
    # Joining identical slots can still leave repeated material indices: collapse.
    obj.data.materials.clear();obj.data.materials.append(mat)
    for face in obj.data.polygons:face.material_index=0
    groups[name]=obj

pivots={'Body':(0,0,0),'Chest':(0,0,0),'Head':(0,.1,-.36),'Tail':(0,0,.38),'Legs':(0,0,0)}
for side,suffix in [(-1,'L'),(1,'R')]:
    pivots['Upper'+suffix]=(side*.14,.07,-.06)
    pivots['Fore'+suffix]=pivots['Hand'+suffix]=(side*.46,.07,-.06)
for name,obj in groups.items():
    pivot=b(pivots[name])
    for v in obj.data.vertices:v.co-=pivot
    obj.location=pivot
    if name=='Body':
        # Existing growth code scales body_mi by (fluff,.9*fluff,1.9).
        # Put authored dimensions in that unchanged legacy scale convention.
        for v in obj.data.vertices:
            p=g(v.co);p.y/=.9;p.z/=1.9;v.co=b(p)
        obj.scale=(1,1.9,.9)
    obj.data.update()

parts=list(groups.values())
tris=C.triangle_count(parts)
assert tris<=4000,(tris,'triangle budget')
assert len(parts)<=12
path=C.export_glb(parts,'game/assets/models/hero_gull_parts.glb',texcoords=True)
C.output_path(folder/'asset_stats.json').write_text(json.dumps({'triangles':tris,'parts':len(parts),'materials':1,
    'bytes':path.stat().st_size,'parts_triangles':{n:C.triangle_count([o]) for n,o in groups.items()},
    'pivots_godot':pivots,'ao':stats},indent=2))

if args.review == 'none':
    print('[HERO_GULL] export only:', tris, 'triangles', len(parts), 'parts')
    sys.exit(0)

# Review 2 permits a handful of <=768 px poses. Four views, one bounded batch.
scene.render.film_transparent=True
scene.render.engine='BLENDER_EEVEE';scene.eevee.taa_render_samples=8
scene.render.resolution_x=scene.render.resolution_y=768
scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
scene.world=bpy.data.worlds.new('ReviewSky');scene.world.use_nodes=True
scene.world.node_tree.nodes.clear()
bg=scene.world.node_tree.nodes.new('ShaderNodeBackground');wo=scene.world.node_tree.nodes.new('ShaderNodeOutputWorld')
scene.world.node_tree.links.new(bg.outputs[0],wo.inputs[0])
bg.inputs[0].default_value=(.8,.83,.9,1);bg.inputs[1].default_value=.5
data=bpy.data.lights.new('PoseKey','AREA');data.energy=500;data.size=5
light=bpy.data.objects.new('PoseKey',data);scene.collection.objects.link(light)
light.location=(2,3,4);light.rotation_euler=(-light.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('PoseCamera');cam=bpy.data.objects.new('PoseCamera',data);scene.collection.objects.link(cam)
scene.camera=cam;data.type='ORTHO';data.ortho_scale=2.65
cam.location=(2,3,1.4);cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler()
pose_paths=[]
for label,a,e,s,legs in [('level',.12,.3,0,False),('up',1.50,-.35,.15,False),('perched',-1.2,1.1,.1,True),('top',.12,.3,0,False)]:
    cam.location=(0,.001,4) if label=='top' else (2,3,1.4)
    cam.rotation_euler=(-cam.location).to_track_quat('-Z','Y').to_euler()
    data.ortho_scale=1.6 if label=='perched' else 2.65
    scene.render.resolution_x=scene.render.resolution_y=512 if label=='top' else 768
    for side,suffix in [(-1,'L'),(1,'R')]:
        # Godot Euler order YXZ; x is zero in these wing poses.
        r=Matrix.Rotation(-s*side,3,'Y') @ Matrix.Rotation(a*side,3,'Z')
        er=Matrix.Rotation(-e*side,3,'Z')
        wrist=max(-1.35,min(1.35,a-e))-(a-e)
        wr=Matrix.Rotation(wrist*side,3,'Z')
        root=Vector(pivots['Upper'+suffix]);elbow=root+r@Vector((side*.32,0,0))
        for prefix in ('Upper','Fore','Hand'):
            obj=groups[prefix+suffix]
            obj.location=b(root if prefix=='Upper' else elbow)
            obj.rotation_euler=(G@(r if prefix=='Upper' else r@er@wr)@G.transposed()).to_euler()
            obj.scale=(1,1,1)
            if label=='perched':
                upper=prefix=='Upper'
                rr=Matrix.Rotation(-side*(1.25 if upper else 1.50),3,'Y') @ Matrix.Rotation(-side*.12 if upper else 0,3,'Z')
                obj.location=b((side*(.17 if upper else .23),.075 if upper else .035,-.12 if upper else .09))
                obj.rotation_euler=(G@rr@G.transposed()).to_euler()
                obj.scale=(1 if upper else .75,.65 if upper else .55,1)
    groups['Tail'].rotation_euler=(G@Matrix.Rotation(-.1 if legs else 0,3,'X')@G.transposed()).to_euler()
    groups['Legs'].hide_render=not legs
    path=C.output_path(folder/f'pose_{label}.png');scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True);pose_paths.append(path)
C.contact_sheet(pose_paths,folder/'poses.png',tile=256,columns=2)
print('[HERO_GULL]',tris,'triangles',len(parts),'parts',path)
