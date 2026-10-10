from pathlib import Path
R=Path(__file__).resolve().parents[2]/'game/scripts'
def edit(p,fn):
 p=R/p;s=p.read_text(encoding='utf8');p.write_text(fn(s),encoding='utf8')
def addprof(s):return s.replace('extends RefCounted','extends RefCounted\nconst Prof=preload("res://scripts/art/s7_profile.gd")',1)
def art(s):
 s=addprof(s).replace('var packed = ResourceLoader.load', 'var profile_t=Prof.start()\n\tvar packed = ResourceLoader.load')
 s=s.replace('\tvar instance = packed.instantiate()', '\tProf.end("GLB load",profile_t)\n\tprofile_t=Prof.start()\n\tvar instance = packed.instantiate()')
 return s.replace('\treturn instance','\tProf.end("GLB instantiate validate",profile_t)\n\treturn instance',1)
edit(Path('art/art_loader.gd'),art)
def person(s):
 s=addprof(s).replace('\t# Reuse per-region','\tvar profile_t=Prof.start()\n\t# Reuse per-region')
 return s.replace('\tvariants[key] = result','\tProf.end("person tint merge upload",profile_t)\n\tvariants[key] = result')
edit(Path('art/person_parts.gd'),person)
def batch(s):
 s=addprof(s).replace('func cover_piece(mesh,c,xf):','func cover_piece(mesh,c,xf):\n\tvar profile_t=Prof.start()')
 s=s.replace('\tauthored(cover_meshes[key],xf)','\tProf.end("primitive paint cache",profile_t)\n\tauthored(cover_meshes[key],xf)')
 s=s.replace('func authored(mesh, xf):','func authored(mesh, xf):\n\tvar profile_t=Prof.start()')
 s=s.replace('\tart_tools[key].append_from(mesh, 0, xf)','\tart_tools[key].append_from(mesh, 0, xf)\n\tProf.end("district append",profile_t)')
 s=s.replace('func flush():','func flush():\n\tvar profile_t=Prof.start()')
 return s+'\n\tProf.end("batch commit upload",profile_t)\n'
edit(Path('world/batcher.gd'),batch)
def tree(s):
 s=addprof(s).replace('static func flush_trees(w):','static func flush_trees(w):\n\tvar profile_t=Prof.start()')
 return s.replace('\t_trees.clear()','\t_trees.clear()\n\tProf.end("tree MultiMesh setup",profile_t)')
edit(Path('art/scenery_parts.gd'),tree)
def terrain(s):
 s=addprof(s).replace('static func ground_material():','static func ground_material():\n\tvar profile_t=Prof.start()')
 return s.replace('\treturn m\n','\tProf.end("ground noise material",profile_t)\n\treturn m\n',1)
edit(Path('world/terrain.gd'),terrain)
def main(s):
 s=s.replace('\twb.tick_report()','\twb.tick_report()\n\tpreload("res://scripts/art/s7_profile.gd").report()\n\tif "--s7-profile" in OS.get_cmdline_user_args():RenderingServer.frame_post_draw.connect(_s7_first_frame,CONNECT_ONE_SHOT)',1)
 return s+'''\nfunc _s7_first_frame():
\tprint("[S7_FIRST_FRAME] ",JSON.stringify({"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"tris":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"ticks_ms":Time.get_ticks_msec(),"no_focus":DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"mouse_captured":Input.mouse_mode==Input.MOUSE_MODE_CAPTURED}))
'''
edit(Path('main.gd'),main)
