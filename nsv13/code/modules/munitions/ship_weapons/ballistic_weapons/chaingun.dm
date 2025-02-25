/obj/machinery/ship_weapon/chaingun
	name = "\improper ASW 'Guillotine' Chainfed AutoGun"
	icon = 'nsv13/icons/obj/chaingun.dmi'
	icon_state = "chaingun"
	desc = "Dakka dakka doesn't do it justice." //placeholder
	anchored = TRUE

	density = FALSE
	safety = FALSE

	bound_width = 96
	bound_height = 96
	ammo_type = /obj/item/ship_weapon/ammunition/chaingun_belt
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
	var/climbing_in = FALSE

	var/list/chaingun_verbs = list(.verb/show_computer, .verb/show_view)

	var/obj/machinery/chaingun_cycler/cycler
	var/turf/cycler_turf = null

	var/obj/machinery/chaingun_loading_hopper/hopper
	var/turf/hopper_turf = null

	var/obj/machinery/chaingun_gyroscope/gyro
	var/turf/gyro_turf = null

/obj/item/circuitboard/machine/chaingun
	name = "circuit board (chaingun platform)"
	desc = "Cut them down! Cut them all down!"
	req_components = list(
		/obj/item/stack/sheet/mineral/titanium = 5,
		/obj/item/stack/sheet/glass = 50,
		/obj/item/stack/sheet/iron = 20,
		/obj/item/stock_parts/manipulator = 4,
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/matter_bin = 10,
		/obj/item/ship_weapon/parts/firing_electronics = 1
	)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	build_path = /obj/machinery/ship_weapon/chaingun

/obj/machinery/ship_weapon/chaingun/Initialize(mapload)
	. = ..()
	cycler_turf = get_offset_target_turf(src, 2, 2)
	hopper_turf = get_offset_target_turf(src, 2, 1)
	gyro_turf = get_offset_target_turf(src, 1 , 2)

/obj/structure/frame/machine/attackby(obj/item/P, mob/user, params) //Move this to Job_changes.dm for the new ship, we don't want players to build chainguns on anything except the bottom deck
	if(istype(P, /obj/item/circuitboard/machine/chaingun))
		var/turf/z_level = get_turf(src)
		if(z_level.z != 2)
			to_chat(user, "<span class='warning'>The [src] can only be built on the bottom deck!</span>")
			return FALSE
	. = ..()

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
	if(climbing_in)
		to_chat(user, "<span class='warning'>Someone is already climbing into the [src]</span>")
		return FALSE
	if(user)
		climbing_in = TRUE
		if(!do_after(user, 10 SECONDS, target = user))
			climbing_in = FALSE
			return FALSE
		else
			occupied = TRUE
			set_chaingunner(user)
			climbing_in = FALSE

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
