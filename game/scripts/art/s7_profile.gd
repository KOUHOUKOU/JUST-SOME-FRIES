extends RefCounted
## Opt-in wall-clock accounting; nested totals must not be summed together.
static var enabled="--s7-profile" in OS.get_cmdline_user_args()
static var totals={}
static func start():
	return Time.get_ticks_usec() if enabled else 0
static func end(key,t):
	if not enabled:return
	if not totals.has(key):totals[key]=[0,0]
	totals[key][0]+=Time.get_ticks_usec()-t;totals[key][1]+=1
static func report():
	if enabled:print("[S7_PROFILE] ",JSON.stringify(totals))
