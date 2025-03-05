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
	magazine_type = /obj/item/ammo_box/magazine/chaingun_belt
	circuit = /obj/item/circuitboard/machine/chaingun

	fire_mode = FIRE_MODE_CHAINGUN


	semi_auto = TRUE
	maintainable = FALSE
	max_ammo = 5
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

	var/obj/machinery/chaingun_cycler/cycler = null
	var/cycler_firerate = 1
	var/turf/cycler_turf = null
	var/stalled = FALSE

	var/obj/machinery/chaingun_loading_hopper/hopper = null
	var/turf/hopper_turf = null

	var/obj/machinery/chaingun_gyroscope/gyro = null
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

/obj/machinery/ship_weapon/chaingun/can_fire()
	. = ..()
	if(stalled)
		//Add clicking sound
		to_chat(gunner, "<span class='notice'>The triggers aren't responding! The gun's stalled out, manual clear required!</span>")
		return FALSE

/obj/machinery/ship_weapon/chaingun/local_fire() //FIGURE OUT WHY WHEN THE GUN STALLS OUT, THE GAME THINKS YOU'RE HOLDING DOWN YOUR MOUSE!!!!
	. = ..()
	if(!length(ammo))
		magazine.forceMove(get_offset_target_turf(src, 0, 1))
		magazine = null
		ammo = null
		state = STATE_NOTLOADED
	if(!hopper)
		new /obj/effect/particle_effect/smoke(hopper_turf)
	else
		if(prob(hopper.soot / 10))
			new /obj/effect/particle_effect/smoke(hopper_turf)
		if(!length(ammo))
			if(length(hopper.loaded_belts) > 0)
				var/obj/B = hopper.loaded_belts[1]
				hopper.loaded_belts -= B
				B.forceMove(src)
				magazine = B
				ammo = magazine.stored_ammo
				state = STATE_CHAMBERED
				//play clicky sound
		if(length(hopper.loaded_belts) > hopper.belts_capacity)
			if(prob(10 * (length(hopper.loaded_belts) - hopper.belts_capacity)))
				var/obj/B = hopper.loaded_belts[((length(hopper.loaded_belts) - hopper.belts_capacity) + 2)]
				var/turf/T = get_turf(pick(oview(src, 2)))
				B.throw_at(T)

	if(!cycler || cycler?.jammed)
		stalled = TRUE
		//play horrible ka-chunka sound
	else
		cycler.durability = min(cycler.durability -= rand(1,2), cycler.max_durability)
		if(prob((100 - cycler.durability) / 10))
			cycler?.jammed = TRUE
			//play cycler jamming sound
	if(gyro)
		gyro.alignment = max((gyro.alignment - rand(1, 5)), 0)

/obj/machinery/ship_weapon/chaingun/proc/manual_cycle()
	//play ka-chunka sound
	if(stalled)
		stalled = FALSE
		state = STATE_LOADED
		return
	else
		if(length(ammo) > 0)
			var/obj/A = magazine.stored_ammo[1]
			ammo -= A
			A.forceMove(get_offset_target_turf(src, -1, 1))
			magazine.update_icon()
			state = STATE_LOADED
			return
	if(!length(ammo))
		if(magazine)
			magazine.forceMove(get_offset_target_turf(src, 0, 1))
			magazine = null
			ammo = null
			state = STATE_NOTLOADED
		if(length(hopper.loaded_belts) > 0)
			var/obj/B = hopper.loaded_belts[1]
			hopper.loaded_belts -= B
			B.forceMove(src)
			magazine = B
			ammo = magazine.stored_ammo
			state = STATE_LOADED
		//play ka-chunka sound

#define DEFAULT_CHAINGUN_SPREAD 25

/obj/machinery/ship_weapon/chaingun/proc/get_spread()
	if(!gyro)
		return DEFAULT_CHAINGUN_SPREAD //Default spread is 25 degrees of deviation
	return DEFAULT_CHAINGUN_SPREAD - ((gyro.accuracy * (0.01 * gyro.alignment)) * 5)

/obj/machinery/ship_weapon/chaingun/animate_projectile(atom/target)
	return linked.fire_projectile(weapon_type.default_projectile_type, target, lateral=weapon_type.lateral, spread = get_spread())

/datum/ship_weapon/chaingun
	name = "Chaingun"
	burst_size = 1
	fire_delay = 1 SECONDS
	range_modifier = 20
	default_projectile_type = /obj/item/projectile/bullet/chaingun
	select_alert = "<span class='notice'>Spinning up chainguns...</span>"
	failure_alert = "<span class='warning'>DANGER: No chain fed, reload!</span>"
//	overmap_firing_sounds = make/find one
//	overmap_select_sound = make/find one
	weapon_class = WEAPON_CLASS_LIGHT
	miss_chance = 10
	max_miss_distance = 6
	ai_fire_delay = 2 SECONDS
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
		if(!do_after(user, 3 SECONDS, target = user))
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
	gunner.AddComponent(/datum/component/overmap_gunning/chaingun, src)
	update_cycler()
	gunner.add_verb(chaingun_verbs)
	ui_interact(user)

/obj/machinery/ship_weapon/chaingun/proc/remove_chaingunner()
	if(gunner)
		var/obj/structure/overmap/OM = get_overmap()
		OM?.stop_piloting(gunner)
		gunner.forceMove(get_offset_target_turf(src, 1, 1))
		gunner.remove_verb(chaingun_verbs)
	gunner = null
	occupied = FALSE

/datum/component/overmap_gunning/chaingun //move this later
	fire_mode = FIRE_MODE_CHAINGUN
	automatic = FALSE
	fire_delay = 1 SECONDS

/obj/machinery/ship_weapon/chaingun/proc/update_cycler()
	var/datum/component/overmap_gunning/OG = gunner?.GetComponent(/datum/component/overmap_gunning/chaingun)
	if(!cycler)
		OG?.fire_delay = 1 SECONDS
	else
		OG?.fire_delay = (1 SECONDS / cycler_firerate)

/obj/machinery/ship_weapon/chaingun/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "chaingun")
		ui.open()
		ui.set_autoupdate(TRUE)

/obj/machinery/ship_weapon/chaingun/ui_state(mob/user)
	return GLOB.contained_state

/obj/machinery/ship_weapon/chaingun/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	playsound(src.loc,'nsv13/sound/effects/fighters/switch.ogg', 50, FALSE) //Switch this up to some clunky gun sounds
	switch(action)
		if("toggle_load")
			if(state == STATE_LOADED)
				feed()
			else
				unload()
		if("chamber")
			chamber()
		if("toggle_safety")
			safety = !safety
		if("load")
			load()
		if("manual_cycle")
			manual_cycle()

/obj/machinery/ship_weapon/chaingun/ui_data(mob/user)
	var/list/data = list()
	data["stalled"] = stalled
	data["loaded"] = state > STATE_LOADED
	data["chambered"] = state == STATE_CHAMBERED
	data["safety"] = safety
	data["ammo"] = ammo.len
	data["max_ammo"] = max_ammo
	data["cycler_firerate"] = cycler?.cycle_speed
	data["cycler_jammed"] = cycler?.jammed
	data["gyroscope_alignment"] = gyro?.alignment
	data["max_gyroscope_alignment"] = gyro?.max_alignment
	data["hopper_belts"] = length(hopper?.loaded_belts)
	data["max_hopper_belts"] = hopper?.belts_capacity
	return data
