/obj/machinery/body_recycler
	name = "Recycler"
	desc = "A gruesome machine designed to extract reagents from humanoid corpses for use in a revival machine"
	icon = 'icons/obj/kitchen.dmi' //Temp Sprite
	icon_state = "grinder"
	circuit = /obj/item/circuitboard/machine/body_recycler

	var/operating = FALSE //Is it on?
	var/filthy = FALSE // Does it need cleaning?
	var/grindtime = 40 // Time from starting until it fills the canisters
	var/efficiency = 1 //How much does it extract
	var/ignore_clothing = FALSE //Strip the dead!
	var/jammed = FALSE //Did you strip the dead? Or just get unlucky

	var/obj/item/reagent_containers/glass/bonemeal_canister //Need to have canisters for it to fill
	var/obj/item/reagent_containers/glass/plasma_canister

/obj/machinery/body_recycler/Initialize(mapload)
	. = ..()

/obj/machinery/body_recycler/RefreshParts()
	grindtime = 40
	efficiency = 1
	for(var/obj/item/stock_parts/matter_bin/B in component_parts)
		efficiency += B.rating
	for(var/obj/item/stock_parts/manipulator/M in component_parts)
		grindtime -= 5 * M.rating
		if(M.rating >= 2)
			ignore_clothing = TRUE

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

/obj/machinery/body_recycler/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Working at <b>[efficiency*50]%</b> efficiency after <b>[grindtime*0.1]</b> seconds of processing.</span>"
		for(var/obj/item/stock_parts/manipulator/M in component_parts)
			if(M.rating >= 2)
				. += "<span class='notice'>The recycler has been upgraded to process inorganic materials.</span>"

/obj/machinery/body_recycler/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/glass/plasma_canister))
		. = 1 //no afterattack
		if(plasma_canister)
			to_chat(user, "<span class='warning'>A plasma canister is already loaded into [src]!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		plasma_canister = I
		user.visible_message("[user] places [I] in [src].", \
							"<span class='notice'>You place [I] in [src].</span>")
		var/reagentlist = pretty_string_from_reagent_list(I.reagents.reagent_list)
		log_game("[key_name(user)] added a [I] to body recycler containing [reagentlist]")
		return
	if(istype(I, /obj/item/reagent_containers/glass/bonemeal_canister))
		. = 1 //no afterattack
		if(bonemeal_canister)
			to_chat(user, "<span class='warning'>A bonemeal canister is already loaded into [src]!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		bonemeal_canister = I
		user.visible_message("[user] places [I] in [src].", \
							"<span class='notice'>You place [I] in [src].</span>")
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
		return TRUE
	..()

/obj/machinery/body_recycler/AltClick(mob/user)
	if(bonemeal_canister)
		bonemeal_canister.forceMove(drop_location())
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(bonemeal_canister)
		bonemeal_canister = null
		user.visible_message("<span class='notice'>[user] removes the bonemeal canister from [src]</span>")

	if(plasma_canister)
		plasma_canister.forceMove(drop_location())
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(plasma_canister)
		plasma_canister = null
		user.visible_message("<span class='notice'>[user] removes the plasma canister from [src]</span>")
	else
		user.visible_message("<span class='notice'>[user] tries to remove something from [src] but nothing was there.")

/obj/machinery/body_recycler/proc/startgrinding(mob/user)
	if(src.operating)
		return
	if(!src.occupant)
		visible_message("<span class='italics'>You hear a loud metallic grinding sound.</span>")
		return
	use_power(1000)
	visible_message("<span class='italics'>You hear a loud squelchy grinding sound.</span>")
	playsound(src.loc, 'sound/machines/juicer.ogg', 50, 1)
	operating = TRUE
	filthy = TRUE
	update_icon()

	var/offset = prob(50) ? -2 : 2
	animate(src, pixel_x = pixel_x + offset, time = 0.2, loop = 200) //start shaking
	var/mob/living/mob_occupant = occupant


	var/list/datum/disease/diseases = mob_occupant.get_static_viruses()
	var/occupant_volume
	if(occupant?.reagents)
		occupant_volume = occupant.reagents.total_volume
	if(occupant_volume)
		occupant.reagents.trans_to(bonemeal_canister && plasma_canister, occupant_volume / 2, remove_blacklisted = FALSE) //Split the reagents between both canisters





	log_combat(user, occupant, "ground")
	mob_occupant.death(1)
	mob_occupant.ghostize()
	qdel(src.occupant)
	addtimer(CALLBACK(src, .proc/fill_canisters, diseases), grindtime)

//Find a way to add diseases to the reagents inside the canistersbo

//Make Dynamic limb/organ/body mincing for MORE CODING PAIN T-T try for(var/bodyparts in H.bodyparts)

/obj/machinery/body_recycler/proc/fill_canisters()
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

/obj/item/circuitboard/machine/body_recycler
	name = "body recycler (Machine Board)"
	icon_state = "medical"
	build_path = /obj/machinery/body_recycler
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stock_parts/manipulator = 3)
	needs_anchored = FALSE
