//Works like a gibber and a reagent grinder in one

/obj/machinery/body_recycler
	name = "Recycler"
	desc = "A gruesome machine designed to extract reagents from humanoid corpses for use in a revival machine"
	icon = 'icons/obj/kitchen.dmi' //Temp Sprite
	icon_state = "grinder"
	circuit = /obj/item/circuitboard/machine/body_recycler

	var/operating = FALSE //Is it on?
	var/filthy = FALSE // Does it need cleaning?
	var/grindtime = 300 // Time from starting until it fills the canisters
	var/efficiency = 1 //How much does it extract
	var/ignore_clothing = FALSE //Strip the dead!
	var/jammed = FALSE //Did you strip the dead? Or just get unlucky

	var/list/holdingitems //So we can grind organs and limbs

	var/obj/item/reagent_containers/glass/bonemeal_canister //Need to have canisters for it to fill
	var/obj/item/reagent_containers/glass/plasma_canister

/obj/machinery/body_recycler/Initialize(mapload)
	holdingitems = list()
	. = ..()

/obj/machinery/body_recycler/RefreshParts()
	grindtime = 300
	efficiency = 1
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		efficiency += B.rating
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		grindtime -= 20 * M.rating
		if(M.rating >= 2)
			ignore_clothing = TRUE

/obj/machinery/body_recycler/attack_paw(mob/user)
	return attack_hand(user)

/obj/machinery/body_recycler/container_resist(mob/living/user)
	go_out()

/obj/machinery/body_recycler/relaymove(mob/living/user)
	go_out()

/obj/machinery/body_recycler/attack_hand(mob/user) //Add organs and limbs to be ground
	. = ..()
	if(.)
		return
	if(machine_stat & (NOPOWER|BROKEN))
		return
	if(operating)
		to_chat(user, "<span class='danger'>It's locked and running.</span>")
		return

	if(jammed) //Add awful grinding noise
		visible_message("<span class='danger'>The blades are caught on something!</span>")
		return

	if(!anchored)
		to_chat(user, "<span class='notice'>\The [src] cannot be used unless bolted to the ground.</span>")
		return

	if(user.pulling && user.a_intent == INTENT_GRAB && isliving(user.pulling))
		var/mob/living/L = user.pulling
		if(!iscarbon(L))
			to_chat(user, "<span class='danger'>Patient is still alive, euthanize patient before recycling!</span>")
			return
		var/mob/living/carbon/C = L
		if(C.buckled ||C.has_buckled_mobs())
			to_chat(user, "<span class='warning'>[C] is attached to something!</span>")
			return

		if(!ignore_clothing)
			for(var/obj/item/I in C.held_items + C.get_equipped_items())
				if(!HAS_TRAIT(I, TRAIT_NODROP))
					startgrinding(user)
					jammed = TRUE //STRIP YOUR DAMNED DEAD I SAID

		user.visible_message("<span class='danger'>[user] starts to put [C] into the gibber!</span>")

		add_fingerprint(user)

		if(do_after(user, 10 SECONDS, target = src))
			if(C && user.pulling == C && !C.buckled && !C.has_buckled_mobs() && !occupant)
				user.visible_message("<span class='danger'>[user] stuffs [C] into the gibber!</span>")
				C.forceMove(src)
				occupant = C
				update_icon()
	else
		startgrinding(user)

/obj/machinery/body_recycler/verb/eject()
	set category = "Object"
	set name = "empty recycler"
	set src in oview(1)

	if(usr.incapacitated())
		return
	src.go_out()
	add_fingerprint(usr)
	return

/obj/machinery/body_recycler/proc/go_out()
	dropContents()
	update_icon()

/obj/machinery/body_recycler/proc/drop_all_items()
	for(var/i in holdingitems)
		var/atom/movable/AM = i
		AM.forceMove(drop_location())
	holdingitems = list()

/obj/machinery/body_recycler/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Working at <b>[efficiency*50]%</b> efficiency after <b>[grindtime*0.1]</b> seconds of processing.</span>"
		for(var/obj/item/stock_parts/manipulator/M in component_parts)
			if(M.rating >= 2)
				. += "<span class='notice'>The recycler has been upgraded to process inorganic materials.</span>"

