"""S1 cover gull: flat facets, dots, closed angular wings; no feathers.

Blender --background --threads 4 --python tools/blender/hero_gull.py -- --iteration 1
Eleven original pivot-local parts, one material, original UV recolour regions.
"""
import sys, math, json, argparse
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
from mathutils import Vector, Matrix
import common as C

ap=argparse.ArgumentParser()
ap.add_argument('--iteration',type=int,choices=range(1,5),default=1)
ap.add_argument('--no-render',action='store_true')
ap.add_argument('--views',default='front,left,right,back,top')
ap.add_argument('--round2',action='store_true')
ap.add_argument('--s5',action='store_true')
args=ap.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
folder=Path('art_src/s1/round_2/blender' if args.round2 else f'art_src/s1/iteration_{args.iteration}/blender')
if args.s5:folder=Path('art_src/s5/iteration_1/gull')
scene=C.clean_scene(); mat=C.vertex_material('CoverGull'); groups={}
G=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
def b(p):return G@Vector(p)
def g(p):return G.transposed()@p

def mesh(group,verts,faces,col,region=0,facet=False):
    data=bpy.data.meshes.new(group);data.from_pydata([b(p) for p in verts],[],faces);data.update()
    obj=bpy.data.objects.new(group,data);scene.collection.objects.link(obj)
    C.activate(obj);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
    data.materials.append(mat)
    ca=data.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='CORNER')
    data.color_attributes.active_color=ca;data.color_attributes.render_color_index=0
    uv=data.uv_layers.new(name='TintRegion')
    for face in data.polygons:
        face.use_smooth=False
        paint=col[face.index%len(col)] if isinstance(col,list) else col
        rgb=C.linear_rgb(paint)
        if facet:
            # No latitude stripes: only a tiny luminance variation per face.
            rgb=tuple(v*(1.0+((face.index*7)%11-5)*.002) for v in rgb)
            if g(face.normal).y < -.45:rgb=(rgb[0]*.991,rgb[1]*.995,rgb[2])
        for li in face.loop_indices:
            ca.data[li].color=(*rgb,1);uv.data[li].uv=(region/7,0)
    groups.setdefault(group,[]).append(obj)
    return obj

def egg(group,c,r,col,region=0,n=12,rings=6,facet=False):
    verts=[(c[0],c[1]+r[1],c[2])]
    for j in range(1,rings):
        a=math.pi*j/rings
        for k in range(n):
            q=math.tau*k/n+math.pi/n
            verts.append((c[0]+r[0]*math.sin(a)*math.cos(q),c[1]+r[1]*math.cos(a),c[2]+r[2]*math.sin(a)*math.sin(q)))
    verts.append((c[0],c[1]-r[1],c[2]));faces=[]
    for k in range(n):faces.append((0,1+k,1+(k+1)%n))
    for j in range(rings-2):
        for k in range(n):
            a=1+j*n+k;d=1+j*n+(k+1)%n
            faces.append((a,a+n,d+n,d))
    for k in range(n):faces.append((len(verts)-1,1+(rings-2)*n+(k+1)%n,1+(rings-2)*n+k))
    return mesh(group,verts,faces,col,region,facet)

def prism(group,sections,col,region=0):
    # Sections are (z, half-width, bottom, top); flat trapezoid/box beak.
    v=[]
    for z,w,lo,hi in sections:v.extend([(-w,lo,z),(w,lo,z),(w,hi,z),(-w,hi,z)])
    f=[(3,2,1,0)]
    for j in range(len(sections)-1):
        for k in range(4):f.append((j*4+k,j*4+(k+1)%4,(j+1)*4+(k+1)%4,(j+1)*4+k))
    f.append(tuple(range((len(sections)-1)*4,len(sections)*4)))
    return mesh(group,v,f,col,region)

# Round 15: a plump body and a head of a friendly size (it was deliberately oversized before: the director found it too big). Head radius .185-.19 (was .26).
egg('Body',(0,.015,.075),(.30,.23,.38),'F7F7FA',1,12,7,True)
egg('Chest',(0,.01,-.175),(.225,.19,.215),'F7F7FA',2,10,5,True)
egg('Head',(0,.30,-.30),(.188,.188,.184),'F7F7FA',1,12,7,True)
for side in (-1,1):
    egg('Head',(side*.108,.326,-.449),(.0235,.0255,.0205),'08090C',7,10,4)
prism('Head',[(-.40,.080,.228,.335),(-.52,.068,.228,.328),(-.625,.047,.226,.298)],'F7B21A',6)
prism('Head',[(-.603,.050,.222,.246),(-.627,.047,.222,.246)],'E95B24',0)

