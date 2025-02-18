/obj/machinery/ship_weapon/chaingun
	name = "\improper ASW 'Guillotine' Chainfed Machinegun"
	icon = 'nsv13/icons/obj/chaingun.dmi'
	icon_state = "chaingun"
	desc = "Dakka dakka doesn't do it justice." //placeholder
	anchored = TRUE

	density = FALSE
	safety = FALSE

	bound_width = 96
	bound_height = 96
	ammo_type = /obj/item/ship_weapon/ammunition/
	circuit = /obj/item/circuitboard/machine/chaingun

//	fire_mode = FIRE_MODE_GAUSS

	semi_auto = TRUE
	maintainable = FALSE
	max_ammo = 100
//	feeding_sound = have to make one
	fed_sound = null
	chamber_sound = null

//	load_delay =
//	unload_delay =
//	fire_animation_length =

//	feed_delay =
//	chamber_delay_rapid =
//	chamber_delay =

	var/mob/gunner = null

	var/obj/structure/chair/fancy/chaingun/chaingun_chair = null
	var/obj/machinery/chaingun_cycler
	var/obj/machinery/chaingun_loading_hopper
	var/obj/machinery/chaingun_gyroscope

	var/list/chaingun_verbs = list(.verb/show_computer, .verb/show_view)

/obj/item/circuitboard/machine/chaingun
	name = "circuit board (chaingun platform)"
	desc = "Cut them down! Cut them all down!"
	req_components = list(
		/obj/item/stack/sheet/mineral/titanium = 5,
		/obj/item/stack/sheet/iron = 20,
		/obj/item/stock_parts/manipulator = 4,
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/matter_bin = 10,
		/obj/item/ship_weapon/parts/firing_electronics = 1
	)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	build_path = /obj/machinery/ship_weapon/chaingun

/obj/item/circuitboard/machine/chaingun/Initialize(mapload)
	. = ..()
	GLOB.critical_muni_items += src

/obj/item/circuitboard/machine/chaingun/Destroy(force=FALSE)
	if(!force)
		return QDEL_HINT_LETMELIVE
	GLOB.critical_muni_items -= src
	return ..()

/obj/machinery/chaingun_cycler
	name = "\improper Mechanical Chaingun Cycler"
	icon = 'nsv13/icons/obj/chaingun_machines.dmi'
	icon_state = "cycler"
	desc = "Using a piezo quartz timer this machine ensures the Chaingun is firing at a steady pace." //placeholder?
	anchored = FALSE
	density = TRUE
	panel_open = TRUE
	circuit = /obj/item/circuitboard/machine/chaingun_cycler

/obj/item/circuitboard/machine/chaingun_cycler
	name = "circuit board (chaingun cycler)"
	desc = "Type writer soundin' mf" //placeholder
	req_components = list(
		/obj/item/stack/sheet/iron = 30,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/manipulator = 10,
		/obj/item/stock_parts/matter_bin = 2,
	)
	build_path = /obj/machinery/chaingun_cycler

/obj/machinery/chaingun_cycler/wrench_act(mob/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	if(!panel_open)
		to_chat(user, "<span class='warning'>You can't reach the bolts, you have to <i>unscrew</i> the panel open first!</span>")
		return FALSE
	if(!anchored)
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = TRUE)
			to_chat(user, "<span class='notice'>You wrench down the bolts, anchoring the [src] to the floor.</span>")
			return TRUE
	else
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = FALSE)
			to_chat(user, "<span class='notice'>You loosen the bolts, freeing the [src] from the floor.</span>")
			return TRUE

/obj/machinery/chaingun_cycler/screwdriver_act(mob/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	if(!panel_open)
		(panel_open = TRUE)
		to_chat(user, "<span class='notice'>You unscrew and open the [src]'s maintenance panel.</span>")
		return TRUE
	else
		(panel_open = FALSE)
		to_chat(user, "<span class='notice'>You screw the [src]'s maintenance panel shut.</span>")
		return TRUE

/obj/machinery/chaingun_loading_hopper
	name = "\improper Chaingun Loading Hopper" //tbd
	icon = 'nsv13/icons/obj/chaingun_machines.dmi'
	icon_state = "loader"
	desc = "The shape of the funnel on this thing apparently has an extremely tight machining tolerance." //placeholder
	anchored = FALSE
	density = TRUE
	panel_open = TRUE
	circuit = /obj/item/circuitboard/machine/chaingun_loading_hopper

/obj/item/circuitboard/machine/chaingun_loading_hopper
	name = "circuit board (chaingun loading hopper)"
	desc = "chain holding lookin' mf" //placeholder
	req_components = list(
		/obj/item/stack/sheet/iron = 20,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/manipulator = 4,
		/obj/item/stock_parts/matter_bin = 10,
	)
	build_path = /obj/machinery/chaingun_cycler

/obj/machinery/chaingun_loading_hopper/wrench_act(mob/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	if(!panel_open)
		to_chat(user, "<span class='warning'>You can't reach the bolts, you have to <i>unscrew</i> the panel open first!</span>")
		return FALSE
	if(!anchored)
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = TRUE)
			to_chat(user, "<span class='notice'>You wrench down the bolts, anchoring the [src] to the floor.</span>")
			return TRUE
	else
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = FALSE)
			to_chat(user, "<span class='notice'>You loosen the bolts, freeing the [src] from the floor.</span>")
			return TRUE

