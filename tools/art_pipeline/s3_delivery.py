"""S3 evidence composition and source/asset audit. No screenshot retouching."""
from pathlib import Path
import hashlib,json,re
from PIL import Image,ImageDraw,ImageOps
ROOT=Path(__file__).resolve().parents[2];S=ROOT/'art_src/s3';OUT=S/'review';OUT.mkdir(exist_ok=True)
LABEL='iteration_4_verified'
before=S/'baseline';after=S/LABEL
cover=Image.open(ROOT/'art_src/reference/cover.jpg').convert('RGB')
CROPS={'roof':(180,450,1672,941),'pier':(1010,435,1672,941),'town':(0,0,825,560),'flight':(955,295,1672,941),'cafe':(660,510,1125,800),'beach':(850,400,1250,690),'headland':(1300,302,1600,490)}

def tile(src,w,h):return ImageOps.contain(src.convert('RGB'),(w,h),Image.Resampling.LANCZOS)
def row_sheet(names,path):
    sheet=Image.new('RGB',(960,len(names)*204),'#1d1d28');d=ImageDraw.Draw(sheet)
    for r,name in enumerate(names):
        group=name.split('_')[0];ref=cover.crop(CROPS[group]);images=[Image.open(before/(name+'.png')),Image.open(after/(name+'.png')),ref]
        for col,(im,label) in enumerate(zip(images,['S2 BEFORE','S3 AFTER','COVER CROP'])):
            x=col*320;y=r*204;d.text((x+6,y+5),name+' / '+label,fill='white')
            thumb=tile(im,320,180);sheet.paste(thumb,(x+(320-thumb.width)//2,y+24+(180-thumb.height)//2))
    sheet.save(path)

for group in ['roof','pier','town','flight']:
    row_sheet([group+'_golden',group+'_dusk'],OUT/(group+'_before_after_cover.png'))
row_sheet(['cafe_3m_golden','cafe_15m_golden','cafe_60m_golden'],OUT/'cafe_before_after_cover.png')
row_sheet(['beach_golden','headland_golden'],OUT/'ground_before_after_cover.png')
row_sheet(['roof_golden','pier_golden','cafe_3m_golden','headland_golden'],OUT/'summary_before_after_cover.png')
# Every raw capture is also shown in a labelled 2x2 viewing page, including governor 2.
paths=sorted(after.glob('*.png'))
for page in range((len(paths)+3)//4):
    im=Image.new('RGB',(960,588),'#1d1d28');d=ImageDraw.Draw(im)
    for j,p in enumerate(paths[page*4:page*4+4]):
        x=j%2*480;y=j//2*294;d.text((x+6,y+4),p.stem,fill='white');im.paste(tile(Image.open(p),480,270),(x,y+24))
    im.save(OUT/f'final_capture_page{page}.jpg')

b=json.loads((before/'metrics.json').read_text());a=json.loads((after/'metrics.json').read_text());pairs=[]
for old,new in zip(b['samples'],a['samples']):
    assert (old['view'],old['time'],old['governor'],old['camera'])==(new['view'],new['time'],new['governor'],new['camera'])
    pairs.append({'view':new['view'],'time':new['time'],'governor':new['governor'],'before':old,'after':new,'draw_pass':new['draw_calls']<=old['draw_calls'],'tri_pass':new['triangles']<=old['triangles']})
def build(label):
    text=(S/(label+'_Cams.log')).read_text(encoding='utf-8-sig')
    return int(re.search(r'island was built in (\d+) ms',text)[1])
base_hash=json.loads((before/'source_hashes.json').read_text());changed=[]
for rel,digest in base_hash.items():
    if hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()!=digest:changed.append(rel)
audit={'before_label':'baseline','after_label':LABEL,'pairs':pairs,'all_draws_nonincreasing':all(p['draw_pass'] for p in pairs),'all_tris_nonincreasing':all(p['tri_pass'] for p in pairs),'build_ms':[build('baseline'),build(LABEL)],'colliders':[b['colliders'],a['colliders']],'physics_shapes_identical':b['physics_shapes_sha256']==a['physics_shapes_sha256'],'anchors_identical':b['anchors']==a['anchors'],'changed_baseline_files':changed,'unchanged_baseline_files':len(base_hash)-len(changed),'contract':json.loads((S/'contract.json').read_text())}
(S/'audit.json').write_text(json.dumps(audit,indent=2),encoding='utf-8')
cat=json.loads((S/'kit_catalog.json').read_text())
locations={'cliff':'Town terrace banks, 30 decorative faces','crag':'Headland edge, 9 inset crags','rock':'Pipeline prototype; loaded as availability guard only, not placed in final scene','bush':'6 headland / hill plants','flower':'6 flowers beside the plants','rowboat':'2 moored non-solid rowboats beside existing marina','barrel':'4 pier / marina supply barrels','crate':'19 existing crate positions, original collision/RNG retained','planks':'2 stacked pier supplies; main decking uses a shader','palm':'Existing kind-2 palm locations via scenery loader; original collision/perch calls retained','table':'32 existing table positions, original table-top height retained','chair':'57 existing chair positions','plant':'Existing planters plus 3 small cafe pots (36 total kit placements)','plate':'3 decorative cafe table plates; no gameplay targets','drink':'3 decorative cafe drinks; no triggers or collectible logic'}
rows=[]
for key,data in cat.items():
    pack=data['pack'];url='https://kenney.nl/assets/'+pack
    source=data['source'].split('/x/',1)[1]
    rows.append(f"| {key} | [{pack}]({url}) | CC0 1.0 | `{source}` | `{data['output']}` | {data['tris']} | {locations[key]} |")
manifest='''# S3 third-party asset manifest

All source packs were already downloaded by the user. Read local `License.txt` before use; licence originals remain unchanged under `_quarantine/<pack>/x/License.txt`. No downloads or additional licences in S3.

Sources were inspected through their own supplied previews and actual Blender renders. `tools/blender/import_kenney.py` samples face-centre UV colours (or material factors when untextured), remaps the palette, bakes light AO/gradient, fits metre dimensions, creates genuinely split flat triangles and exports one vertex-colour surface without textures/cameras/lights. Full source/output SHA256, colour mappings, AO statistics and dimensions: `art_src/s3/kit_catalog.json`. Runtime shared material: `Art.material()`.

| Asset | Pack / official source | Licence | Source file within pack | Derived file | Tris | Used at / status |
|---|---|---|---|---|---:|---|
'''+ '\n'.join(rows)+'''

Rejected trials (NOT shipped): `pirate-kit/Models/GLB format/ship-small.glb`, CC0, official source https://kenney.nl/assets/pirate-kit . Whole ship was too ornate and its extracted `sail-a` did not meet the adaptation/shape gate. Derived trial files are retained in `art_src/s3/rejected/`; existing procedural sailboats remain. No new sailboat collision or bobbing logic was introduced. The original boats are statically batched; the spec's “bobbing as before” does not describe these existing source boats.

Not used: fantasy-town-kit, city-kit-suburban, blocky-characters. Existing authored houses, fries, gull and characters were retained. The previewed furniture `loungeChairRelax` was rejected as an indoor sofa. Food-kit fries previewed only; all interactive fries remain the existing game assets.
'''
(ROOT/'art_src/third_party/ASSET_MANIFEST.md').write_text(manifest,encoding='utf-8')
print(json.dumps({'build_ms':audit['build_ms'],'draws_pass':audit['all_draws_nonincreasing'],'tris_pass':audit['all_tris_nonincreasing'],'physics':audit['physics_shapes_identical'],'changed':changed,'assets':len(cat),'triangles_catalog':sum(v['tris'] for v in cat.values())},indent=2))
