"""CC0 palette GLB -> one flat, vertex-painted, AO-baked mesh, metres / Y-up.

Blender --background --threads 4 --python tools/blender/import_kenney.py -- --catalog
Or: --input art_src/.../model.glb --name example --size 1 .8 1 --budget 200
All writes stay in this project. Sources and licences are never modified.
"""
import argparse, colorsys, hashlib, json, math, sys
from array import array
from pathlib import Path
import bpy
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from common import ROOT, clean_scene, activate, linear_rgb, vertex_material, bake_vertex_ao, export_glb, triangle_count, output_path

CATALOG=[
    ('cliff','nature-kit','cliff_rock',[5,4,1.2],200,'stone'),
    ('crag','nature-kit','rock_tallA',[9,20,8],200,'crag'),
    ('rock','nature-kit','rock_largeC',[3.8,1.4,3],200,'stone'),
    ('bush','nature-kit','plant_bush',[1.1,.85,.95],200,'plant'),
    ('flower','nature-kit','flower_redA',[.25,.55,.25],100,'plant'),
    ('rowboat','pirate-kit','boat-row-large',[2,.85,5.2],200,'boat'),
    ('barrel','pirate-kit','barrel',[.68,.9,.68],200,'wood'),
    ('crate','pirate-kit','crate',[.85,.85,.85],200,'wood'),
    ('planks','pirate-kit','platform-planks',[1,.12,1],200,'wood'),
    ('palm','pirate-kit','palm-detailed-bend',[3.8,7.8,4.8],500,'palm'),
    ('table','furniture-kit','tableRound',[1,.81,.8],200,'wood'),
    ('chair','furniture-kit','chair',[.46,.97,.46],200,'wood'),
    ('plant','furniture-kit','pottedPlant',[.7,1.28,.7],200,'plant'),
    ('plate','food-kit','plate',[.27,.025,.27],200,'ceramic'),
    ('drink','food-kit','soda',[.14,.28,.14],200,'drink'),
]

def source_path(pack,name):
    base=ROOT/'art_src/third_party/_quarantine'/pack/'x'
    license=(base/'License.txt').read_text(encoding='utf-8-sig')
    assert 'CC0' in license
    matches=list((base/'Models').glob('GL* format/'+name+'.glb'))
    assert len(matches)==1,(pack,name,matches)
    return matches[0]

def paint(rgb, family):
    h,s,v=colorsys.rgb_to_hsv(*rgb)
    if s>.18 and .18<h<.56:return '73974F' if v>.5 else '477657'
    if family=='palm':return '8B6A4D'
    if family=='stone':return '82818A' if v>.5 else '707480'
    if family=='crag':return '676A7B' if v>.5 else '5A6070'
    if s<.15:
        return 'F5EDDB' if v>.62 else ('8D9EAC' if v>.28 else '485366')
    if .54<h<.82:
        return '6C9FAD' if family in ('boat','drink') else '7D8E9E'
    if h<.045 or h>.93:return 'D37D63'
    if family=='boat':return 'E8D9B5' if v>.68 else 'BC9165'
    return 'CDA56E' if v>.62 else '947255'

def samples_for(obj,family):
    mesh=obj.data; uv=mesh.uv_layers.active
    pixels={}; textures={}
    for idx,slot in enumerate(obj.material_slots):
        mat=slot.material
        images=[n.image for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image] if mat and mat.use_nodes else []
        if images:
            im=images[0]; data=array('f',[0])*(len(im.pixels)); im.pixels.foreach_get(data)
            pixels[idx]=(im.size[0],im.size[1],data);textures[idx]=im.name
    faces=[];mapping={}
    for f in mesh.polygons:
        if f.material_index in pixels and uv:
            w,h,px=pixels[f.material_index]
            u=sum(uv.data[k].uv.x for k in f.loop_indices)/len(f.loop_indices)
            v=sum(uv.data[k].uv.y for k in f.loop_indices)/len(f.loop_indices)
            x=min(w-1,max(0,int((u%1)*w)));y=min(h-1,max(0,int((v%1)*h)))
            rgb=tuple(px[(y*w+x)*4+i] for i in range(3))
        else:
            mat=obj.material_slots[f.material_index].material
            rgb=tuple(mat.diffuse_color[:3]) if mat else (1,1,1)
        colour=paint(rgb,family);faces.append(colour)
        mapping[str(tuple(round(c,4) for c in rgb))]=colour
    return faces,mapping,textures

def render_one(obj,path):
    scene=bpy.context.scene;scene.render.engine='BLENDER_EEVEE';scene.eevee.taa_render_samples=8
    scene.render.resolution_x=scene.render.resolution_y=320;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.film_transparent=False
    scene.world=bpy.data.worlds.new('S3Preview');scene.world.color=(.25,.25,.25)
    scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
    points=[obj.matrix_world@Vector(p) for p in obj.bound_box];lo=Vector([min(p[i] for p in points) for i in range(3)]);hi=Vector([max(p[i] for p in points) for i in range(3)])
    center=(lo+hi)/2;extent=max(hi-lo)
    for name,offset,energy,col in [('key',(3,-4,6),450,(1,.83,.65)),('fill',(-3,2,4),220,(.7,.8,1))]:
        data=bpy.data.lights.new(name,'AREA');data.energy=energy*extent**2;data.color=col;data.size=extent*4
        o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);o.location=center+Vector(offset)*extent;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
    data=bpy.data.cameras.new('Review');camera=bpy.data.objects.new('Review',data);scene.collection.objects.link(camera);scene.camera=camera
    data.type='ORTHO';data.ortho_scale=extent*1.5;camera.location=center+Vector((3,-4,2.6))*extent;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(output_path(path));bpy.ops.render.render(write_still=True)

