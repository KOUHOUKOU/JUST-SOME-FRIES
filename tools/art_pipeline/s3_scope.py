from pathlib import Path
import difflib,json,re
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'art_src/s3'
def read(p):return p.read_text(encoding='utf-8')
def funcs(p):
    s=read(p);starts=list(re.finditer(r'^func (\w+)\([^\n]*\):',s,re.M))
    return {m[1]:s[m.start():(starts[i+1].start() if i+1<len(starts) else len(s))].strip() for i,m in enumerate(starts)}
b=funcs(out/'baseline/source/game/scripts/world/world_builder.gd');a=funcs(ROOT/'game/scripts/world/world_builder.gd')
same=[];changed=[];renamed={}
for n,body in b.items():
    if n in ['chair','table','planter','crate','patio_umbrella']:
        newname='_'+n+'_procedural';renamed[n]=body.replace('func '+n+'(', 'func '+newname+'(',1)==a[newname]
    elif n in a and body==a[n]:same.append(n)
    else:changed.append(n)
assert all(renamed.values()),renamed
record={'identical_world_functions':same,'changed_world_functions':changed,'renamed_procedural_bodies_identical':renamed}
audio='game/scripts/systems/audio_manager.gd'
record['concurrent_audio_change_not_authored_by_s3']=''.join(difflib.unified_diff(read(out/'baseline/source'/audio).splitlines(True),read(ROOT/audio).splitlines(True),fromfile='S3 baseline',tofile='Current concurrent change'))
(out/'source_scope.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record,indent=2))
