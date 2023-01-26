//I apologize in advanced Skink, for what you're about to witness. I never said I was a good coder T_T

/obj/machinery/clonepod/revival
	//Create new sprites, new sounds, animations
	speed_coeff = 20
	fleshamnt = 0
	//New (old) materials required for cloning
	var/bone_meal_req = 1
	var/plasm_req = 1

	//Variables for potential health complications after cloning
	var/complication = 1
	var/appearance_apgar = 0
	var/pulse_apgar = 0
	var/grimace_apgar = 0
	var/activity_apgar = 0
	var/respiration_apgar = 0


/obj/machinery/clonepod/revival/proc/apgar_random() //Add complication percentage that changes with better parts
	var/apgar_random = rand(1, 100)
	switch(apgar_random)
		if(1 to 70)
			return 2
		if(71 to 90)
			return 1
		if(91 to 100)
			return 0

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