def convert(path,name,size,budget,family,render=True,output_dir='game/assets/art/kenney',review_dir='art_src/s3/kit_review_final_flat'):
    clean_scene();bpy.ops.import_scene.gltf(filepath=str(path))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert meshes
    # Apply hierarchy before normalization. All exported geometry has identity transforms.
    for o in meshes:
        world=o.matrix_world.copy();o.parent=None;o.matrix_world=world;activate(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    pts=[v.co for o in meshes for v in o.data.vertices];lo=Vector([min(v[i] for v in pts) for i in range(3)]);hi=Vector([max(v[i] for v in pts) for i in range(3)])
    extent=hi-lo; center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    scale=Vector((size[0]/max(extent.x,1e-4),size[2]/max(extent.y,1e-4),size[1]/max(extent.z,1e-4)))
    if name=='palm':
        base=[p for p in pts if p.z<lo.z+extent.z*.025]
        center.x=sum(p.x for p in base)/len(base);center.y=sum(p.y for p in base)/len(base)
    mapping={};texture_names={};face_colours={}
    for o in meshes:
        faces,mp,tx=samples_for(o,family);face_colours[o.name]=faces;mapping.update(mp);texture_names.update(tx)
        for v in o.data.vertices:v.co=(v.co-center)*scale
        for f in o.data.polygons:f.use_smooth=False
    ao=bake_vertex_ao(meshes,meshes,lambda o,p:Vector((1,1,1)),samples=8,distance=min(size)*.55,strength=.16,gradient=.05)
    material=vertex_material('S3_Cover_Vertex')
    for o in meshes:
        col=o.data.color_attributes['Col']
        for f,c in zip(o.data.polygons,face_colours[o.name]):
            rgb=linear_rgb(c)
            for k in f.loop_indices:
                shadow=col.data[k].color;col.data[k].color=(*[rgb[i]*shadow[i] for i in range(3)],1)
        o.data.materials.clear();o.data.materials.append(material)
        for f in o.data.polygons:f.material_index=0
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();obj=bpy.context.object;obj.name=name
    before=triangle_count([obj])
    # Planar dissolve keeps the authored silhouette; no arbitrary collapsing of accessories.
    if before>budget:
        mod=obj.modifiers.new('PalettePlanarDissolve','DECIMATE');mod.decimate_type='DISSOLVE';mod.angle_limit=.012;mod.delimit={'MATERIAL','UV','NORMAL'}
        bpy.ops.object.modifier_apply(modifier=mod.name)
    count=triangle_count([obj])
    if count>budget:
        mod=obj.modifiers.new('BudgetCollapse','DECIMATE');mod.ratio=budget/count*.94;mod.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for f in obj.data.polygons:f.use_smooth=False
    # glTF custom split normals override use_smooth; clear to generated face normals.
    obj.data.normals_split_custom_set([(0.0,0.0,0.0)]*len(obj.data.loops))
    # Rebuild split triangles: imported custom normals can survive a zero-normal reset.
    # A fresh mesh guarantees true face normals and drops zero-area source triangles.
    old=obj.data;old.calc_loop_triangles();verts=[];faces=[];colours=[]
    for tri in old.loop_triangles:
        points=[old.vertices[k].co.copy() for k in tri.vertices]
        if (points[1]-points[0]).cross(points[2]-points[0]).length_squared<1e-16:continue
        start=len(verts);verts.extend(points);faces.append((start,start+1,start+2))
        colours.extend(tuple(old.color_attributes['Col'].data[k].color) for k in tri.loops)
    flat=bpy.data.meshes.new(name+'_Flat');flat.from_pydata(verts,[],faces);flat.update()
    ca=flat.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='CORNER')
    flat.color_attributes.active_color=ca;flat.color_attributes.render_color_index=0
    for corner,c in zip(ca.data,colours):corner.color=c
    flat.materials.append(material);obj.data=flat
    for f in flat.polygons:f.use_smooth=False
    count=triangle_count([obj]);assert count<=budget,(name,count,budget)
    glb=export_glb([obj],f'{output_dir}/{name}.glb')
    if render:render_one(obj,f'{review_dir}/{name}.png')
    return {'source':str(path.relative_to(ROOT)).replace('\\','/'),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'output':str(glb.relative_to(ROOT)).replace('\\','/'),'output_sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'size_m':size,'origin':'base-centre','tris':count,'source_tris':before,'surfaces':1,'palette':mapping,'source_textures':texture_names,'ao':ao}

def main():
    p=argparse.ArgumentParser();p.add_argument('--catalog',action='store_true');p.add_argument('--input');p.add_argument('--name');p.add_argument('--size',nargs=3,type=float,default=[1,1,1]);p.add_argument('--budget',type=int,default=200);p.add_argument('--family',default='wood');p.add_argument('--only');p.add_argument('--no-render',action='store_true');a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    result=json.loads((ROOT/'art_src/s3/kit_catalog.json').read_text()) if a.only else {}
    entries=CATALOG if a.catalog else [(a.name,None,None,a.size,a.budget,a.family)]
    for name,pack,src,size,budget,family in entries:
        if a.only and name not in a.only.split(','):continue
        path=source_path(pack,src) if pack else (ROOT/a.input).resolve()
        assert path.is_relative_to(ROOT/'art_src/third_party/_quarantine')
        result[name]=convert(path,name,size,budget,family,not a.no_render)
        result[name]['pack']=pack;result[name]['budget']=budget
        output_path('art_src/s3/kit_catalog.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print('S3_KITS',[(n,v['tris']) for n,v in result.items()])

if __name__=='__main__':main()
