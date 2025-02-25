
/obj/machinery/chaingun_cycler
	name = "Mechanical Chaingun Cycler"
	icon = 'nsv13/icons/obj/chaingun_machines.dmi'
	icon_state = "cycler"
	desc = "Using a piezo quartz timer this machine ensures the Chaingun is firing at a steady pace." //placeholder?
	anchored = FALSE
	density = TRUE
	panel_open = TRUE
	circuit = /obj/item/circuitboard/machine/chaingun_cycler
	layer = 3 //Want this to appear above the chaingun sprite

	var/obj/machinery/ship_weapon/chaingun/chaingun


	var/repair_multiplier = 5
	var/busy = FALSE
	var/jammed = FALSE //When durability reaches 0, cycler becomes jammed
	var/durability = 100 //Lowers when firing, replenished with oil
	var/max_durability = 100


/obj/item/circuitboard/machine/chaingun_cycler
	name = "circuit board (chaingun cycler)"
	desc = "Type writer soundin' mf" //placeholder
	req_components = list(
		/obj/item/stack/sheet/iron = 30,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/matter_bin = 1,
	)
	build_path = /obj/machinery/chaingun_cycler

/obj/machinery/chaingun_cycler/wrench_act(mob/user, obj/item/tool)
	if(!panel_open)
		to_chat(user, "<span class='warning'>You can't reach the bolts, you have to <i>unscrew</i> the panel open first!</span>")
		return FALSE
	if(!anchored)
		var/turf/T = get_turf(src)
		chaingun = (locate(/obj/machinery/ship_weapon/chaingun) in T)
		var/turf/CT = chaingun?.cycler_turf
		if(!chaingun || T != CT)
			to_chat(user, "<span class='warning'>You can't connect the [src] here!</span>")
			return FALSE
		tool.play_tool_sound(src, 50)
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = TRUE)
			to_chat(user, "<span class='notice'>You wrench down the bolts, anchoring the [src] to the floor.</span>")
			return TRUE
	else
		tool.play_tool_sound(src, 50)
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

/obj/machinery/chaingun_cycler/attackby(obj/item/R, mob/living/user, params) //Taken from ammo_rack.dm from the ammo rack itself
	. = ..()
	if(istype(R, /obj/item/reagent_containers) && panel_open)
		if(jammed)
			to_chat(user, "<span class='warning'>You can't lubricate a jammed machine!</span>")
			return TRUE
		if(durability == 100)
			to_chat(user, "<span class='warning'>[src] doesn't need any oil right now!</span>")
			return TRUE
		if(!R.reagents.has_reagent(/datum/reagent/oil))
			to_chat(user, "<span class='warning'>You need oil to lubricate this!</span>")
			return TRUE
		// get how much oil we have
		var/oil_amount = min(R.reagents.get_reagent_amount(/datum/reagent/oil), max_durability/repair_multiplier)
		var/oil_needed = CLAMP(ROUND_UP((max_durability-durability)/repair_multiplier), 1, oil_amount)
		oil_amount = min(oil_amount, oil_needed)
		user.visible_message("<span class='notice'>[user] begins lubricating [src]...</span>", \
					"<span class='notice'>You start lubricating the inner workings of [src]...</span>")
		busy = TRUE
		if(!do_after(user, 5 SECONDS, target=src))
			busy = FALSE
			to_chat(user, "<span class='warning'>You were interrupted!</span>")
			return TRUE
		if(!R.reagents.has_reagent(/datum/reagent/oil, oil_amount)) //things can change, check again.
			to_chat(user, "<span class='warning'>You don't have enough oil left to lubricate [src]!</span>")
			busy = FALSE
			return TRUE
		user.visible_message("<span class='notice'>[user] lubricates [src].</span>", \
					"<span class='notice'>You lubricate the inner workings of [src].</span>")
		durability = min(durability + (oil_amount * repair_multiplier), max_durability)
		R.reagents.remove_reagent(/datum/reagent/oil, oil_amount)
		busy = FALSE
		return TRUE

