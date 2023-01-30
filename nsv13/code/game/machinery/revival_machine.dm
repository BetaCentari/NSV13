//I apologize in advanced Skink, for what you're about to witness. I never said I was a good coder T_T

#define CLONE_INITIAL_DAMAGE     150    //Redefining from cloning.dm
#define MINIMUM_HEAL_LEVEL 40

#define SPEAK(message) radio.talk_into(src, message, radio_channel)

/obj/machinery/clonepod/revival
	name = "revival machine"
	desc = "An old revival machine from when cloning was first discovered. It smells metallic."
	//Create new sprites, new sounds, animations
	speed_coeff = 20
	fleshamnt = null
	//New (old) materials required for cloning
	var/bonemeal_req = 1
	var/plasm_req = 1
	var/obj/item/reagent_containers/glass/bonemeal_canister = null
	var/obj/item/reagent_containers/glass/plasm_canister = null

	//Variables for potential health complications after cloning
	var/complication = 10 //Don't ask me why this has to be 10
	var/appearance_apgar = 0
	var/pulse_apgar = 0
	var/grimace_apgar = 0
	var/activity_apgar = 0
	var/respiration_apgar = 0


/obj/machinery/clonepod/revival/proc/apgar_random() //Add complication percentage that changes with better parts
	var/apgar_random = rand(complication*3, 50)
	switch(apgar_random)
		if(0 to 35)
			return 2
		if(36 to 45)
			return 1
		if(46 to 50)
			return 0

/obj/machinery/clonepod/revival/RefreshParts()
	speed_coeff = 20
	efficiency = 0
	reagents.maximum_volume = 0
	for(var/obj/item/stock_parts/scanning_module/S in component_parts)
		efficiency += S.rating
		bonemeal_req = 1/max(efficiency-1, 1)
		plasm_req = 1/max(efficiency-1, 1)
	for(var/obj/item/stock_parts/manipulator/P in component_parts)
		speed_coeff += P.rating
		complication -= P.rating
	heal_level = (efficiency * 15) + 10
	if(heal_level < MINIMUM_HEAL_LEVEL)
		heal_level = MINIMUM_HEAL_LEVEL
	if(heal_level > 100)
		heal_level = 100

//Write examine text