/obj/machinery/chaingun_loading_hopper/screwdriver_act(mob/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	if(!panel_open)
		(panel_open = TRUE)
		to_chat(user, "<span class='notice'>You unscrew and open the [src]'s maintenance panel.</span>")
		return TRUE
	else
		(panel_open = FALSE)
		to_chat(user, "<span class='notice'>You screw the [src]'s maintenance panel shut.</span>")
		return TRUE

/obj/machinery/chaingun_gyroscope
	name = "\improper 'Always Upright' Kinetic Gyroscope" //tbd
	icon = 'nsv13/icons/obj/chaingun_machines.dmi'
	icon_state = "gyro"
	desc = "This delicate machination is what allows the gun and dome to rotate properly." //placeholder
	anchored = FALSE
	density = TRUE
	panel_open = TRUE
	circuit = /obj/item/circuitboard/machine/chaingun_gyroscope

/obj/item/circuitboard/machine/chaingun_gyroscope
	name = "circuit board (chaingun gyroscope)"
	desc = "spinny winny lookin' mf" //placeholder
	req_components = list(
		/obj/item/stack/sheet/iron = 50,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/manipulator = 10,
		/obj/item/stock_parts/scanning_module = 5,
		/obj/item/stock_parts/micro_laser = 1,
	)
	build_path = /obj/machinery/chaingun_gyroscope

/obj/machinery/chaingun_gyroscope/wrench_act(mob/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	if(!panel_open)
		to_chat(user, "<span class='warning'>You can't reach the bolts, you have to <i>unscrew</i> the panel open first!</span>")
		return FALSE
	if(!anchored)
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = TRUE)
			to_chat(user, "<span class='notice'>You wrench down the bolts, anchoring the [src] to the floor.</span>")
			return TRUE
	else
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = FALSE)
			to_chat(user, "<span class='notice'>You loosen the bolts, freeing the [src] from the floor.</span>")
			return TRUE

/obj/machinery/chaingun_gyroscope/screwdriver_act(mob/user, obj/item/tool)
	tool.play_tool_sound(src, 50)
	if(!panel_open)
		(panel_open = TRUE)
		to_chat(user, "<span class='notice'>You unscrew and open the [src]'s maintenance panel.</span>")
		return TRUE
	else
		(panel_open = FALSE)
		to_chat(user, "<span class='notice'>You screw the [src]'s maintenance panel shut.</span>")
		return TRUE

/datum/ship_weapon/chaingun
	name = "Chaingun"
	burst_size = 10 //Try to find a way to get continuous fire
	fire_delay = 0 SECONDS
	range_modifier = 20
	default_projectile_type = /obj/item/projectile/bullet/chaingun
	select_alert = "<span class='notice'>Spinning up chainguns...</span>"
	failure_alert = "<span class='warning'>DANGER: No chain fed, reload!</span>"
//	overmap_firing_sounds = make/find one
//	overmap_select_sound = make/find one
	weapon_class = WEAPON_CLASS_LIGHT
	miss_chance = 10
	max_miss_distance = 6
	ai_fire_delay = 10 SECONDS
	allowed_roles = OVERMAP_USER_ROLE_SECONDARY_GUNNER
	screen_shake = 0

/obj/machinery/ship_weapon/chaingun/examine()
	. = ..()
	switch(maint_state)
		if(MSTATE_CLOSED)
			pop(.)
		if(MSTATE_UNSCREWED)
			pop(.)
		if(MSTATE_UNBOLTED)
			pop(.)
	if(panel_open)
		. += "The maintenance panel is <b>unscrewed</b> and the machinery could be <i>pried out</i>."
	else
		. += "The maintenance panel is <b>closed</b> and could be <i>screwed open</i>."

/obj/machinery/ship_weapon/chaingun/proc/add_chair(obj/structure/chair/fancy/chaingun/chair)
	chaingun_chair = chair

/obj/structure/chair/fancy/chaingun
	name = "Chaingunner chair"
	desc = "A capsule-like seat for the gunner to sit in, the Empire nicknamed them death eggs. Sounds better in draconic" //placeholder?
	icon = 'nsv13/icons/obj/chairs.dmi'
	icon_state = "shuttle_chair" //placeholder
	item_chair = null
	buildstackamount = 10
	var/locked = FALSE
	var/obj/machinery/ship_weapon/chaingun/gun
	var/mob/living/occupant

/obj/structure/chair/fancy/chaingun/Destroy() //I think this makes the chair destructible?
	if(gun)
		gun.chaingun_chair = null
	return ..()

/obj/structure/chair/fancy/chaingun/unbuckle_mob(mob/buckled_mob, force=FALSE)
	if(locked)
		to_chat(buckled_mob, "<span class='warning'>[src]'s lid is sealed above you!</span>")
		return FALSE
	. = ..()
	if(.)
		occupant = null