def wing(group,side,sections,col,region=3):
    v=[]
    # Author the reference pose in world coordinates, then undo the EXACT
    # existing shoulder/elbow transforms into neutral mesh coordinates.
    upper=group.startswith('Upper');r=Matrix.Rotation(.72*side,3,'Z')
    root=Vector((side*.14,.07,-.06));elbow=root+r@Vector((side*.32,0,0))
    for x,high,low,rear,front in sections:
        # Slightly broader diagonal wing face and a swept, curved trailing edge.
        # The tip remains a point; the extra chord lives around the elbow only.
        bulge=max(0.0,1.0-abs(x-.51)/.45)
        rear+=.055*bulge;front+=.018*bulge
        if .3<x<.72:low-=.025;high+=.008
        ring=[(side*x,high,rear),(side*x,high-.020,rear+(front-rear)*.27),
              (side*x,low,front),(side*x,low-.018,front),(side*x,high-.018,rear)]
        for point in ring:
            p=Vector(point)
            p=root+r.transposed()@(p-root) if upper else Vector((side*.46,.07,-.06))+(p-elbow)
            v.append(p)
    f=[tuple(reversed(range(5)))]
    for j in range(len(sections)-1):
        for k in range(5):f.append((j*5+k,j*5+(k+1)%5,(j+1)*5+(k+1)%5,(j+1)*5+k))
    f.append(tuple(range((len(sections)-1)*5,len(sections)*5)))
    return mesh(group,v,f,col,region)
for side,suf in [(-1,'L'),(1,'R')]:
    wing('Upper'+suf,side,[(.14,.245,.025,.08,-.20),(.31,.360,.092,.10,-.21),(.49,.545,.230,.15,-.19)],['F3F3F8','EAEBF2','DFE0EB','F3F3F8','F7F7FA'])
    # Continue the actual forewing shell into its elbow rather than putting a
    # separate raised cap on top. The proximal ring overlaps the upper shell.
    wing('Fore'+suf,side,[(.38,.325,.240,.10,-.18),(.475,.535,.225,.15,-.19),(.64,.625,.363,.23,-.20),(.71,.625,.399,.24,-.16)],['EEEDF5','E2E1ED','D3D2E0','E3E3EF','F0F0F7'])
    wing('Hand'+suf,side,[(.70,.625,.397,.235,-.165),(1.00,.612,.512,.255,-.10),(1.28,.590,.572,.285,.262)],['555965','575C69','424651','484D5A','89909E'],4)
# Short angular fan/wedge, no individual feather strips.
mesh('Tail',[(0,.085,.34),(-.21,.055,.40),(-.19,.08,.53),(0,.12,.60),(.19,.08,.53),(.21,.055,.40),(0,.025,.49)],
     [(0,1,2,3),(0,3,4,5),(6,2,1),(6,3,2),(6,4,3),(6,5,4),(6,1,0,5)],['E2E4EA','F5F5F7','B8BDC8'],5)
for side in (-1,1):
    x=.13*side
    # Rectangular thin shin, webbed triangular foot with a raised central ridge.
    o=prism('Legs',[(.026,.016,-.305,-.17),(.054,.016,-.305,-.17)],'F7B21A')
    for ve in o.data.vertices:ve.co.x+=x
    mesh('Legs',[(x-.024,-.292,.034),(x+.024,-.292,.034),(x-.086,-.392,-.082),(x+.086,-.392,-.082),
                 (x,-.354,-.058),(x-.086,-.400,-.082),(x+.086,-.400,-.082),(x,-.396,.055)],
         [(0,2,4),(0,4,1),(1,4,3),(2,3,4),(0,1,7),(0,7,5,2),(1,3,6,7),(2,5,6,3),(5,7,6)],['FFC32B','F7B21A','E7A018'])

pivots={'Body':(0,0,0),'Chest':(0,0,0),'Head':(0,.1,-.36),'Tail':(0,0,.38),'Legs':(0,0,0)}
for side,suf in [(-1,'L'),(1,'R')]:
    pivots['Upper'+suf]=(side*.14,.07,-.06)
    pivots['Fore'+suf]=pivots['Hand'+suf]=(side*.46,.07,-.06)
for name,pieces in list(groups.items()):
    C.activate(pieces[0])
    for ob in pieces:ob.select_set(True)
    if len(pieces)>1:bpy.ops.object.join()
    obj=bpy.context.object;obj.name=name;obj.data.materials.clear();obj.data.materials.append(mat)
    for f in obj.data.polygons:f.material_index=0;f.use_smooth=False
    pivot=b(pivots[name])
    for ve in obj.data.vertices:
        ve.co-=pivot
        if name=='Body':
            p=g(ve.co);p.y/=.9;p.z/=1.9;ve.co=b(p)
    obj.location=pivot
    if name=='Body':obj.scale=(1,1.9,.9)
    groups[name]=obj