/obj/machinery/clonepod/revival/process()
	var/mob/living/mob_occupant = occupant

	if(!is_operational) //Autoeject if power is lost (or the pod is dysfunctional due to whatever reason)
		if(mob_occupant)
			go_out()
			log_cloning("[key_name(mob_occupant)] ejected from [src] at [AREACOORD(src)] due to power loss.")

			connected_message("Clone Ejected: Loss of power.")

	else if(mob_occupant && (mob_occupant.loc == src))
		if(!reagents.has_reagent(/datum/reagent/bonemeal, bonemeal_req) || !reagents.has_reagent(/datum/reagent/plasm, plasm_req))
			go_out()
			log_cloning("[key_name(mob_occupant)] ejected from [src] at [AREACOORD(src)] due to insufficient material.")
			connected_message("Clone Ejected: Not enough material.")
			if(internal_radio)
				SPEAK("The cloning of [mob_occupant.real_name] has been ended prematurely due to insufficient material.")
		else if(SSeconomy.full_ancap)
			if(!current_insurance)
				go_out()
				log_cloning("[key_name(mob_occupant)] ejected from [src] at [AREACOORD(src)] due to invalid bank account.")
				connected_message("Clone Ejected: No bank account.")
				if(internal_radio)
					SPEAK("The cloning of [mob_occupant.real_name] has been terminated due to no bank account to draw payment from.")
			else if(!current_insurance.adjust_money(-fair_market_price))
				go_out()
				log_cloning("[key_name(mob_occupant)] ejected from [src] at [AREACOORD(src)] due to insufficient funds.")
				connected_message("Clone Ejected: Out of Money.")
				if(internal_radio)
					SPEAK("The cloning of [mob_occupant.real_name] has been ended prematurely due to being unable to pay.")
			else
				var/datum/bank_account/department/D = SSeconomy.get_dep_account(payment_department)
				if(D && !D.is_nonstation_account())
					D.adjust_money(fair_market_price)
		if(mob_occupant && (mob_occupant.stat == DEAD) || (mob_occupant.suiciding) || mob_occupant.ishellbound())  //Autoeject corpses and suiciding dudes.
			connected_message("Clone Rejected: Deceased.")
			if(internal_radio)
				SPEAK("The cloning of [mob_occupant.real_name] has been \
					aborted due to unrecoverable tissue failure.")
			go_out()
			log_cloning("[key_name(mob_occupant)] ejected from [src] at [AREACOORD(src)] after suiciding.")

		else if(mob_occupant && mob_occupant.cloneloss > (100 - heal_level))
			mob_occupant.Unconscious(80)
			var/dmg_mult = CONFIG_GET(number/damage_multiplier)
			 //Slowly get that clone healed and finished.
			mob_occupant.adjustCloneLoss(-((speed_coeff / 2) * dmg_mult), TRUE, TRUE)
			if(reagents.has_reagent(/datum/reagent/bonemeal, bonemeal_req) && reagents.has_reagent(/datum/reagent/plasm, plasm_req))
				reagents.remove_reagent(/datum/reagent/bonemeal, bonemeal_req)
				reagents.remove_reagent(/datum/reagent/plasm, plasm_req)
			var/progress = CLONE_INITIAL_DAMAGE - mob_occupant.getCloneLoss()
			// To avoid the default cloner making incomplete clones
			progress += (100 - MINIMUM_HEAL_LEVEL)
			var/milestone = CLONE_INITIAL_DAMAGE / flesh_number
			var/installed = flesh_number - unattached_flesh.len

			if((progress / milestone) >= installed)
				// attach some flesh
				var/obj/item/I = pick_n_take(unattached_flesh)
				if(isorgan(I))
					var/obj/item/organ/O = I
					O.organ_flags &= ~ORGAN_FROZEN
					O.Insert(mob_occupant)
				else if(isbodypart(I))
					var/obj/item/bodypart/BP = I
					BP.attach_limb(mob_occupant)

			use_power(5000 * speed_coeff) //This might need tweaking.

		else if(mob_occupant && (mob_occupant.cloneloss <= (100 - heal_level)))
			connected_message("Cloning Process Complete.")
			if(internal_radio)
				SPEAK("The cloning cycle of [mob_occupant.real_name] is complete.")

			// If the cloner is upgraded to debugging high levels, sometimes
			// organs and limbs can be missing.
			for(var/i in unattached_flesh)
				if(isorgan(i))
					var/obj/item/organ/O = i
					O.organ_flags &= ~ORGAN_FROZEN
					O.Insert(mob_occupant)
				else if(isbodypart(i))
					var/obj/item/bodypart/BP = i
					BP.attach_limb(mob_occupant)

			go_out()
			log_cloning("[key_name(mob_occupant)] completed cloning cycle in [src] at [AREACOORD(src)].")

	else if (!mob_occupant || mob_occupant.loc != src)
		occupant = null
		if (!mess && !panel_open)
			icon_state = "pod_0"
		use_power(200)