/obj/machinery/body_recycler/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/organ) || istype(I, /obj/item/bodypart))
		. = 1 //no afterattack
		if(istype(I, /obj/item/organ/brain))
			to_chat(user, "<span class='warning'>The machine won't recycle a brain!</span>")
			return
		else
			if(!user.transferItemToLoc(I, src))
				return
			if(user.transferItemToLoc(I, src))
				to_chat(user, "<span class='notice'>You add [I] to [src].</span>")
				holdingitems[I] = TRUE
				return FALSE


	if(istype(I, /obj/item/reagent_containers/glass/plasma_canister))
		. = 1 //no afterattack
		if(plasma_canister)
			to_chat(user, "<span class='warning'>A plasma canister is already loaded into \the [src]!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		plasma_canister = I
		user.visible_message("[user] places [I] in \the [src].", \
							"<span class='notice'>You place [I] in \the [src].</span>")
		var/reagentlist = pretty_string_from_reagent_list(I.reagents.reagent_list)
		log_game("[key_name(user)] added a [I] to body recycler containing [reagentlist]")
		return
	if(istype(I, /obj/item/reagent_containers/glass/bonemeal_canister))
		. = 1 //no afterattack
		if(bonemeal_canister)
			to_chat(user, "<span class='warning'>A bonemeal canister is already loaded into \the [src]!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		bonemeal_canister = I
		user.visible_message("[user] places [I] in \the [src].", \
							"<span class='notice'>You place [I] in \the [src].</span>")
		var/reagentlist = pretty_string_from_reagent_list(I.reagents.reagent_list)
		log_game("[key_name(user)] added a [I] to body recycler containing [reagentlist]")
		return

	if(istype(I, /obj/item/reagent_containers/spray))
		var/obj/item/reagent_containers/spray/clean_spray = I
		if(clean_spray.reagents.has_reagent(/datum/reagent/space_cleaner, clean_spray.amount_per_transfer_from_this))
			clean_spray.reagents.remove_reagent(/datum/reagent/space_cleaner, clean_spray.amount_per_transfer_from_this,1)
			playsound(loc, 'sound/effects/spray3.ogg', 50, 1, -6)
			user.visible_message("[user] has cleaned \the [src].", "<span class='notice'>You clean \the [src].</span>")
			filthy = FALSE
			update_icon()
		else
			to_chat(user, "<span class='warning'>You need more space cleaner!</span>")
		return TRUE

	if(istype(I, /obj/item/soap) || istype(I, /obj/item/reagent_containers/glass/rag))
		var/cleanspeed = 50
		if(istype(I, /obj/item/soap))
			var/obj/item/soap/used_soap = I
			cleanspeed = used_soap.cleanspeed
		user.visible_message("[user] starts to clean \the [src].", "<span class='notice'>You start to clean \the [src]...</span>")
		if(do_after(user, cleanspeed, target = src))
			user.visible_message("[user] has cleaned \the [src].", "<span class='notice'>You clean \the [src].</span>")
			filthy = FALSE
			update_icon()
		return TRUE

	if(filthy) // It's dirty, smells awful
		to_chat(user, "<span class='warning'>\The [src] is filthy!</span>")

	if(default_deconstruction_screwdriver(user, "grinder_open", "grinder", I)) //Change Sprites Here
		go_out()
		return

	else if(default_pry_open(I))
		return

	else if(default_unfasten_wrench(user, I))
		return

	else if(default_deconstruction_crowbar(I))
		return

	if(I.tool_behaviour == TOOL_WIRECUTTER)
		if(jammed && panel_open)
			jammed = FALSE
			to_chat(user, "You use \the [I] to clear the jam inside \the [src]")
			return
	..()

/obj/machinery/body_recycler/AltClick(mob/user)
	if(bonemeal_canister)
		bonemeal_canister.forceMove(drop_location())
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(bonemeal_canister)
		bonemeal_canister = null
		user.visible_message("<span class='notice'>[user] removes the bonemeal canister from \the [src]</span>")

	if(plasma_canister)
		plasma_canister.forceMove(drop_location())
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(plasma_canister)
		plasma_canister = null
		user.visible_message("<span class='notice'>[user] removes the plasma canister from \the [src]</span>")

	if(!bonemeal_canister && !plasma_canister)
		drop_all_items()
		user.visible_message("<span class='notice'>[user] dumps out the \the [src]</span>")

/obj/machinery/body_recycler/proc/startgrinding(mob/user)
	if(src.operating)
		return
	if(!src.occupant && length(holdingitems) == 0)
		visible_message("<span class='italics'>You hear a loud metallic grinding sound.</span>")
		return
	use_power(1000)
	visible_message("<span class='italics'>You hear a loud squelchy grinding sound.</span>")
	playsound(src.loc, 'sound/machines/juicer.ogg', 50, 1)
	operating = TRUE
	update_icon()

	var/mob/living/mob_occupant = occupant
	var/list/datum/disease/diseases = mob_occupant?.get_static_viruses()
	var/occupant_volume
	if(occupant?.reagents)
		occupant_volume = occupant.reagents.total_volume
	if(occupant_volume)
		occupant.reagents.trans_to(bonemeal_canister && plasma_canister, occupant_volume / 2, remove_blacklisted = FALSE) //Split the reagents between both canisters

	for(var/i in holdingitems)
		if(bonemeal_canister && bonemeal_canister.reagents.total_volume >= bonemeal_canister.reagents.maximum_volume)
			break
		if(plasma_canister && plasma_canister.reagents.total_volume >= plasma_canister.reagents.maximum_volume)
			break
		var/obj/item/I = i
		if(I.grind_results)
			if(istype(I, /obj/item/reagent_containers))
				var/obj/item/reagent_containers/p = I
				if(!p.prevent_grinding)
					grind_item(p, user)
			else
				grind_item(I, user)



	if(occupant)
		log_combat(user, occupant, "ground")
	mob_occupant?.death(1)
	mob_occupant?.ghostize()
	qdel(src.occupant)
	addtimer(CALLBACK(src, .proc/fill_canisters, diseases), grindtime)

/obj/machinery/body_recycler/proc/grind_item(obj/item/I, mob/user) //Grind results can be found in respective object definitions
	if(I.on_grind(src) == -1) //Call on_grind() to change amount as needed, and stop grinding the item if it returns -1
		to_chat(usr, "<span class='danger'>[src] shorts out as it tries to grind up [I], and transfers it back to storage.</span>")
		return
	if(istype(I, /obj/item/bodypart))
		if(bonemeal_canister)
			bonemeal_canister.reagents.add_reagent_list(I.grind_results)
		else
			visible_message("<span class='warning'>Without a canister, the machine oozes bonemeal all over the ground!</span>")
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
	if(istype(I, /obj/item/organ))
		if(plasma_canister)
			plasma_canister.reagents.add_reagent_list(I.grind_results)
		else
			visible_message("<span class='warning'>Without a canister, the machine gushes blood plasma all over the ground!</span>")
			playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)
	if(I.reagents)
		I.reagents.trans_to(bonemeal_canister, I.reagents.total_volume / 2, transfered_by = user)
		I.reagents.trans_to(plasma_canister, I.reagents.total_volume / 2, transfered_by = user)
	remove_object(I)


//Make Dynamic limb/organ/body mincing for MORE CODING PAIN T-T try for(var/bodyparts in H.bodyparts)

/obj/machinery/body_recycler/proc/fill_canisters(var/list/datum/disease/diseases)
	if(bonemeal_canister)
		bonemeal_canister.reagents.add_reagent(/datum/reagent/bonemeal, efficiency * 20)
		if(filthy)
			bonemeal_canister.reagents.add_reagent(/datum/reagent/liquidgibs, 20)
	if(!bonemeal_canister)
		visible_message("<span class='warning'>Without a canister, the machine oozes bonemeal all over the ground!</span>")
		playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)

	if(plasma_canister)
		plasma_canister.reagents.add_reagent(/datum/reagent/blood_plasma, efficiency * 20)
		if(filthy)
			plasma_canister.reagents.add_reagent(/datum/reagent/liquidgibs, 20)
	if(!plasma_canister)
		visible_message("<span class='warning'>Without a canister, the machine gushes blood plasma all over the ground!</span>")
		playsound(src.loc, 'sound/effects/splat.ogg', 50, 1)

	pixel_x = base_pixel_x //return to its spot after shaking
	operating = FALSE
	update_icon()
	filthy = TRUE


/obj/machinery/body_recycler/proc/remove_object(obj/item/O)
	holdingitems -= O
	qdel(O)

/obj/item/circuitboard/machine/body_recycler
	name = "body recycler (Machine Board)"
	icon_state = "medical"
	build_path = /obj/machinery/body_recycler
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/manipulator = 3)
	needs_anchored = FALSE
