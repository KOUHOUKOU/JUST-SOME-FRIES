"""Summarize measured evidence without turning a native run into a web claim."""
from pathlib import Path
import json,re,statistics,hashlib,difflib
R=Path(__file__).resolve().parents[2];S=R/'art_src/s7'
def load(p):return json.loads(p.read_text(encoding='utf8'))
def runs(prefix):
 rows=[]
 for i in range(5):
  p=S/f'{prefix}_cold_{i}.log';s=p.read_text(encoding='utf8')
  assert 'SCRIPT ERROR' not in s
  rows.append({'log':p.name,'build_ms':int(re.search(r'island was built in (\d+) ms',s)[1]),'profile_us_count':json.loads(re.search(r'\[S7_PROFILE\] (.*)',s)[1]),'first_frame':json.loads(re.search(r'\[S7_FIRST_FRAME\] (.*)',s)[1])})
 keys=sorted(set(k for row in rows for k in row['profile_us_count']))
 return {'runs':rows,'median_ms':statistics.median(x['build_ms'] for x in rows),'profile_median_ms':{k:statistics.median(x['profile_us_count'].get(k,[0])[0]/1000 for x in rows) for k in keys},'first_frame_ticks_median_ms':statistics.median(x['first_frame']['ticks_ms'] for x in rows)}
a=load(S/'baseline/game/metrics.json');b=load(S/'iteration_4_verified/game/metrics.json')
rows=[]
for x,y in zip(a['samples'],b['samples']):
 assert x['camera']==y['camera'] and x['view']==y['view'] and x['governor']==y['governor']
 rows.append({'view':x['view'],'governor':x['governor'],'before':x,'after':y,'draw_delta':y['draw_calls']-x['draw_calls'],'tris_delta':y['triangles']-x['triangles']})
assert len(a['people'])==len(b['people'])==171
assert all(x['style']==y['style'] for x,y in zip(a['people'],b['people']))
people_moved=[{'before':x['position'],'after':y['position']} for x,y in zip(a['people'],b['people']) if x['position']!=y['position']]
audit={'engine':'Godot 4.7.1 Compatibility, native Windows, RTX 5070 Ti Laptop GPU','resolution':[960,540],'fps_cap':30,'cold_definition':'Five independent processes; OS disk and shader caches were not flushed. No browser run/export.','baseline':runs('baseline_valid'),'final':runs('final'),'historical_pre_s6_target_ms':916,'camera_rows':rows,'draws_all_lower':all(x['draw_delta']<0 for x in rows),'triangles_regression_rows':[x for x in rows if x['tris_delta']>0],'people_styles_exact':171,'people_moved_with_ground':people_moved,'contract':load(S/'contract.json')['s7']}
audit['target_pass']=audit['final']['median_ms']<=916
hashes=load(S/'baseline/hashes.json');changed=[];patch=[]
for p,h in hashes.items():
 q=R/p
 if not q.exists() or hashlib.sha256(q.read_bytes()).hexdigest()!=h:
  changed.append(p)
  old=S/'baseline/source'/p
  if old.exists() and q.exists():patch.extend(difflib.unified_diff(old.read_text(encoding='utf8').splitlines(True),q.read_text(encoding='utf8').splitlines(True),fromfile='S6/'+p,tofile='S7/'+p))
audit['baseline_files_changed']=changed
audit['existing_glbs_unchanged']=not any(p.endswith('.glb') for p in changed)
audit['new_resources']={p.relative_to(R).as_posix():{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in (R/'game/assets/models/s7').glob('*') if p.suffix in ['.glb','.res']}
# Physics changes are restricted by the executable contract, not by a hash equality claim.
audit['scope']='Local headland terrain lowered 24 to 12; 68 collider origins and 2 anchors follow it. Other collision shapes, other anchors and thermals exact. Five local NPCs follow ground.'
(S/'source_diff.patch').write_text(''.join(patch),encoding='utf8')
(S/'audit.json').write_text(json.dumps(audit,indent=2),encoding='utf8')
print(json.dumps({k:audit[k] for k in ['target_pass','draws_all_lower','existing_glbs_unchanged','baseline_files_changed']},indent=2))
print('Cold medians',audit['baseline']['median_ms'],audit['final']['median_ms'])
print('Profiles',audit['baseline']['profile_median_ms'],audit['final']['profile_median_ms'])