/obj/machinery/clonepod/revival/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/glass/plasm_canister))
		. = 1 //no afterattack
		if(plasm_canister)
			to_chat(user, "<span class='warning'>A plasm canister is already loaded into [src]!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		plasm_canister = I
		user.visible_message("[user] places [I] in [src].", \
							"<span class='notice'>You place [I] in [src].</span>")
		var/reagentlist = pretty_string_from_reagent_list(I.reagents.reagent_list)
		log_game("[key_name(user)] added a [I] to revival containing [reagentlist]")
		return
	if(istype(I, /obj/item/reagent_containers/glass/bonemeal_canister))
		. = 1 //no afterattack
		if(bonemeal_canister)
			to_chat(user, "<span class='warning'>A plasm canister is already loaded into [src]!</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		bonemeal_canister = I
		user.visible_message("[user] places [I] in [src].", \
							"<span class='notice'>You place [I] in [src].</span>")
		var/reagentlist = pretty_string_from_reagent_list(I.reagents.reagent_list)
		log_game("[key_name(user)] added a [I] to revival containing [reagentlist]")
		return

/obj/machinery/clonepod/revival/AltClick(mob/user)
	if(bonemeal_canister)
		bonemeal_canister.forceMove(drop_location())
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(bonemeal_canister)
		bonemeal_canister = null
		user.visible_message("<span class='notice'>[user] removes the bonemeal canister from [src]</span>")

	if(plasm_canister)
		plasm_canister.forceMove(drop_location())
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(plasm_canister)
		plasm_canister = null
		user.visible_message("<span class='notice'>[user] removes the plasm canister from [src]</span>")
	else
		user.visible_message("<span class='notice'>[user] tries to remove something from [src] but nothing was there.")

/obj/machinery/clonepod/revival/growclone(clonename, ui, mutation_index, mindref, last_death, datum/species/mrace, list/features, factions, list/quirks, datum/bank_account/insurance, list/traumas, body_only, experimental)
	var/result = CLONING_SUCCESS
	if(!reagents.has_reagent(/datum/reagent/bonemeal, bonemeal_req) || !reagents.has_reagent(/datum/reagent/plasm, plasm_req))
		connected_message("Cannot start cloning: Not enough raw materials.")
		return ERROR_NO_SYNTHFLESH
	if(panel_open)
		return ERROR_PANEL_OPENED
	if(mess || attempting)
		return ERROR_MESS_OR_ATTEMPTING
	if(experimental && !experimental_pod)
		return ERROR_MISSING_EXPERIMENTAL_POD

	if(!body_only && !(experimental && experimental_pod))
		clonemind = locate(mindref) in SSticker.minds
		if(!istype(clonemind))	//not a mind
			return ERROR_NOT_MIND
		//if(last_death<0) //presaved clone is not clonable
		//	return ERROR_PRESAVED_CLONE
		if((last_death > 0) && (abs(clonemind.last_death - last_death) > 5)) //You can't clone old ones. 5 seconds grace because a sync-failure can happen. //NSV13 - allow precloning
			return ERROR_OUTDATED_CLONE
		if(!QDELETED(clonemind.current))
			if(clonemind.current.stat != DEAD)	//mind is associated with a non-dead body
				return ERROR_ALREADY_ALIVE
			if(clonemind.current.suiciding) // Mind is associated with a body that is suiciding.
				return ERROR_COMMITED_SUICIDE
		if(!clonemind.active)
			// get_ghost() will fail if they're unable to reenter their body
			var/mob/dead/observer/G = clonemind.get_ghost()
			if(!G)
				return ERROR_SOUL_DEPARTED
			if(G.suiciding) // The ghost came from a body that is suiciding.
				return ERROR_SUICIDED_BODY
		if(clonemind.damnation_type) //Can't clone the damned.
			INVOKE_ASYNC(src, .proc/horrifyingsound)
			mess = TRUE
			icon_state = "pod_g"
			update_icon()
			return ERROR_SOUL_DAMNED
		if(clonemind.no_cloning_at_all) // nope.
			return ERROR_UNCLONABLE
		current_insurance = insurance
	attempting = TRUE //One at a time!!
	countdown.start()

	var/mob/living/carbon/human/H = new /mob/living/carbon/human(src)

	H.hardset_dna(ui, mutation_index, H.real_name, null, mrace, features)

	if(!HAS_TRAIT(H, TRAIT_RADIMMUNE))//dont apply mutations if the species is Mutation proof.
		if(efficiency > 2)
			var/list/unclean_mutations = (GLOB.not_good_mutations|GLOB.bad_mutations)
			H.dna.remove_mutation_group(unclean_mutations)
		if(efficiency > 5 && prob(20))
			H.easy_randmut(POSITIVE)
		if(efficiency < 3 && prob(50))
			var/mob/M = H.easy_randmut(NEGATIVE+MINOR_NEGATIVE)
			if(ismob(M))
				H = M

	H.silent = 20 //Prevents an extreme edge case where clones could speak if they said something at exactly the right moment.
	occupant = H

	if(!clonename)	//to prevent null names
		clonename = "clone ([rand(1,999)])"
	H.real_name = clonename

	icon_state = "pod_1"
	//Get the clone body ready
	maim_clone(H)
	ADD_TRAIT(H, TRAIT_STABLEHEART, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_STABLELIVER, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_EMOTEMUTE, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_MUTE, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_NOBREATH, CLONING_POD_TRAIT)
	ADD_TRAIT(H, TRAIT_NOCRITDAMAGE, CLONING_POD_TRAIT)
	H.Unconscious(80)

	if(!experimental && !experimental_pod && !body_only) //everything should be perfect to none
		clonemind.transfer_to(H)
	else if(!(!experimental && body_only))
		current_insurance = insurance
		offer_to_ghost(H)
		result = CLONING_SUCCESS_EXPERIMENTAL

	if(H.mind)
		if(grab_ghost_when == CLONER_FRESH_CLONE)
			H.grab_ghost()
			to_chat(H, "<span class='notice'><b>Consciousness slowly creeps over you as your body regenerates.</b><br><i>So this is what cloning feels like?</i></span>")

		if(grab_ghost_when == CLONER_MATURE_CLONE)
			H.ghostize(TRUE)	//Only does anything if they were still in their old body and not already a ghost
			to_chat(H.get_ghost(TRUE), "<span class='notice'>Your body is beginning to regenerate in a cloning pod. You will become conscious when it is complete.</span>")

	if(H)
		H.faction |= factions
		remove_hivemember(H)

		for(var/V in quirks)
			var/datum/quirk/Q = new V(H)
			Q.on_clone(quirks[V])

		for(var/t in traumas)
			var/datum/brain_trauma/BT = t
			var/datum/brain_trauma/cloned_trauma = BT.on_clone()
			if(cloned_trauma)
				H.gain_trauma(cloned_trauma, BT.resilience)

		H.set_cloned_appearance()

		H.set_suicide(FALSE)
	to_chat(H, "<span class='warning'><b>You are being cloned. You cannot remember how you died.</b></span>") //NSV13
	attempting = FALSE
	return result

/obj/machinery/clonepod/revival/go_out() //Spits out the clone and determines complications alongside normal cloning problems
	appearance_apgar = apgar_random()
	pulse_apgar = apgar_random()
	grimace_apgar = apgar_random()
	activity_apgar = apgar_random()
	respiration_apgar = apgar_random()
	var/mob/living/carbon/mob_occupant = occupant
	var/apgar_total = appearance_apgar + pulse_apgar + grimace_apgar + activity_apgar + respiration_apgar
	switch(appearance_apgar)
		if(0)
			mob_occupant.adjust_bodytemperature(-65)
		if(1)
			mob_occupant.adjust_bodytemperature(-45)
	switch(pulse_apgar)
		if(0)
			mob_occupant.set_heartattack(TRUE)
		if(1)
			var/datum/disease/D = new /datum/disease/heart_failure()
			mob_occupant.ForceContractDisease(D, FALSE, TRUE)
	switch(grimace_apgar)
		if(0)
			mob_occupant.adjustStaminaLoss(120)
		if(1)
			mob_occupant.adjustStaminaLoss(50)
	switch(activity_apgar)
		if(0)
			mob_occupant.Paralyze(150 SECONDS)
		if(1)
			mob_occupant.Paralyze(30 SECONDS)
	switch(respiration_apgar)
		if(0)
			mob_occupant.adjustOxyLoss(60)
		if(1)
			mob_occupant.adjustOxyLoss(40)
	say("APGAR Score [apgar_total]")
	switch(apgar_total)
		if(9 to 10)
			say("Healthy patient, little to no complications.")
		if(7 to 8)
			say("Minor complications, medical attention recommended.")
		if(4 to 6)
			say("Major complications, medical attention required, recycle recommended.")
		if(1 to 4)
			say("Critical complications, recycle required.")
		if(0)
			say("Stillborn patient, recycle body immediately.")
	. = ..()
	mess = TRUE //Clean out the machine every time it's used

/obj/item/reagent_containers/glass/plasm_canister
	name = "plasm canister"
	icon = 'icons/obj/chemical.dmi' //Temp Sprite
	icon_state = "beaker"
	item_state = "beaker"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50, 100)
	volume = 200
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	resistance_flags = ACID_PROOF

/obj/item/reagent_containers/glass/bonemeal_canister
	name = "bonemeal canister"
	icon = 'icons/obj/chemical.dmi' //Temp Sprite
	icon_state = "beaker"
	item_state = "beaker"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50, 100)
	volume = 200
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	resistance_flags = ACID_PROOF

