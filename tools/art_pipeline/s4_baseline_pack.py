"""Size reference: exact backed-up source + current non-art assets, no new art.
This is a reconstruction, not a claim that a pristine historical binary exists.
Called under run_s4.ps1's project-local environment.
"""
from pathlib import Path
import subprocess,json,hashlib
R=Path(__file__).resolve().parents[2];P=R/'art_src/_orig_build';O=R/'art_src/final'
paths=[P/'scripts/main.gd',P/'scripts/autotest.gd',P/'export_presets.cfg']
saved={p:p.read_bytes() for p in paths}
try:
    for p in paths[:2]:p.write_bytes((R/'backup/pre_art_round14'/p.relative_to(P)).read_bytes())
    cfg=paths[2].read_text(encoding='utf-8').replace('exclude_filter=""','exclude_filter="assets/art/*,assets/models/*,scripts/art/*"')
    paths[2].write_text(cfg,encoding='utf-8')
    (O/'original_size_export_presets.cfg').write_text(cfg,encoding='utf-8')
    cmd=[r'D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe','--headless','--path',str(P),'--log-file',str(O/'OriginalPack.log'),'--export-pack','Windows Desktop',str(O/'original_reference.pck')]
    with (O/'OriginalPack_console.log').open('w',encoding='utf-8') as log:
        code=subprocess.call(cmd,stdout=log,stderr=subprocess.STDOUT)
    target=O/'original_reference.pck'
    data={'status':'reconstructed pre-art size reference; current non-art assets, not a retained original binary','exit_code':code,'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'excluded':'assets/art/*,assets/models/*,scripts/art/*','source':'backup/pre_art_round14; exact source restored for export'}
    (O/'original_size_reference.json').write_text(json.dumps(data,indent=2))
    print(json.dumps(data))
    raise SystemExit(code)
finally:
    for p,data in saved.items():p.write_bytes(data)
