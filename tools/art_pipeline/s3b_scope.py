"""Scoped source and colour-only GLB audit against immutable S3b starting files."""
from pathlib import Path
import re,json,hashlib,difflib,struct
R=Path(__file__).resolve().parents[2];S=R/'art_src/s3b';B=S/'baseline/source'
def read(p):return p.read_text(encoding='utf-8')
def funcs(p):
    t=read(p);m=list(re.finditer(r'^(?:static )?func (\w+)\(',t,re.M))
    return {v[1]:t[v.start():(m[i+1].start() if i+1<len(m) else len(t))].strip() for i,v in enumerate(m)}
allowed={
 'world/world_builder.gd':['_headland'],
 'world/batcher.gd':['_init','ball','flush'],
 'world/terrain.gd':['build_mesh'],
 'world/day_cycle.gd':['_apply'],
 'world/cover_atmosphere.gd':['finish'],
 'art/kenney_parts.gd':['ground','cafe'],
 'art/s3_review.gd':['run'],
 'art/s3_contract.gd':['run'],
 'autotest.gd':['_ready'],
 'art/s3b_bake_terrain.gd':[],
}
report={'changed_functions':{},'unapproved_changes':[],'house_geometry_identical':True}
hashes=json.loads((S/'baseline/source_hashes.json').read_text())
changed=[f for f,h in hashes.items() if hashlib.sha256((R/f).read_bytes()).hexdigest()!=h]
for rel in changed:
    if rel.endswith('.gd'):
        sub=rel.removeprefix('game/scripts/');before=funcs(B/rel);after=funcs(R/rel)
        dif=[name for name,body in before.items() if after.get(name)!=body]
        report['changed_functions'][sub]=dif
        report['unapproved_changes'] += [sub+':'+n for n in dif if n not in allowed.get(sub,[])]
    if rel.endswith('.glb'):
        assert Path(rel).name.startswith('house_')
        b=(B/rel).read_bytes();a=bytearray((R/rel).read_bytes());n=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+n]);start=28+n
        for m in j['meshes']:
            for p in m['primitives']:
                acc=j['accessors'][p['attributes']['COLOR_0']];v=j['bufferViews'][acc['bufferView']];lo=start+v.get('byteOffset',0);hi=lo+v['byteLength'];a[lo:hi]=b[lo:hi]
        assert a==b,rel
    if rel.startswith('game/shaders/'):assert Path(rel).name in ['soft_toon.gdshader','sea.gdshader','ground.gdshader','decking.gdshader']
assert not report['unapproved_changes'],report
# Clock, sun target, progression/saturation/ending overrides, all world functions except
# the explicitly non-colliding lighthouse paint rings remain byte-for-byte identical.
old=read(B/'game/scripts/world/world_builder.gd');new=read(R/'game/scripts/world/world_builder.gd')
assert old.replace('3.45 - i * 0.2, 1.2, "D96D5F", false','3.46, 2.15, "B94837", false')==new
for name in ['_process','compute_target','_place_sun']:assert funcs(B/'game/scripts/world/day_cycle.gd')[name]==funcs(R/'game/scripts/world/day_cycle.gd')[name]
old=read(B/'game/scripts/world/day_cycle.gd');new=read(R/'game/scripts/world/day_cycle.gd')
assert old[old.index('\t# colour: richer'):]==new[new.index('\t# colour: richer'):]
report['changed_files']=changed
report['unchanged_baseline_files']=len(hashes)-len(changed)
report['terrain_cache_bytes']=(R/'game/assets/models/terrain_s3b.res').stat().st_size
report['terrain_cache_sha256']=hashlib.sha256((R/'game/assets/models/terrain_s3b.res').read_bytes()).hexdigest()
report['world_builder_only_non_solid_ring_paint']=True
report['day_clock_sun_target_ending_sense_unchanged']=True
report['gameplay_files_unchanged']=[f for f in hashes if f not in changed and f.endswith('.gd')]
(S/'source_scope.json').write_text(json.dumps(report,indent=2))
diff=''.join(''.join(difflib.unified_diff(read(B/f).splitlines(True),read(R/f).splitlines(True),fromfile='baseline/'+f,tofile=f)) for f in changed if f.endswith(('.gd','.gdshader')))
(S/'source_diff.patch').write_text(diff,encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['changed_files','gameplay_files_unchanged','changed_functions']},indent=2))