/obj/item/circuitboard/machine/clonepod/revival
	name = "revival machine (Machine Board)"
	icon_state = "medical"
	build_path = /obj/machinery/clonepod/revival
	req_components = list(
		/obj/item/stack/cable_coil = 2,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stack/sheet/iron = 5)

/datum/reagent/bonemeal
	name = "Bonemeal"
	description = "A liquified calcium hydroxyapatite suspended in fluid for use in an old fashioned revival machine."
	reagent_state = LIQUID
	color = "#FFFFFF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_DRUG | CHEMICAL_GOAL_CHEMIST_BLOODSTREAM

/datum/reagent/plasm
	name = "Plasm"
	description = "A fluidic concoction of organic compounds resembling blood plasma and other basic proteins for use in a revival machine"
	reagent_state = LIQUID
	color = "#948f2c"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_CHEMIST_DRUG | CHEMICAL_GOAL_CHEMIST_BLOODSTREAM

/datum/chemical_reaction/rapidoxadone
	name = "Rapidoxadone"
	id = /datum/reagent/medicine/rapidoxadone
	results = list(/datum/reagent/medicine/rapidoxadone = 3)
	required_reagents = list(/datum/reagent/medicine/clonexadone = 1, /datum/reagent/medicine/pyroxadone = 1, /datum/reagent/medicine/cryoxadone = 1)
	required_catalysts = new/list(/datum/reagent/toxin/plasma = 1)

