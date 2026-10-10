"""Rebuild pre-art code with current assets; all writes stay in the project."""
from pathlib import Path
import shutil, json, hashlib
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'art_src/final'
ORIG = ROOT / 'art_src/_orig_build'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def inventory(base):
    return {str(p.relative_to(base)): {'bytes':p.stat().st_size,'sha256':sha(p)} for p in base.rglob('*') if p.is_file()}
OUT.mkdir(parents=True, exist_ok=True)
if not (OUT/'pre_delivery_sizes.json').exists():
    (OUT/'pre_delivery_sizes.json').write_text(json.dumps({d:inventory(ROOT/d) for d in ['build','web']},indent=2))
if ORIG.exists(): raise SystemExit('Original copy already exists; refusing to replace it')
ORIG.mkdir()
for name in ['scripts','shaders','scenes']:
    shutil.copytree(ROOT/'backup/pre_art_round14'/name, ORIG/name)
shutil.copy2(ROOT/'backup/pre_art_round14/project.godot',ORIG/'project.godot')
shutil.copytree(ROOT/'game/assets', ORIG/'assets')
shutil.copy2(ROOT/'game/export_presets.cfg', ORIG/'export_presets.cfg')
# Test etiquette only. The old backup predates the NO_FOCUS fix.
for rel in ['scripts/main.gd','scripts/ui/menus.gd']:
    p=ORIG/rel
    s=p.read_text(encoding='utf-8').replace('Input.mouse_mode = Input.MOUSE_MODE_CAPTURED','Input.mouse_mode = Input.MOUSE_MODE_VISIBLE')
    if rel.endswith('main.gd'):
        s=s.replace('func _ready():','func _ready():\n\tDisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)',1)
    p.write_text(s,encoding='utf-8')
for base in [ROOT/'game',ORIG]:
    (base/'scripts/art').mkdir(exist_ok=True)
    shutil.copy2(ROOT/'tools/art_pipeline/s4_review.gd',base/'scripts/art/s4_review.gd')
    p=base/'scripts/autotest.gd';s=p.read_text(encoding='utf-8')
    s=s.replace('func cams_test():','func cams_test():\n\tif "--art-s4" in OS.get_cmdline_user_args():\n\t\tvar review=load("res://scripts/art/s4_review.gd").new();add_child(review)\n\t\tawait review.run(main);return',1)
    p.write_text(s,encoding='utf-8')
views=json.loads((ROOT/'art_src/s6/cams.json').read_text())
views=[v for v in views if v[0] in ['01_opening_roof','03_boardwalk_market','04_beach','06_marina','07_harbor_cranes','09_town_stairs','12_farm','15_headland','17_sea_low','22_pier']]
t=[-11.5,.85,6.2];d=[1,.8,1.4];length=sum(x*x for x in d)**.5
views[1:1]=[[f'cafe_{n}m',[t[i]+d[i]/length*n for i in range(3)],t,55] for n in [3,15]]
views += [['gull_fry',[-10.3,6.07,-3.8],[-11.6,5.32,-.8],44],['fry_table',[-9.2,2.5,6.7],[-10.8,1.1,4.2],42]]
(OUT/'cameras.json').write_text(json.dumps(views,indent=2))
diff=[]
for p in (ROOT/'backup/pre_art_round14').rglob('*'):
    if not p.is_file() or p.name=='AGENTS.md':continue
    q=ORIG/p.relative_to(ROOT/'backup/pre_art_round14')
    if sha(p)!=sha(q):diff.append(str(q.relative_to(ORIG)))
(OUT/'original_provenance.json').write_text(json.dumps({'base':'backup/pre_art_round14','assets':'game/assets at S4 setup','instrumentation_only_changes':diff,'backup_hashes':inventory(ROOT/'backup/pre_art_round14')},indent=2))
print('Original prepared; test-only differences:',diff)
