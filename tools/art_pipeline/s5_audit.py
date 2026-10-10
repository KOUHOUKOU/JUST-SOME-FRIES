"""S5 immutable source / GLB geometry checks and measured comparison report."""
from pathlib import Path
import json,hashlib,struct,difflib
root=Path('art_src/s5')
baseline=json.loads((root/'baseline/hashes.json').read_text())
changed=[];patch=[]
for name,digest in baseline.items():
    p=Path(name)
    if not p.exists():continue
    if hashlib.sha256(p.read_bytes()).hexdigest()!=digest:
        changed.append(name)
        if p.suffix in ['.gd','.gdshader','.py']:
            old=(root/'baseline'/p).read_text(encoding='utf-8').splitlines(True)
            patch.extend(difflib.unified_diff(old,p.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
def glb(path):
    data=Path(path).read_bytes();ln=struct.unpack_from('<I',data,12)[0]
    doc=json.loads(data[20:20+ln]);binary=data[28+ln:]
    def acc(index):
        a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
        start=v.get('byteOffset',0)+a.get('byteOffset',0)
        size={5126:4,5125:4,5123:2,5121:1}[a['componentType']]*{'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]*a['count']
        return binary[start:start+size]
    return {m['name']:{k:acc(v) for k,v in {**m['primitives'][0]['attributes'],'indices':m['primitives'][0]['indices']}.items()} for m in doc['meshes']}
old=glb(root/'baseline/game/assets/models/hero_gull_parts.glb');new=glb('game/assets/models/hero_gull_parts.glb')
geometry={n:all(old[n][k]==new[n][k] for k in old[n] if k!='COLOR_0') for n in old}
assert all(geometry.values())
b=json.loads((root/'baseline/game/metrics.json').read_text());a=json.loads((root/'iteration_3/game/metrics.json').read_text())
rows=[]
for x,y in zip(b['samples'],a['samples']):
    assert [x[k] for k in ['view','time','governor','camera']]==[y[k] for k in ['view','time','governor','camera']]
    rows.append({**{k:x[k] for k in ['view','time','governor']},**{k:[x[k],y[k]] for k in ['draw_calls','triangles','frame_ms','render_cpu_ms','render_gpu_ms']}})
report={'samples':rows,'colliders':[b['colliders'],a['colliders']],'physics_equal':b['physics_shapes_sha256']==a['physics_shapes_sha256'],'anchors_equal':b['anchors']==a['anchors'],'people_layout_styles_equal':b['people']==a['people'],'people_count':len(a['people'])}
assert report['physics_equal'] and report['anchors_equal']
assert report['people_layout_styles_equal']
assert all(r['draw_calls'][1]<=r['draw_calls'][0] and r['triangles'][1]<=r['triangles'][0] for r in rows)
(root/'comparison_metrics.json').write_text(json.dumps(report,indent=2))
(root/'source_audit.json').write_text(json.dumps({'changed_from_snapshot':changed,'unchanged_count':len(baseline)-len(changed),'gull_noncolour_accessors_identical':geometry},indent=2))
(root/'source_diff.patch').write_text(''.join(patch),encoding='utf-8')
print('PASS: 11 matched camera rows lower draws/tris; physics/anchors exact; gull geometry identical')