/datum/reagent/medicine/rapidoxadone
	name = "Rapidoxadone"
	description = "A dangerous chemical that can rapidly heal damage done by the cloning process but is quite toxic. It was outlawed a long time ago."
	color = "#7700ff"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BARTENDER_SERVING
	taste_description = "urple"
	overdose_threshold = 15

/datum/reagent/medicine/rapidoxadone/on_mob_life(mob/living/carbon/M)
	M.adjustToxLoss(1) //Trade 5 CLone Damage for half a tox damage
	M.adjustCloneLoss(-5)
	REMOVE_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC) //fixes common causes for disfiguration
	..()

/datum/reagent/medicine/rapidoxadone/overdose_start(mob/living/M) //Don't OD, your cells will completely fall apart
	to_chat(M, "<span class='userdanger'>YOU EXPLOSIVELY LIQUEFACT!</span>")
	M.visible_message("<span class='warning'>[M] experiences something that could be described as explosive liquefaction!</span>")
	playsound(M, 'sound/effects/spray.ogg', 10, 1, -3)
	if (!QDELETED(M))
		for(var/obj/item/W in M)
			M.dropItemToGround(W)
			if(prob(50))
				step(W, pick(GLOB.alldirs))
		ADD_TRAIT(M, TRAIT_DISFIGURED, TRAIT_GENERIC)
		M.gib_animation()
		sleep(3)
		M.adjustBruteLoss(1000)
		M.spawn_gibs()
		M.spill_organs()
		M.spread_bodyparts()
	return TRUE

#undef CLONE_INITIAL_DAMAGE //undefining again like cloning.dm
#undef MINIMUM_HEAL_LEVEL
#undef SPEAK
