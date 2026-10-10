"""S6: existing CC0 crop / ivy imports and a authored faceted coastal escarpment."""
import sys,math,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
import bpy
from common import ROOT,clean_scene,linear_rgb,vertex_material,export_glb,output_path,triangle_count
from import_kenney import source_path,convert,render_one
out='game/assets/models/s6';review='art_src/s6/iteration_4/blender'
catalog={}
for name,src,size,budget,family in [
    ('wheat','crops_wheatStageB',[4.2,.8,.7],120,'wood'),
    ('leaves','crops_leafsStageB',[1.3,.58,.85],120,'plant'),
    ('ivy','hanging_moss',[1.8,1.7,.22],120,'plant')]:
    catalog[name]=convert(source_path('nature-kit',src),name,size,budget,family,True,out,review)
    catalog[name].update(pack='nature-kit',license='CC0 1.0',url='https://kenney.nl/assets/nature-kit')
clean_scene()
# Godot coordinates are built explicitly then mapped to Blender X,-Z,Y.
# The 24 m playable cap stays exactly fixed; only the non-solid skirt changes.
rings=[(53,.05),(46,2.3),(39,7.4),(30.5,18.5),(28.5,22.4),(24.25,24.02)]
verts=[];faces=[];cols=[];N=24
for k,(r,y) in enumerate(rings):
    for i in range(N):
        a=i*math.tau/N
        t=k/(len(rings)-1)
        if k not in [0,len(rings)-1]:a+=math.sin(i*1.9+k*.7)*.038
        wob=(math.sin(a*3+.5)*.8+math.sin(a*7)*.3)*(1-t)
        radius=r+wob*2.0-max(0,math.cos(a))*(1-t)**2*11
        # Unequal columns and staggered ledges remove the concentric cone bands.
        yy=y+(math.sin(a*3+.5)*2.2+math.cos(a*5)*1.5)*math.sin(math.pi*t)
        if k in [2,3,4]:radius+=(3.5 if i%4==0 else -1.2)*math.sin(math.pi*t)
        x=math.cos(a)*radius;z=math.sin(a)*radius
        verts.append((x,-z,yy))
palette=['796D66','877565','79695F','89755F','758449']
for k in range(len(rings)-1):
    for i in range(N):
        a=k*N+i;b=k*N+(i+1)%N;c=(k+1)*N+i;d=(k+1)*N+(i+1)%N
        # Correct outward winding after the Y-up conversion.
        faces.extend([(a,c,b),(b,c,d)])
        col=linear_rgb(palette[k]);shade=.90+.18*math.sin(i*2.4+k*.75)
        cols.extend([tuple(v*shade for v in col)]*2)
mesh=bpy.data.meshes.new('CoastalStrata');mesh.from_pydata(verts,[],faces);mesh.update()
obj=bpy.data.objects.new('headland',mesh);bpy.context.collection.objects.link(obj)
ca=mesh.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='CORNER');mesh.color_attributes.active_color=ca;mesh.color_attributes.render_color_index=0
for poly,c in zip(mesh.polygons,cols):
    poly.use_smooth=False
    for li in poly.loop_indices:ca.data[li].color=(*c,1)
mesh.materials.append(vertex_material('S6_Cover_Vertex'))
glb=export_glb([obj],out+'/headland.glb');render_one(obj,review+'/headland.png')
catalog['headland']={'output':str(glb.relative_to(ROOT)).replace('\\','/'),'tris':triangle_count([obj]),'surfaces':1,'authored':True,'collision':'none; original cap and terrain retained'}
output_path('art_src/s6/assets.json').write_text(json.dumps(catalog,indent=2))
print('S6 ASSETS',[(k,v['tris']) for k,v in catalog.items()])
