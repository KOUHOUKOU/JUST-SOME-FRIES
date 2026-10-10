"""Source-scope and capture metrics audit. Run after the final in-game review."""
from pathlib import Path
import hashlib,json,re,sys
root=Path.cwd();base=root/'art_src/s2/baseline';dst=root/'art_src/s2'
hashes=json.loads((base/'hashes.json').read_text());changed=[];same=[]
for rel,old in hashes.items():
    target=root/'game'/rel
    (same if hashlib.sha256(target.read_bytes()).hexdigest()==old else changed).append(rel)
def funcs(text):
    marks=list(re.finditer(r'^func (\w+)\(',text,re.M));out={}
    for i,m in enumerate(marks):out[m[1]]=text[m.start():marks[i+1].start() if i+1<len(marks) else len(text)].strip()
    return out
def compare(path,names):
    a=funcs((base/path).read_text(encoding='utf8'));b=funcs((root/'game'/path).read_text(encoding='utf8'))
    return {k:a[k]==b[k] for k in names}
checks={}
checks['day_progress_and_sun_quest']=compare('scripts/world/day_cycle.gd',['compute_target','_process','_place_sun'])
# Added helpers are below _place_sun: compare its body without the following comment.
checks['day_progress_and_sun_quest']['_place_sun']=funcs((base/'scripts/world/day_cycle.gd').read_text())['_place_sun'].splitlines()==funcs((root/'game/scripts/world/day_cycle.gd').read_text())['_place_sun'].split('# Four art keys')[0].strip().splitlines()
wb=funcs((base/'scripts/world/world_builder.gd').read_text(encoding='utf8'))
changed_visual={'build','_environment','_terrain','lamp','_pier','_headland','_distant'}
checks['unchanged_world_functions']=compare('scripts/world/world_builder.gd',[k for k in wb if k not in changed_visual])
checks['main_only_wiring']=(root/'game/scripts/main.gd').read_text(encoding='utf8').replace('\n\tday.atmosphere = world.get("cover_atmosphere")','')==(base/'scripts/main.gd').read_text(encoding='utf8')
checks['project_settings_identical']=(root/'game/project.godot').read_bytes()==(base/'project.godot').read_bytes()
assert all(checks['day_progress_and_sun_quest'].values())
assert all(checks['unchanged_world_functions'].values()) and checks['main_only_wiring'] and checks['project_settings_identical']
label=sys.argv[1] if len(sys.argv)>1 else 'iteration_4'
a=json.loads((base/'metrics.json').read_text());b=json.loads((dst/label/'metrics.json').read_text());pairs=[]
for x,y in zip(a['samples'],b['samples']):
    assert (x['view'],x['time'])==(y['view'],y['time'])
    pairs.append({'view':x['view'],'time':x['time'],'before':x,'after':y,'frame_change_pct':100*(y['frame_ms']/x['frame_ms']-1),'draw_change':y['draw_calls']-x['draw_calls']})
timing_worst={}
for key in ['render_cpu_ms','render_gpu_ms']:
    p=max(pairs,key=lambda p:p['after'][key]/p['before'][key])
    timing_worst[key]={'view':p['view'],'time':p['time'],'before':p['before'][key],'after':p['after'][key],'change_pct':100*(p['after'][key]/p['before'][key]-1)}
report={'unchanged_source_count':len(same),'changed_existing_sources':changed,'checks':checks,'pairs':pairs,'max_frame_change_pct':max(p['frame_change_pct'] for p in pairs),'max_draw_change':max(p['draw_change'] for p in pairs),'colliders_before_after':[a['colliders'],b['colliders']],'performance_gate':'UNVERIFIED: 30 fps cap obscures throughput; render CPU/GPU regressions remain unresolved','worst_render_timing':timing_worst}
(dst/'audit.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in report.items() if k not in ['checks','pairs']},indent=2))
