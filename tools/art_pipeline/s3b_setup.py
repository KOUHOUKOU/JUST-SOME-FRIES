"""Immutable starting evidence for the second S3 review round."""
from pathlib import Path
import hashlib,json,shutil
R=Path(__file__).resolve().parents[2]
S=R/'art_src/s3b';B=S/'baseline'
assert not B.exists(), 'Do not overwrite the S3b baseline'
B.mkdir(parents=True)
hashes={}
for folder in ['game/scripts','game/shaders','game/scenes','game/assets/models','game/assets/art/kenney']:
    for p in (R/folder).rglob('*'):
        if p.is_file() and p.suffix not in ['.import','.uid']:
            rel=p.relative_to(R);hashes[str(rel).replace('\\','/')]=hashlib.sha256(p.read_bytes()).hexdigest()
            dst=B/'source'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)
p=R/'game/project.godot';hashes['game/project.godot']=hashlib.sha256(p.read_bytes()).hexdigest()
shutil.copy2(p,B/'source/game/project.godot')
(B/'source_hashes.json').write_text(json.dumps(hashes,indent=2))
shutil.copytree(R/'art_src/s3/iteration_4_verified',S/'s3_reference')
shutil.copy2(R/'art_src/s3/iteration_4_verified_Cams.log',S/'s3_reference_Cams.log')
launcher=(R/'tools/art_pipeline/run_s3.ps1').read_text(encoding='utf-8-sig')
launcher=launcher.replace("art_src/s3'","art_src/s3b'").replace("'--art-s3',","'--art-s3','--art-s3b',")
launcher=launcher.replace("'--art-s3')","'--art-s3','--art-s3b')")
(R/'tools/art_pipeline/run_s3b.ps1').write_text(launcher,encoding='utf-8-sig')
print('S3b baseline saved',len(hashes))