/obj/structure/chair/fancy/chaingun/user_unbuckle_mob(mob/buckled_mob, mob/user)
	if(locked)
		to_chat(buckled_mob, "<span class='warning'>[src]'s lid is sealed above you!</span>")
		return FALSE
	. = ..()
	if(.)
		occupant = null

/obj/structure/chair/fancy/chaingun/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if((gun && !gun.allowed(M)) || !M.client)
		var/sound = pick('nsv13/sound/effects/computer/error.ogg','nsv13/sound/effects/computer/error2.ogg','nsv13/sound/effects/computer/error3.ogg')
		playsound(src, sound, 100, 1)
		to_chat(user, "<span class='warning'>Access denied</span>")
		return

	if(M.loc != loc)
		return

	if(!iscyborg(M) && !iscarbon(M)) //Only carbons and cyborgs get to use the chaingun. (That means monkeys too, but only player-controlled ones will be able to use it)
		if(M == user)
			to_chat(user, "<span class='warning'>You can't seem fit in the [src].!</span>")
		else
			to_chat(user, "<span class='warning'>[M] won't fit in the [src].!</span>")
		return

	var/mob/living/carbon/C = M
	if(istype(C) && ((!C.get_bodypart(BODY_ZONE_L_ARM) && !C.get_bodypart(BODY_ZONE_R_ARM)) || C.restrained(TRUE))) //Can't shoot the gun if you have no hands, borgs get a pass on this
		if(M == user)
			to_chat(user, "<span class='warning'>You can't operate the chaingun without hands!!</span>")
		else
			to_chat(user,"<span class='warning'>[M] can't operate the chaingun without hands!!</span>")
		return

	to_chat(C, "<span class='warning'>[src]'s lid is sealed above you!</span>")
	occupant = C
	. = ..()
	if(.)
		update_armrest()
		gun?.close_hatch()

/obj/machinery/ship_weapon/chaingun/proc/close_hatch()
	if(!chaingun_chair || chaingun_chair.loc == src)
		return FALSE
	var/mob/M = chaingun_chair.occupant //Arrays start at 1 in byond. Grr.
	if(gunner)
		to_chat(M, "<span class='warning'>Someone else is already manning this turret!</span>")
		return FALSE
	chaingun_chair.locked = TRUE //No escape.
	chaingun_chair.visible_message("<span class='notice'>The hatch is about the close!</span>")

	if(M.loc != chaingun_chair.loc) //They got out of the chair somehow. Probably admin fuckery.
		return FALSE
	set_gunner(M) //Up we go!
	chaingun_chair.forceMove(src)

/obj/machinery/ship_weapon/chaingun/proc/open_hatch()
	if(!chaingun_chair || chaingun_chair.loc != src)
		return FALSE
	var/turf/chair = get_offset_target_turf(src, 1, 1) //need to change: get the turf the chair is on, we don't wanna throw people into voids
	chaingun_chair.forceMove(chair)
	chaingun_chair.locked = TRUE
	var/mob/living/M = gunner
	M.forceMove(chair)
	chaingun_chair.buckle_mob(M)
	visible_message("<span class='notice'>The hatch hisses open!</span>")
	M.alpha = 0
	chaingun_chair.alpha = 0
	chaingun_chair.locked = FALSE //Ok. Feel free to move again.
	chaingun_chair.visible_message("<span class='notice'>The hatch swings open and locks in place!</span>")

/obj/machinery/ship_weapon/chaingun/proc/set_gunner(mob/user)
	user.forceMove(src)
	gunner = user
	gunner.AddComponent(/datum/component/overmap_gunning, src)
	gunner.add_verb(chaingun_verbs)
	ui_interact(user)

/obj/machinery/ship_weapon/chaingun/proc/remove_gunner()
	if(gunner)
		var/mob/oldGunner = gunner
		var/obj/structure/overmap/OM = get_overmap()
		OM?.stop_piloting(gunner)
		if(chaingun_chair)
			open_hatch()
		else
			oldGunner.forceMove(get_turf(src))
		oldGunner.remove_verb(chaingun_verbs)
	gunner = null

/obj/machinery/ship_weapon/chaingun/verb/show_computer()
	set name = "Access internal computer"
	set category = "Chaingun"
	set src = usr.loc

	if(gunner.incapacitated() || !isliving(gunner))
		return
	ui_interact(gunner)
	to_chat(gunner, "<span class='notice'>You reach for [src]'s control panel.</span>")

/obj/machinery/ship_weapon/chaingun/verb/show_view()
	set name = "Access gun camera"
	set category = "Chaingun"
	set src = usr.loc

	if(usr.incapacitated())
		return
	set_gunner(usr)
	to_chat(gunner, "<span class='notice'>You reach for [src]'s gun camera controls.</span>")

//obj/machinery/chaingun/chaingun_cycler

//obj/machinery/chaingun/chaingun_loading_hopper

//obj/machinery/chaingun/chaingun_gyroscope