/obj/machinery/chaingun_cycler/MouseDrop_T(mob/living/A, mob/living/user) //An easter egg, allows the players to lubricate the cycler with IPC's blood
	. = ..()
	if(!isipc(A))
		return FALSE
	else
		if(jammed)
			to_chat(user, "<span class='warning'>You can't lubricate a jammed machine!</span>")
			return TRUE
		if(durability == 100)
			to_chat(user, "<span class='warning'>[src] doesn't need any IPC blood right now!</span>")
			return TRUE
		if(A.blood_volume == 0)
			to_chat(user, "<span class='warning'>[A] doesn't have enough blood!</span>")
			return TRUE
		// get how much oil we have
		var/oil_amount = min(A.blood_volume, max_durability/repair_multiplier)
		var/oil_needed = CLAMP(ROUND_UP((max_durability-durability)/repair_multiplier), 1, oil_amount)
		oil_amount = min(oil_amount, oil_needed)
		user.visible_message("<span class='notice'>[user] begins lubricating [src] with [A]'s blood...</span>", \
				"<span class='notice'>You start lubricating the inner workings of [src] with [A]'s blood...</span>",)
		to_chat(A, "<span class='userdanger'>[user] rips an oil hose out of you and connects it to the [src]!")
		busy = TRUE
		if(!do_after(user, 5 SECONDS, target=src))
			busy = FALSE
			to_chat(user, "<span class='warning'>You were interrupted!</span>")
			return TRUE
		if(A.blood_volume < oil_amount) //things can change, check again.
			to_chat(user, "<span class='warning'>There's not enough blood left to lubricate [src]!</span>")
			busy = FALSE
			return TRUE
		user.visible_message("<span class='notice'>[user] lubricates [src] with [A]'s blood!</span>", \
					"<span class='notice'>You lubricate the inner workings of [src] with [A]'s blood!</span>")
		durability = min(durability + (oil_amount * repair_multiplier), max_durability)
		A.blood_volume = (A.blood_volume -= (oil_amount * 3))
		A.apply_damage(5, BRUTE, pick(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM))
		busy = FALSE
		return TRUE

/obj/machinery/chaingun_loading_hopper
	name = "Chaingun Loading Hopper" //tbd
	icon = 'nsv13/icons/obj/chaingun_machines.dmi'
	icon_state = "loader"
	desc = "The shape of the funnel on this thing apparently has an extremely tight machining tolerance." //placeholder
	anchored = FALSE
	density = TRUE
	panel_open = TRUE
	circuit = /obj/item/circuitboard/machine/chaingun_loading_hopper
	layer = 3 //Want this to appear above the chaingun sprite

	var/obj/machinery/ship_weapon/chaingun/chaingun

	var/belts = 0
	var/belts_capacity = 5

	var/soot = 0 //This seems familiar
	var/max_soot = 100
	var/min_soot = 0

/obj/item/circuitboard/machine/chaingun_loading_hopper
	name = "circuit board (chaingun loading hopper)"
	desc = "chain holding lookin' mf" //placeholder
	req_components = list(
		/obj/item/stack/sheet/iron = 20,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/matter_bin = 2,
	)
	build_path = /obj/machinery/chaingun_cycler

/obj/machinery/chaingun_loading_hopper/RefreshParts()
	for(var/obj/item/stock_parts/matter_bin/MB in component_parts)
		belts_capacity = (5 * MB.rating)

/obj/machinery/chaingun_loading_hopper/wrench_act(mob/user, obj/item/tool)
	if(!panel_open)
		to_chat(user, "<span class='warning'>You can't reach the bolts, you have to <i>unscrew</i> the panel open first!</span>")
		return FALSE
	if(!anchored)
		var/turf/T = get_turf(src)
		chaingun = (locate(/obj/machinery/ship_weapon/chaingun) in T)
		var/turf/HT = chaingun?.hopper_turf
		if(!chaingun || T != HT)
			to_chat(user, "<span class='warning'>You can't connect the [src] here!</span>")
			return FALSE
		tool.play_tool_sound(src, 50)
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = TRUE)
			to_chat(user, "<span class='notice'>You wrench down the bolts, anchoring the [src] to the floor.</span>")
			return TRUE
	else
		tool.play_tool_sound(src, 50)
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

