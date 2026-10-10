"""Encode the one real capture. No narration, mock-ups, speed change or audio replacement."""
from pathlib import Path
import subprocess,json,sys
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[2];O=R/'art_src/final';F=R/'film'
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',18)
def call(args):subprocess.run(args,check=True)
if '--inspect' in sys.argv:
    q=O/'film_qa';q.mkdir(exist_ok=True)
    call(['ffmpeg','-y','-v','error','-threads','2','-i',str(F/'art_remaster_raw.avi'),'-vf','fps=1/2,scale=320:180','-threads','2',str(q/'%02d.jpg')])
    files=sorted(q.glob('*.jpg'))
    im=Image.new('RGB',(1280,((len(files)+3)//4)*204),'#25252d');d=ImageDraw.Draw(im)
    for i,p in enumerate(files):
        x=i%4*320;y=i//4*204;im.paste(Image.open(p),(x,y+24));d.text((x+5,y+2),f'raw ~{i*2+1:02d}s',font=font,fill='white')
    im.save(O/'film_qa_contact.jpg',quality=94)
else:
    # Drop the menu setup second and stop after reaching the lighthouse approach.
    call(['ffmpeg','-y','-v','error','-threads','2','-ss','1','-i',str(F/'art_remaster_raw.avi'),'-t','40','-map','0:v:0','-map','0:a:0?',
          '-c:v','libx264','-threads','2','-crf','21','-preset','fast','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',str(F/'art_remaster_preview.mp4')])
    frames=O/'frames';frames.mkdir(exist_ok=True)
    times=[.3,3,6,13.5,14.9,16.8,22,35]
    names=['roof','takeoff','pier_ferris','dive','rhythm_ring','snatch','town','lighthouse']
    sheet=Image.new('RGB',(1920,4*564),'#25252d');d=ImageDraw.Draw(sheet)
    for i,(t,name) in enumerate(zip(times,names)):
        p=frames/f'{i+1:02d}_{name}.png'
        call(['ffmpeg','-y','-v','error','-threads','2','-ss',str(t),'-i',str(F/'art_remaster_preview.mp4'),'-frames:v','1','-threads','2',str(p)])
        x=i%2*960;y=i//2*564;sheet.paste(Image.open(p).resize((960,540)),(x,y+24));d.text((x+6,y+2),f'{t:.1f}s / {name}',font=font,fill='white')
    sheet.save(O/'preview_frames.jpg',quality=94)
    data=subprocess.check_output(['ffprobe','-v','error','-show_streams','-show_format','-of','json',str(F/'art_remaster_preview.mp4')])
    (O/'clip_probe.json').write_bytes(data)
    call(['ffmpeg','-v','info','-threads','2','-i',str(F/'art_remaster_preview.mp4'),'-vn','-af','volumedetect','-f','null','-'])
