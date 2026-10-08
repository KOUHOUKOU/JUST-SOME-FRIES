import subprocess, sys, numpy as np
def load(path, sr=16000):
    p = subprocess.run(["ffmpeg","-v","error","-i",path,"-ac","1","-ar",str(sr),"-f","f32le","-"],capture_output=True,check=True)
    return np.frombuffer(p.stdout,dtype="<f4"), sr
if __name__=="__main__":
    path=sys.argv[1]; step=float(sys.argv[2]) if len(sys.argv)>2 else 4.0
    x,sr=load(path)
    n=int(step*sr)
    rms=[20*np.log10(np.sqrt(np.mean(x[i:i+n]**2))+1e-9) for i in range(0,len(x)-n,n)]
    mx=max(rms)
    for k,r in enumerate(rms):
        print("%5.0f s %6.1f dB %s"%(k*step,r,"#"*int(max(0,(r-mx+40))*1.2)))
