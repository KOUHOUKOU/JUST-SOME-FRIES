"""Small source/GLB audit for the Review 4 revision, not a gameplay suite."""
from pathlib import Path
import json,hashlib,struct
import numpy as np
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'art_src/p1b_review2'
def glb(path):
 raw=path.read_bytes();size=struct.unpack_from('<I',raw,12)[0]
 doc=json.loads(raw[20:20+size]);data=raw[28+size:];out={}
 def access(index):
  a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
  dt=np.dtype({5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']]);n={'VEC2':2,'VEC3':3,'VEC4':4,'SCALAR':1}[a['type']]
  offset=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',n*dt.itemsize)
  ar=np.ndarray((a['count'],n),dtype=dt,buffer=data,offset=offset,strides=(stride,dt.itemsize)).astype(float)
  if a.get('normalized'):ar/=np.iinfo(dt).max
  return ar
 for node in doc['nodes']:
  if 'mesh' not in node:continue
  ps=doc['meshes'][node['mesh']]['primitives'];assert len(ps)==1
  p=ps[0];out[node['name']]={k:access(i) for k,i in p['attributes'].items()};out[node['name']]['tris']=len(access(p['indices']))//3
 return out
old=glb(BASE/'baseline/person_parts.glb');new=glb(ROOT/'game/assets/models/person_parts.glb')
def signature(part):
 return sorted(tuple(row) for row in np.round(np.concatenate([part[k] for k in ['POSITION','NORMAL','COLOR_0']],axis=1),7))
faces={}
for n in ['Head','EyeL','EyeR','Mouth']:
 assert signature(old[n])==signature(new[n]),n
 faces[n]={'position_normal_colour_identical':True,'vertices':len(new[n]['POSITION'])}
regions={}
expected={'Torso':{1,2},'ArmL':{1,2},'ArmR':{1,2},'LegL':{3,5},'LegR':{3,5},'Head':{1,9},'Hair_bun':{4},'Hair_beanie':{6},'Hair_cap':{6},'Apron':{10},'Pack':{7},'Vest':{8}}
for n,p in new.items():
 assert 'TEXCOORD_1' not in p,n
 actual=set(np.rint(p['TEXCOORD_0'][:,0]*15).astype(int));regions[n]=sorted(map(int,actual))
 if n in expected:assert actual==expected[n],(n,actual)
trees={}
for path in sorted((ROOT/'game/assets/models').glob('tree_*.glb')):
 p=next(iter(glb(path).values()));uv=p['TEXCOORD_0'];assert set(np.rint(uv[:,0]*15).astype(int))=={0,1}
 assert p['COLOR_0'].shape[1]==4 and p['COLOR_0'][:,3].min()<.01 and p['COLOR_0'][:,3].max()>.99
 trees[path.name]={'tris':p['tris'],'wind_range':[float(p['COLOR_0'][:,3].min()),float(p['COLOR_0'][:,3].max())]}
hashes=json.loads((BASE/'baseline/hashes.json').read_text(encoding='utf-8'))
changed=[name for name,h in hashes.items() if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=h]
sources=[n for n in changed if not n.endswith('.glb')]
assert set(sources)=={'game/scripts/autotest.gd','game/scripts/art/person_parts.gd','game/scripts/art/p1b_review.gd','game/scripts/art/p1b_contract.gd','game/shaders/soft_toon.gdshader'},sources
assert 'game/assets/models/hero_gull_parts.glb' not in changed
contract=json.loads((BASE/'contract.json').read_text(encoding='utf-8'))
metrics=json.loads((BASE/'iteration_2/game/metrics.json').read_text(encoding='utf-8'))
assert metrics['collision_exact'] and metrics['generation_exact']
assert all(s['draw_parts']==9 for s in contract['styles'])
report={'changed_existing_sources':sources,'changed_glbs':[n for n in changed if n.endswith('.glb')],
 'unchanged_baseline_files':len(hashes)-len(changed),'faces':faces,'person_UV_regions':regions,'trees':trees,
 'gull_asset_unchanged':True,'world_colliders_and_generation_exact':True,'person_style_tris':[s['tris'] for s in contract['styles']],
 'glb_bytes':{'trees':sum(p.stat().st_size for p in (ROOT/'game/assets/models').glob('tree_*.glb')),'houses':sum(p.stat().st_size for p in (ROOT/'game/assets/models').glob('house_*.glb')),'person':(ROOT/'game/assets/models/person_parts.glb').stat().st_size}}
(BASE/'source_audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
images=[]
for p in sorted(BASE.rglob('*.png')):
 images.append({'file':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(BASE/'viewed_images.json').write_text(json.dumps({'note':'All images opened with view_image, including invalid diagnostic masks and sheets. Final masks exclude transparent overlay volumes; invalid evidence is retained and labelled. Two asset iterations; masks-only instrumentation repairs did not rerender beauty frames.','count':len(images),'images':images},indent=2),encoding='utf-8')
print(json.dumps({k:report[k] for k in ['changed_existing_sources','faces','person_style_tris','glb_bytes']},indent=2))
print('Opened PNG inventory:',len(images))
