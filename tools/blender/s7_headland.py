"""S7 decorative rock island. Keeps the original radius-24m cap footprint.
The authorised local terrain fallback places that cap at 12m elevation.
No render: review is exclusively through three real game cameras.
"""
import sys,math,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
import bpy
from common import ROOT,clean_scene,linear_rgb,vertex_material,export_glb,output_path,triangle_count
clean_scene()
# Broad stepped shoulders instead of the inherited cone. Thin overhangs, unequal
# ledges and colours form geological strata. East edge avoids marina/town.
rings=[(55,-1.1),(50,.3),(45,2.3),(47,3.0),(42,5.2),(45,6.0),(40,8.2),(42,9.0),(32,11.4),(26,11.65),(24.25,12.02)]
N=24;verts=[];faces=[];cols=[]
for k,(r,y) in enumerate(rings):
 for i in range(N):
  a=i*math.tau/N;t=k/(len(rings)-1)
  wob=(math.sin(a*3+.5)*3.6+math.sin(a*7)*1.8)*(1-t)
  rad=r+wob-max(0,math.cos(a))*(1-t)**1.5*13
  # Aligned fractured columns with staggered strata, not even concentric rings.
  rad+=(3.6*math.sin(i*2.1+k*.13))*math.sin(math.pi*t)
  yy=y+(math.sin(a*3+.5)*1.2+math.cos(a*5)*.65)*math.sin(math.pi*t)
  verts.append((math.cos(a)*rad,-math.sin(a)*rad,yy))
palette=['605B59','82756A','ACA08D','756C65','AC9279','706C68','A39882','7F7263','8D8668','758449']
for k in range(len(rings)-1):
 for i in range(N):
  a=k*N+i;b=k*N+(i+1)%N;c=(k+1)*N+i;d=(k+1)*N+(i+1)%N
  faces.extend([(a,c,b),(b,c,d)])
  col=linear_rgb(palette[k]);shade=.94+.10*math.sin(i*1.7+k*.35)
  cols.extend([tuple(v*shade for v in col)]*2)
mesh=bpy.data.meshes.new('S7LayeredRock');mesh.from_pydata(verts,[],faces);mesh.update()
obj=bpy.data.objects.new('headland',mesh);bpy.context.collection.objects.link(obj)
ca=mesh.color_attributes.new(name='Col',type='FLOAT_COLOR',domain='CORNER');mesh.color_attributes.active_color=ca;mesh.color_attributes.render_color_index=0
for poly,c in zip(mesh.polygons,cols):
 poly.use_smooth=False
 for li in poly.loop_indices:ca.data[li].color=(*c,1)
mesh.materials.append(vertex_material('S7_Cover_Vertex'))
glb=export_glb([obj],'game/assets/models/s7/headland.glb')
output_path('art_src/s7/headland_asset.json').write_text(json.dumps({'path':str(glb.relative_to(ROOT)),'tris':triangle_count([obj]),'materials':1,'rings':rings,'collisions':'unchanged; decorative only'},indent=2))
print('S7 HEADLAND',triangle_count([obj]))