/obj/machinery/chaingun_loading_hopper/attack_hand(mob/living/user) //Replace with swabber when broadside update gets full merged
	. = ..()
	if(soot == min_soot)
		to_chat(user, "<span class='warning'>The [src] doesn't need a good swabbing yet!</span>")
		return
	if(panel_open && (soot > min_soot))
		to_chat(user, "<span class='notice'>You swab the s machine with your bare hands...</span>")
		while(soot > min_soot)
			if(!do_after(user, 2 SECONDS, target = src))
				to_chat(user, "<span class='warning'>You were interrupted!</span>")
				return
			soot -= rand(5,10)
			if(soot <= min_soot)
				soot = 0
				to_chat(user, "<span class='notice'>You finish cleaning the [src] with your hands.</span>")
				break

/obj/machinery/chaingun_loading_hopper/examine()
	. = ..()
	if(panel_open)
		. += "The maintenance panel is <b>unscrewed</b> and the machinery could be <i>pried out</i>."
	else
		. += "The maintenance panel is <b>closed</b> and could be <i>screwed open</i>."
	. += "<span class ='notice'>It has [belts]/[belts_capacity] ammunition belts seated inside.</span>"

/obj/machinery/chaingun_gyroscope
	name = "'Always Upright' Kinetic Gyroscope" //tbd
	icon = 'nsv13/icons/obj/chaingun_machines.dmi'
	icon_state = "gyro"
	desc = "This delicate machination is what allows the gun and dome to rotate properly." //placeholder
	anchored = FALSE
	density = TRUE
	panel_open = TRUE
	circuit = /obj/item/circuitboard/machine/chaingun_gyroscope
	layer = 3 //Want this to appear above the chaingun sprite

	var/obj/machinery/ship_weapon/chaingun/chaingun

	var/alignment = 100
	var/max_alignment = 100

/obj/item/circuitboard/machine/chaingun_gyroscope
	name = "circuit board (chaingun gyroscope)"
	desc = "spinny winny lookin' mf" //placeholder
	req_components = list(
		/obj/item/stack/sheet/iron = 50,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/micro_laser = 1,
	)
	build_path = /obj/machinery/chaingun_gyroscope

/obj/machinery/chaingun_gyroscope/wrench_act(mob/user, obj/item/tool)
	if(!panel_open)
		to_chat(user, "<span class='warning'>You can't reach the bolts, you have to <i>unscrew</i> the panel open first!</span>")
		return FALSE
	if(!anchored)
		var/turf/T = get_turf(src)
		chaingun = (locate(/obj/machinery/ship_weapon/chaingun) in T)
		var/turf/GT = chaingun?.gyro_turf
		if(!chaingun || T != GT)
			to_chat(user, "<span class='warning'>You can't connect the [src] here!</span>")
			return FALSE
		tool.play_tool_sound(src, 50)
		if(do_after(user, 5 SECONDS, target = src))
			(anchored = TRUE)
			to_chat(user, "<span class='notice'>You wrench down the bolts, anchoring the [src] to the floor.</span>")
			return TRUE
	else
		tool.play_tool_sound(src, 50)
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

/obj/machinery/chaingun_gyroscope/attack_hand(mob/living/user) //add alignment sound?
	. = ..()
	if(alignment == max_alignment)
		to_chat(user, "<span class='warning'>The [src] doesn't need your grubby hands in it yet!</span>")
		return
	if(panel_open && (alignment < max_alignment))
		to_chat(user, "<span class='notice'>You begin to align the [src] by hand...</span>")
		while(alignment < max_alignment)
			if(!do_after(user, 5, target = src))
				to_chat(user, "<span class='warning'>You were interrupted!</span>")
				return
			alignment += rand(1,2)
			if(alignment >= 100)
				alignment = 100
				to_chat(user, "<span class='notice'>You finish aligning the [src].</span>")
				break
