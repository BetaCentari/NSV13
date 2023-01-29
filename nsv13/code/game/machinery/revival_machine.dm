//I apologize in advanced Skink, for what you're about to witness. I never said I was a good coder T_T

#define CLONE_INITIAL_DAMAGE     150    //Redefining from cloning.dm
#define MINIMUM_HEAL_LEVEL 40
/obj/machinery/clonepod/revival
	name = "revival machine"
	desc = "An old revival machine from when cloning was first discovered. It smells metallic."
	//Create new sprites, new sounds, animations
	speed_coeff = 20
	fleshamnt = 0
	//New (old) materials required for cloning
	var/bonemeal_req = 1
	var/plasm_req = 1

	//Variables for potential health complications after cloning
	var/complication = 4
	var/appearance_apgar = 0
	var/pulse_apgar = 0
	var/grimace_apgar = 0
	var/activity_apgar = 0
	var/respiration_apgar = 0


/obj/machinery/clonepod/revival/proc/apgar_random() //Add complication percentage that changes with better parts
	var/apgar_random = rand(complication*7, 50)
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
			mob_occupant.adjustStaminaLoss(100)
		if(1)
			mob_occupant.adjustStaminaLoss(50)
	switch(activity_apgar)
		if(0)
			mob_occupant.Paralyze(150 SECONDS)
		if(1)
			mob_occupant.adjustStaminaLoss(120)
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
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50, 100)
	volume = 200
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	resistance_flags = ACID_PROOF

/obj/item/reagent_containers/glass/bonemeal_canister
	name = "plasm canister"
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
		/obj/item/stock_parts/manipulator = 4,
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

#undef CLONE_INITIAL_DAMAGE //undefining again like cloning.dm
#undef MINIMUM_HEAL_LEVEL
