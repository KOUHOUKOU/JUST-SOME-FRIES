"""Preserve S6 input and install bounded S7 measurement hooks, no asset edits."""
from pathlib import Path
import shutil,json,hashlib
R=Path(__file__).resolve().parents[2]; S=R/'art_src/s7'; S.mkdir(exist_ok=True)
if (S/'baseline/hashes.json').exists():raise SystemExit('S7 baseline already frozen; refusing to overwrite evidence')
for d in ['scripts','shaders']:
    shutil.copytree(R/'game'/d,S/'baseline/source/game'/d,dirs_exist_ok=True)
files=list((R/'game').rglob('*.gd'))+list((R/'game/shaders').glob('*'))+list((R/'game/assets').rglob('*.glb'))+list((R/'game/assets/models').glob('*.res'))
(S/'baseline/hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files if p.is_file()},indent=2))
shutil.copy2(R/'game/assets/models/s6/headland.glb',S/'baseline/headland.glb')
# Derive the review from S6, preserving identical shape hashing and sampling.
s=(R/'game/scripts/art/s6_review.gd').read_text(encoding='utf8').replace('s6','s7').replace('S6','S7')
s=s.replace('report.anchors=str(main.world.anchors)','report.anchors=str(main.world.anchors);report.thermals=str(main.world.air_zones)')
start=s.index('\t# Production title');end=s.index('\tFileAccess.open',start)
s=s[:start]+'''\tgovernor.level=2;governor._apply();check_lite(main)
\tfor idx in [0,3,4,5]:
\t\tvar v=views[idx]
\t\tawait capture([v[0],Vector3(v[1][0],v[1][1],v[1][2]),Vector3(v[2][0],v[2][1],v[2][2]),v[3]],"golden",2,false)
\tgovernor.level=3;governor._apply();check_lite(main)
\tassert(not main.world.sun.shadow_enabled)
\tgovernor.level=0;governor._apply()
\tGS.web=true;governor._apply();check_lite(main);GS.web=false
\treport.governor={"forced_2_3_and_web_lite":"PASS","auto_adjustment":"disabled by existing <=30fps/paused guard"}
''' + s[end:]
(R/'game/scripts/art/s7_review.gd').write_text(s,encoding='utf8')
p=R/'game/scripts/autotest.gd';s=p.read_text(encoding='utf8')
s=s.replace('if "--art-s6" in OS.get_cmdline_user_args():shots=', 'if "--art-s7" in OS.get_cmdline_user_args():shots=ProjectSettings.globalize_path("res://../art_src/s7/autotest/")\n\tif "--art-s6" in OS.get_cmdline_user_args():shots=',1)
needle='\tif "--art-s6" in OS.get_cmdline_user_args():\n\t\tvar review='
idx=s.index(needle)
s=s[:idx]+'''\tif "--art-s7" in OS.get_cmdline_user_args():
\t\tvar review=load("res://scripts/art/s7_review.gd").new();add_child(review)
\t\tawait review.run(main,shots);return
'''+s[idx:];p.write_text(s,encoding='utf8')
views=[['headland_east',[-58,40,86],[-100,17,38],62],['headland_sea',[-111,28,164],[-102,19,40],62],['headland_west',[-210,38,77],[-104,17,40],62]]
t=[-11.5,.85,6.2];import math
v=[1,.8,1.4];length=math.sqrt(sum(x*x for x in v))
for d in [3,15,60]:views.append(['cafe_'+str(d)+'m',[t[i]+v[i]/length*d for i in range(3)],t,55])
(S/'cams.json').write_text(json.dumps(views,indent=2))
