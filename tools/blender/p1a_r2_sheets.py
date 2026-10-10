"""Review 2: measure existing captures and compose handoff sheets; no rendering."""
from pathlib import Path
import colorsys,hashlib,json,struct
from PIL import Image,ImageDraw,ImageFilter
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'art_src/p1a_review2'
FINAL=BASE/'iteration_3'

def sample(name):
    im=Image.open(FINAL/(name+'.png')).convert('RGB')
    mask=Image.open(FINAL/(name+'_mask.png')).convert('RGB')
    binary=Image.new('L',im.size)
    binary.putdata([255 if r>245 and g<30 and b>245 else 0 for r,g,b in mask.get_flattened_data()])
    binary=binary.filter(ImageFilter.MinFilter(3))
    pix=[c for c,m in zip(im.get_flattened_data(),binary.get_flattened_data()) if m]
    mean=[sum(c[i] for c in pix)/len(pix) for i in range(3)]
    return dict(pixels=len(pix),mean_rgb=mean,saturation_of_mean_pct=100*colorsys.rgb_to_hsv(*mean)[1],
        mean_pixel_saturation_pct=100*sum(colorsys.rgb_to_hsv(*c)[1] for c in pix)/len(pix))

colours={n:sample('colour_'+n) for n in ['noon_3m','golden_15m']}
colours['method']='Rendered 960x540. Visible UV body/chest/head, geometric N.L>.5; mask magenta R/B>245,G<30; eroded 1 pixel. Includes the blue-grey mantle on the body; excludes eyes/beak/wings. Self-shadow may be included. HSV saturation; no pixel retouching.'
(FINAL/'colour_measurements.json').write_text(json.dumps(colours,indent=2),encoding='utf-8')

sil={}
for label in ['level','up']:
    for kind in ['old','new']:
        im=Image.open(FINAL/f'silhouette_{kind}_{label}.png').convert('RGB')
        coords=[(x,y) for y in range(128) for x in range(128) if max(im.getpixel((x,y)))<40]
        sil[kind+'_'+label]={'width_px':max(x for x,y in coords)-min(x for x,y in coords)+1,
            'height_px':max(y for x,y in coords)-min(y for x,y in coords)+1,'black_pixels':len(coords)}
(FINAL/'silhouette_measurements.json').write_text(json.dumps(sil,indent=2),encoding='utf-8')

# GLB POSITION accessors are floats. Verify the praised merged face's geometry.
def glb_positions(path,node_name):
    raw=path.read_bytes();size,kind=struct.unpack_from('<II',raw,12)
    doc=json.loads(raw[20:20+size]);offset=20+size
    bs,bk=struct.unpack_from('<II',raw,offset);bin_=raw[offset+8:offset+8+bs]
    node=next(n for n in doc['nodes'] if n.get('name')==node_name)
    primitive=doc['meshes'][node['mesh']]['primitives'][0]
    a=doc['accessors'][primitive['attributes']['POSITION']];v=doc['bufferViews'][a['bufferView']]
    assert a['componentType']==5126 and a['type']=='VEC3'
    start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',12)
    return sorted(tuple(round(c,7) for c in struct.unpack_from('<fff',bin_,start+i*stride)) for i in range(a['count']))
old=glb_positions(BASE/'baseline/hero_gull_parts.glb','Head')
new=glb_positions(ROOT/'game/assets/models/hero_gull_parts.glb','Head')
assert old==new
hashes=json.loads((BASE/'baseline/source_hashes.json').read_text(encoding='utf-8'))
changed=[p for p,h in hashes.items() if hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
oldcode=(BASE/'baseline/gull_visual.gd').read_text(encoding='utf-8')
newcode=(ROOT/'game/scripts/player/gull_visual.gd').read_text(encoding='utf-8')
def method(code,name):
    value=code.split('func '+name+'(',1)[1]
    return value.split('\nfunc ',1)[0]
assert method(oldcode,'_build_procedural')==method(newcode,'_build_procedural')
assert method(oldcode,'pose')==method(newcode,'pose').replace('\n\tif authored:\n\t\t_pose_authored_fold()','')
allowed={'game/scripts/autotest.gd','game/scripts/player/gull_visual.gd','game/shaders/soft_toon.gdshader'}
assert set(changed)==allowed,changed
(BASE/'source_audit.json').write_text(json.dumps({'changed_existing_game_sources':changed,
    'review_script_added':'game/scripts/art/p1a_r2_review.gd','head_positions_identical':True,'head_vertices':len(new),
    'procedural_build_identical':True,'original_pose_calculations_identical_except_art_child_call':True,
    'files_unchanged':len(hashes)-len(changed)},indent=2),encoding='utf-8')

BG='#eee7dd';INK='#3a3d48'
def place(canvas,path,box):
    im=Image.open(path).convert('RGBA');im.thumbnail((box[2],box[3]),Image.Resampling.LANCZOS)
    canvas.paste(im,(box[0]+(box[2]-im.width)//2,box[1]+(box[3]-im.height)//2),im)

def text(draw,xy,s):draw.text(xy,s,fill=INK)
sheet=Image.new('RGB',(960,540),BG);d=ImageDraw.Draw(sheet)
text(d,(12,8),'REVIEW 2 / FINAL ITERATION 3    Procedural -> authored gull')
for row,label in enumerate(['flight','perch']):
    for col,kind in enumerate(['before','after']):
        x=col*320;y=35+row*213
        text(d,(x+8,y),label+' / '+('old procedural' if kind=='before' else 'new authored'))
        place(sheet,FINAL/f'{label}_{kind}.png',(x,y+19,320,180))
text(d,(664,35),'128 px / SAME CAMERA AND SCALE')
for row,label in enumerate(['level','up']):
    for col,kind in enumerate(['old','new']):
        x=656+col*148;y=70+row*180
        text(d,(x,y),kind+' / '+label)
        place(sheet,FINAL/f'silhouette_{kind}_{label}.png',(x,y+20,128,128))
text(d,(12,484),'Old 1464 tris / 22 parts / 16 mats     New 3804 tris / 11 parts / 1 mat')
text(d,(12,505),'Level span +19.3% / Up span +20.5%    Main-pass meshes: flight 18 -> 10, perch 22 -> 11')
sheet.save(BASE/'before_after.png')
sheet=Image.new('RGB',(960,370),BG);d=ImageDraw.Draw(sheet)
for col,key in enumerate(['noon_3m','golden_15m']):
    x=col*480;v=colours[key]
    text(d,(x+8,10),key+' / body sunlight mask, N.L > 0.5')
    place(sheet,FINAL/f'colour_{key}.png',(x,32,480,270))
    text(d,(x+8,315),'Mean RGB: '+', '.join(f'{n:.1f}' for n in v['mean_rgb']))
    text(d,(x+8,335),f"HSV S: {v['saturation_of_mean_pct']:.2f}% / n={v['pixels']} / limit <12%")
sheet.save(BASE/'colour_check.png')
sheet=Image.new('RGB',(512,486),BG);d=ImageDraw.Draw(sheet)
for i,label in enumerate(['max_up','max_down','flare','dive','fold_mid','perch_profile']):
    x=i%2*256;y=i//2*162
    text(d,(x+5,y+2),label)
    name=label if label=='perch_profile' else 'joint_'+label
    place(sheet,FINAL/(name+'.png'),(x,y+18,256,144))
sheet.save(BASE/'joints.png')
print(json.dumps({'colour':colours,'silhouette':sil,'changed':changed},indent=2))