parts=list(groups.values());tris=C.triangle_count(parts)
assert 500<=tris<=1000,(tris,'S1 budget')
path=C.export_glb(parts,'game/assets/models/hero_gull_parts.glb',texcoords=True)
stats={'triangles':tris,'parts':len(parts),'materials':1,'bytes':path.stat().st_size,
       'flat_faces':all(not f.use_smooth for o in parts for f in o.data.polygons),
       'parts_triangles':{n:C.triangle_count([o]) for n,o in groups.items()},'pivots_godot':pivots}
C.output_path(folder/'asset_stats.json').write_text(json.dumps(stats,indent=2))
# Mesh-local measurement input. This is not a different display mesh.
C.output_path(folder/'geometry.json').write_text(json.dumps({n:{'vertices':[list(g(v.co)) for v in o.data.vertices], 'faces':[list(f.vertices) for f in o.data.polygons]} for n,o in groups.items()}))
if args.no_render:sys.exit(0)

# Fixed five orthographic views, eight samples. Transparent alpha doubles as the
# measurement silhouette, so there is no separate high-cost silhouette pass.
scene.render.engine='BLENDER_EEVEE';scene.eevee.taa_render_samples=8
scene.render.resolution_x=scene.render.resolution_y=512
scene.render.resolution_percentage=100;scene.render.film_transparent=True
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
scene.world=bpy.data.worlds.new('ReviewSky');scene.world.use_nodes=True
scene.world.node_tree.nodes.clear()
bg=scene.world.node_tree.nodes.new('ShaderNodeBackground');wo=scene.world.node_tree.nodes.new('ShaderNodeOutputWorld')
scene.world.node_tree.links.new(bg.outputs[0],wo.inputs[0])
bg.inputs[0].default_value=(.8,.85,1,1);bg.inputs[1].default_value=.8
ld=bpy.data.lights.new('WarmKey','AREA');ld.energy=350;ld.size=5;ld.color=(1,.86,.72)
li=bpy.data.objects.new('WarmKey',ld);scene.collection.objects.link(li);li.location=b((-3,4,-4));li.rotation_euler=(-li.location).to_track_quat('-Z','Y').to_euler()
ld2=bpy.data.lights.new('CoolFill','AREA');ld2.energy=260;ld2.size=5;ld2.color=(.80,.87,1)
li2=bpy.data.objects.new('CoolFill',ld2);scene.collection.objects.link(li2);li2.location=b((3,2,3));li2.rotation_euler=(-li2.location).to_track_quat('-Z','Y').to_euler()
ld.energy=350;ld2.energy=260;ld.use_shadow=False;ld2.use_shadow=False
cd=bpy.data.cameras.new('ReviewCamera');cam=bpy.data.objects.new('ReviewCamera',cd);scene.collection.objects.link(cam);scene.camera=cam;cd.type='ORTHO';cd.ortho_scale=2.6

views={'front':(0,.06,-1),'left':(-.83,.24,-.56),'right':(.83,.24,-.56),'back':(0,.06,1),'top':(0,1,-.00001)}
pose_path=C.output_path('art_src/s1/round_2/reference_poses.json')
poses=json.loads(pose_path.read_text()) if args.round2 and pose_path.exists() else {}
for name,direction in views.items():
    if name not in args.views.split(','):continue
    config=poses.get(name,{'camera':direction,'left':[.72,.72],'right':[.72,.72]})
    direction=config['camera']
    for side,suf in [(-1,'L'),(1,'R')]:
        values=config['left' if side==-1 else 'right'];a,e=values[:2];s=values[2] if len(values)>2 else 0
        r=Matrix.Rotation(-s*side,3,'Y')@Matrix.Rotation(a*side,3,'Z');er=Matrix.Rotation(-e*side,3,'Z')
        root=Vector(pivots['Upper'+suf]);elbow=root+r@Vector((side*.32,0,0))
        for pre in ['Upper','Fore','Hand']:
            o=groups[pre+suf];o.location=b(root if pre=='Upper' else elbow)
            o.rotation_euler=(G@(r if pre=='Upper' else r@er)@G.transposed()).to_euler()
    target=Vector((0,.10,0));cam.location=b(target+Vector(direction).normalized()*5)
    cam.rotation_euler=(b(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    if name=='top':cam.rotation_euler=(0,0,math.pi) # explicit roll: beak down, as reference
    elif config.get('roll'):cam.rotation_euler=(cam.rotation_euler.to_matrix()@Matrix.Rotation(config['roll'],3,'Z')).to_euler()
    scene.render.filepath=str(C.output_path(folder/f'{name}.png'));bpy.ops.render.render(write_still=True)
stats['reference_pose']=poses if poses else {'shoulder_z':.72,'elbow_z':-.72,'legs':True}
stats['orthographic_cameras_godot']=views
C.output_path(folder/'asset_stats.json').write_text(json.dumps(stats,indent=2))
print('[S1 GULL]',tris,'tris',len(parts),'parts')
