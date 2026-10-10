"""Repaint existing house COLOR_0 only. No geometry, indices, bounds or rigs change.
Reads immutable S3b baseline GLBs; safe to rerun without accumulating colour edits.
"""
from pathlib import Path
import json,struct,hashlib
import numpy as np
R=Path(__file__).resolve().parents[2];S=R/'art_src/s3b'
old=[('F0DFC0','954D35'),('DEA08A','32646B'),('E1C578','A95646'),('91B5B4','9E5539'),('C997A1','336C70'),('EAD6B7','B56946')]
new=[('EAD5AA','B83C26'),('DF9567','AA3524'),('E9BB59','BC492E'),('BAC38B','AD4028'),('E0BB82','BE5131'),('E7D2A7','AB3D27')]
records=json.loads((R/'art_src/p1b/baseline/catalog.json').read_text())['houses']
def lin(s):
    c=np.array([int(s[i:i+2],16)/255 for i in (0,2,4)])
    return np.where(c<=.04045,c/12.92,((c+.055)/1.055)**2.4)
def unit(c):return c/np.maximum(np.linalg.norm(c,axis=-1,keepdims=True),1e-8)
audit=[]
for i,rec in enumerate(records):
    name=f'house_{i:02d}.glb';p=S/'baseline/source/game/assets/models'/name
    b=bytearray(p.read_bytes());n=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+n]);start=28+n
    def array(aidx):
        a=j['accessors'][aidx];v=j['bufferViews'][a['bufferView']]
        assert a['componentType']==5126 and 'byteStride' not in v
        return np.ndarray((a['count'],{'VEC3':3,'VEC4':4}[a['type']]),dtype='<f4',buffer=b,offset=start+v.get('byteOffset',0)+a.get('byteOffset',0))
    att=j['meshes'][0]['primitives'][0]['attributes'];c=array(att['COLOR_0']);pos=array(att['POSITION'])
    before=c[:,:3].copy();idx=(i*5+42)%6;h=rec['params'][4];counts=[]
    for k in [0,1]:
        src=lin(old[idx][k]);dst=lin(new[idx][k])
        if rec['params'][0]==-93 and k==0:dst=lin('EEE4CC')
        mask=np.linalg.norm(unit(before)-unit(src),axis=1)<(.035 if k==0 else .065)
        mask&=(pos[:,1]<h-.12 if k==0 else pos[:,1]>h-.20)
        c[mask,:3]=np.clip(before[mask]*dst/src,0,1)
        counts.append(int(mask.sum()))
    out=R/'game/assets/models'/name;out.write_bytes(b)
    # No JSON or non-colour accessor bytes may have changed.
    verify=bytearray(b);ac=j['accessors'][att['COLOR_0']];v=j['bufferViews'][ac['bufferView']]
    lo=start+v.get('byteOffset',0);hi=lo+v['byteLength'];orig=p.read_bytes();verify[lo:hi]=orig[lo:hi]
    assert verify==orig
    audit.append({'asset':name,'wall_roof_vertices':counts,'palette':new[idx],'source_sha256':hashlib.sha256(orig).hexdigest(),'output_sha256':hashlib.sha256(b).hexdigest(),'only_COLOR_0_changed':True})
(S/'house_palette.json').write_text(json.dumps(audit,indent=2))
print('Repainted',len(audit),'existing houses; geometry untouched')
