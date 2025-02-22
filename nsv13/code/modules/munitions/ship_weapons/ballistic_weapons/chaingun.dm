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
	var/occupied = FALSE

	var/list/chaingun_verbs = list(.verb/show_computer, .verb/show_view)

	var/obj/machinery/chaingun_cycler
	var/obj/machinery/chaingun_loading_hopper
	var/obj/machinery/chaingun_gyroscope

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

/obj/machinery/ship_weapon/chaingun/Destroy() //Yeet them out before we die.
	remove_chaingunner()
	return ..()

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
	set_chaingunner(usr)
	to_chat(gunner, "<span class='notice'>You reach for [src]'s gun camera controls.</span>")

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

/obj/machinery/ship_weapon/chaingun/MouseDrop_T(obj/machinery/A, mob/user)
	if(!isliving(user))
		return FALSE
	if(occupied)
		to_chat(user, "<span class='warning'>The [src] is already occupied!</span>")
		return FALSE
	if(user)
		if(!do_after(user, 10 SECONDS, target = user))
			return FALSE
		else
			occupied = TRUE
			set_chaingunner(user)

/obj/machinery/ship_weapon/chaingun/attack_hand(mob/user)
	if(!occupied)
		return FALSE
	if(gunner == user)
		visible_message("<span class='notice'>The hatch of the [src] hisses open!</span>")
		if(do_after(user, 5 SECONDS, target = src))
			remove_chaingunner()

/obj/machinery/ship_weapon/chaingun/proc/set_chaingunner(mob/user)
	user.forceMove(src)
	gunner = user
	gunner.AddComponent(/datum/component/overmap_gunning, src)
	gunner.add_verb(chaingun_verbs)
	ui_interact(user)

/obj/machinery/ship_weapon/chaingun/proc/remove_chaingunner()
	if(gunner)
		var/mob/user = gunner
		var/obj/structure/overmap/OM = get_overmap()
		OM?.stop_piloting(gunner)
		user.forceMove(get_offset_target_turf(src, 1, 1))
		user.remove_verb(chaingun_verbs)
	gunner = null
	occupied = FALSE
