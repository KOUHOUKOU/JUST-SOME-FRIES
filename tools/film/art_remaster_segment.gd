extends Node
## S4 opt-in Movie Maker segment. Real controller/rhythm/audio; editorial setup cuts only.
var bot
var main
var p
var start_frame=0
var events=[]
func mark(label):
	var t=(Engine.get_frames_drawn()-start_frame)/30.0
	events.append({"event":label,"seconds":t,"position":str(p.global_position),"speed":p.speed,"stamina":p.stamina})
	print("[S4 FILM] ",label," t=",t," pos=",p.global_position)
func run(b):
	process_mode=Node.PROCESS_MODE_ALWAYS;bot=b;main=b.main;p=main.player
	bot.metrics["cine_shot"]=true # AVI is the evidence; don't emit extra automatic screenshots.
	assert(Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
	await bot.film_start_game()
	Engine.max_fps=30
	main.day.t=.72;main.day._apply(0);main.day.set_process(false)
	start_frame=Engine.get_frames_drawn()
	mark("roof_start")
	bot.aim_at(p,Vector3(2,13,55));p.update_camera(0,true)
	await bot.real(1.5)
	bot.tap("flap")
	mark("takeoff")
	await fly(Vector3(0,22,70),7.5,0)
	mark("pier_and_ferris")
	await fly(Vector3(35,22,88),3.5,0)
	# A visible edit to the real dive approach; the following snatch uses the existing bot.
	bot.place(Vector3(-8,17,36),Vector3(-8,3,17),11)
	p.update_camera(0,true);p.reset_physics_interpolation()
	mark("dive")
	await fly(Vector3(-8,2,14),1.8,0)
	mark("snatch_approach")
	var result=await bot.film_steal(main.world.fries["TUTORIAL_01"],Vector3(0,.2,1),11.0,{"gold":true})
	mark("snatch_"+result)
	print("[S4 FILM] verdict=",p.snatch.last_commit," result=",result," tutorial=",GS.tutorial_done)
	assert(result=="ok")
	await bot.real(1.8)
	if main.showcase.active:bot.fkey()
	var deadline=GS.msec()+12000
	while main.showcase.active and GS.msec()<deadline:await get_tree().process_frame
	await bot.real(.3)
	bot.place(Vector3(38,43,8),Vector3(-38,35,-75),12)
	p.input_locked=false;p.update_camera(0,true);p.reset_physics_interpolation()
	mark("town_fast_flight")
	await fly(Vector3(-38,35,-75),8.0,2.0)
	bot.place(Vector3(23,28,112),Vector3(-105,26,38),12)
	p.input_locked=false;p.update_camera(0,true);p.reset_physics_interpolation()
	mark("sea_to_lighthouse")
	var remain=51.0-(Engine.get_frames_drawn()-start_frame)/30.0
	await fly(Vector3(-105,26,38),max(remain,4.0),2.0)
	mark("complete")
	var path=ProjectSettings.globalize_path("res://../art_src/final/film_events.json")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"events":events,"real_controller":true,"real_snatch":result,"golden_t":.72,"editorial_teleports":["dive setup","existing snatch approach","town","sea"],"normal_speed_and_stamina_rules":true},"\t"))
func fly(target,seconds,boost_seconds):
	p.input_locked=false;Input.action_press("move_forward")
	var f0=Engine.get_frames_drawn()
	while (Engine.get_frames_drawn()-f0)/30.0<seconds:
		var d=(target-p.global_position).normalized()
		p.aim_yaw=atan2(-d.x,-d.z);p.aim_pitch=asin(clamp(d.y,-1,1))
		if (Engine.get_frames_drawn()-f0)/30.0<boost_seconds:Input.action_press("dash")
		else:Input.action_release("dash")
		await get_tree().process_frame
	Input.action_release("dash");Input.action_release("move_forward")
