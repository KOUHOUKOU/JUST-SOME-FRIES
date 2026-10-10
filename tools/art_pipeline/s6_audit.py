"""S6 evidence: immutable source scope, camera / collision / performance comparison."""
from pathlib import Path
import hashlib,json,difflib,re,statistics
root=Path(__file__).resolve().parents[2];s=root/'art_src/s6'
hashes=json.loads((s/'baseline/hashes.json').read_text());changed=[];diff=[]
for rel,h in hashes.items():
 p=root/rel
 if hashlib.sha256(p.read_bytes()).hexdigest()!=h:
  changed.append(rel)
  if p.suffix in ['.gd','.gdshader','.py']:
   old=(s/'baseline/source'/rel).read_text(encoding='utf-8').splitlines(True)
   diff.extend(difflib.unified_diff(old,p.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel,tofile='after/'+rel))
allowed=['game/scripts/art/s6_review.gd','game/scripts/autotest.gd','tools/blender/import_kenney.py','game/scripts/art/kenney_parts.gd','game/scripts/world/world_builder.gd','game/scripts/world/world_extra.gd','game/scripts/world/batcher.gd','game/shaders/ground.gdshader','game/scripts/world/cover_atmosphere.gd','game/scripts/world/world_flora.gd','game/scripts/art/person_parts.gd','game/scripts/art/s5_contract.gd']
assert not set(changed)-set(allowed),set(changed)-set(allowed)
assert not any(p.endswith(('.glb','.res')) for p in changed)
before=json.loads((s/'baseline/game/metrics.json').read_text());after=json.loads((s/'iteration_4/game/metrics.json').read_text())
rows=[]
assert len(before['samples'])==len(after['samples'])==25
for b,a in zip(before['samples'],after['samples']):
 for key in ['view','camera','time','governor']:assert b[key]==a[key]
 assert a['draw_calls']<=b['draw_calls'] and a['triangles']<=b['triangles'],b['view']
 rows.append({**{k:b[k] for k in ['view','governor','camera']},**{k:[b[k],a[k]] for k in ['draw_calls','triangles','frame_ms','render_cpu_ms','render_gpu_ms']}})
for k in ['physics_shapes_sha256','colliders','people','anchors']:assert before[k]==after[k],k
assert before['test_window']==after['test_window']=={'mouse_captured':False,'no_focus':True}
startup={}
for version in ['before','after']:
 vals=[]
 for p in s.glob('startup_*_'+version+'.log'):
  vals.append(int(re.search(r'island was built in (\d+) ms',p.read_text(encoding='utf-8')).group(1)))
 startup[version]={'samples_ms':vals,'median_ms':statistics.median(vals)}
bench=json.loads((s/'build_bench.json').read_text())
report={'rows':rows,'colliders':after['colliders'],'global_physics_identical':True,'anchors_identical':True,'people_layout_styles_identical':True,'people_count':len(after['people']),'test_window':after['test_window'],'changed_baseline_files':changed,'unchanged_baseline_files':len(hashes)-len(changed),'all_old_glbs_and_terrain_cache_unchanged':True,'native_startup_series':startup,'warm_resource_build_bench':bench,'warm_resource_build_medians_ms':{v:statistics.median(x['ms'] for x in bench if x['version']==v) for v in ['before','after']},'gpu':after['gpu'],'renderer':after['renderer']}
(s/'audit.json').write_text(json.dumps(report,indent=2))
(s/'source_diff.patch').write_text(''.join(diff),encoding='utf-8')
print('PASS: 25/25 draws and triangles; 1498 global colliders, anchors and people exact; scope exact')
print(json.dumps({k:report[k] for k in ['native_startup_series','warm_resource_build_medians_ms']},indent=2))
