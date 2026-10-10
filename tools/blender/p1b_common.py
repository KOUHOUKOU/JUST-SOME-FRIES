"""Small Godot-coordinate authoring helpers for P1b. All output stays in project."""
import sys,math,json
from pathlib import Path
import bpy
from mathutils import Vector,Matrix
import common as C
G=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
def b(p):return G@Vector(p)
def g(p):return G.transposed()@p

def register(obj,name,colour,region=0):
 obj.name=name;obj['colour']=colour;obj['region']=region
 C.smooth(obj,weighted=False)
 return obj

def ellipsoid(name,centre,radii,colour,segments=10,rings=6,region=0):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1)
 o=bpy.context.object
 for v in o.data.vertices:
  p=g(v.co);v.co=b(Vector(centre)+Vector([p[i]*radii[i] for i in range(3)]))
 return register(o,name,colour,region)

def mesh(name,verts,faces,colour,region=0,smooth=True):
 m=bpy.data.meshes.new(name);m.from_pydata([b(v) for v in verts],[],faces);m.update()
 o=bpy.data.objects.new(name,m);bpy.context.scene.collection.objects.link(o)
 register(o,name,colour,region)
 C.activate(o);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
 if not smooth:
  for p in o.data.polygons:p.use_smooth=False
 return o

def box(name,centre,size,colour,bevel=0,region=0,rot=None,taper=1):
 bpy.ops.mesh.primitive_cube_add(size=1)
 o=bpy.context.object;o.name=name;o.scale=(size[0],size[2],size[1]);C.activate(o);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if taper!=1:
  for v in o.data.vertices:
   if v.co.z>0:v.co.x*=taper;v.co.y*=taper
 if bevel:C.bevel(o,bevel,2)
 rr=Matrix.Identity(3) if rot is None else Matrix.Rotation(math.radians(rot[1]),3,'Y')@Matrix.Rotation(math.radians(rot[0]),3,'X')@Matrix.Rotation(math.radians(rot[2]),3,'Z')
 for v in o.data.vertices:v.co=b(Vector(centre)+rr@g(v.co))
 register(o,name,colour,region);C.smooth(o,weighted=True)
 return o

def lathe(name,rings,sides,colour,centre=(0,0,0),scallop=0,region=0):
 verts=[]
 for j,(y,r) in enumerate(rings):
  for i in range(sides):
   a=i*math.tau/sides;rr=r*(1+scallop*math.cos(a*5+.4))
   verts.append(Vector(centre)+Vector((rr*math.cos(a),y+scallop*.15*math.cos(a*5)*(1-j/max(1,len(rings)-1)),rr*math.sin(a))))
 faces=[tuple(reversed(range(sides)))]
 for j in range(len(rings)-1):
  for i in range(sides):
   k=j*sides+i;n=j*sides+(i+1)%sides;faces.append((k,n,n+sides,k+sides))
 faces.append(tuple(range((len(rings)-1)*sides,len(rings)*sides)))
 return mesh(name,verts,faces,colour,region)

def finish(objects,name,path,paint=None,alpha=None,region_div=15):
 mat=C.vertex_material('P1bClay')
 for o in objects:o.data.materials.clear();o.data.materials.append(mat)
 if paint is None:paint=lambda o,p:C.linear_rgb(o['colour'])
 stats=C.bake_vertex_ao(objects,objects,paint,samples=12,distance=.18,strength=.20,gradient=.06)
 for o in objects:
  uv=o.data.uv_layers.active or o.data.uv_layers.new(name='TintRegion')
  # Join by one common layer name, including primitives with Blender's UVMap.
  uv.name='TintRegion'
  for k in uv.data:k.uv=(o['region']/region_div,0)
  if alpha:
   c=o.data.color_attributes.active_color
   for k,loop in enumerate(o.data.loops):
    col=c.data[k].color[:];c.data[k].color=(*col[:3],alpha(o,g(o.data.vertices[loop.vertex_index].co)))
 C.activate(objects[0])
 for o in objects:o.select_set(True)
 if len(objects)>1:bpy.ops.object.join()
 o=bpy.context.object;o.name=name;o.data.materials.clear();o.data.materials.append(mat)
 for face in o.data.polygons:face.material_index=0
 if alpha:
  nodes=mat.node_tree.nodes;vc=next(n for n in nodes if n.type=='VERTEX_COLOR');bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
  link=mat.node_tree.links.new(vc.outputs['Alpha'],bs.inputs['Alpha'])
  mat.surface_render_method='DITHERED'
 C.export_glb([o],path,texcoords=True)
 if alpha:mat.node_tree.links.remove(link);bs.inputs['Alpha'].default_value=1
 return o,stats

def only(objects):
 for o in bpy.context.scene.objects:
  if o.type=='MESH':o.hide_render=o not in objects

def turn(objects,folder):
 only(objects);bpy.context.view_layer.update()
 paths=C.render_turntable(objects,folder,resolution=320,samples=8,framing=1.2)
 C.contact_sheet(paths,Path(folder)/'contact.png')

def cast(objects,path,width=512,height=300,scale=10):
 only(objects);bpy.context.view_layer.update();s=bpy.context.scene;s.render.engine='BLENDER_EEVEE';s.eevee.taa_render_samples=8
 s.render.resolution_x=width;s.render.resolution_y=height;s.render.resolution_percentage=100;s.render.film_transparent=False
 s.view_settings.view_transform='Standard';s.view_settings.look='None'
 s.world=bpy.data.worlds.new('CastWorld');s.world.use_nodes=True
 nodes=s.world.node_tree.nodes;nodes.clear();bg=nodes.new('ShaderNodeBackground');out=nodes.new('ShaderNodeOutputWorld');s.world.node_tree.links.new(bg.outputs[0],out.inputs[0]);bg.inputs[0].default_value=(.67,.64,.60,1);bg.inputs[1].default_value=.7
 pts=[o.matrix_world@Vector(p) for o in objects for p in o.bound_box];lo=Vector([min(p[i] for p in pts) for i in range(3)]);hi=Vector([max(p[i] for p in pts) for i in range(3)]);target=(lo+hi)*.5
 d=bpy.data.cameras.new('CastCamera');cam=bpy.data.objects.new('CastCamera',d);s.collection.objects.link(cam);s.camera=cam;d.type='ORTHO';d.ortho_scale=scale
 cam.location=target+Vector((0,-scale*1.7,scale*.75));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
 d=bpy.data.lights.new('CastKey','AREA');d.energy=500*scale;d.size=scale*2;light=bpy.data.objects.new('CastKey',d);s.collection.objects.link(light);light.location=target+Vector((scale*.4,-scale,scale));light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
 s.render.filepath=str(C.output_path(path));bpy.ops.render.render(write_still=True)
 bpy.data.objects.remove(cam,do_unlink=True);bpy.data.objects.remove(light,do_unlink=True)


def panel(name,centre,size,colour,radius=.025,region=0):
 # Rounded-rectangle extrusion: two arc segments per corner, only 44 tris.
 w,h,d=size;pts=[];r=min(radius,w*.2,h*.2)
 for x,y,a in [(w/2-r,h/2-r,0),(-w/2+r,h/2-r,90),(-w/2+r,-h/2+r,180),(w/2-r,-h/2+r,270)]:
  for k in range(3):
   ang=math.radians(a+k*45);pts.append((x+r*math.cos(ang),y+r*math.sin(ang)))
 verts=[Vector(centre)+Vector((x,y,z)) for z in [-d/2,d/2] for x,y in pts];n=len(pts)
 faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 o=mesh(name,verts,faces,colour,region);C.smooth(o,True);return o
