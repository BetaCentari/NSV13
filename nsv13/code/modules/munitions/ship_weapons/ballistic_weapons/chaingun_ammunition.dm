/obj/item/ship_weapon/ammunition/chaingun_belt
	name = "\improper ASA 'Severance' Ammunition Belt"
	desc = "A belt of 5 'Severance' 42mm cartridges meant to feed into a chaingun's ammo hopper." //42mm because it's the answer to life
	icon_state = "chaingun_belt"
	lefthand_file = 'nsv13/icons/mob/inhands/weapons/bombs_lefthand.dmi'
	righthand_file = 'nsv13/icons/mob/inhands/weapons/bombs_righthand.dmi'
	icon = 'nsv13/icons/obj/munitions.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	projectile_type = /obj/item/projectile/bullet/chaingun

/obj/machinery/chaingun_loading_hopper/attackby(obj/item/I, mob/living/user, params) //Add/make sounds
	. = ..()
	if(istype(I, /obj/item/ship_weapon/ammunition/chaingun_belt))
		if(shells == 0)
			to_chat(user, "<span class='notice'>You <i>very</i> carefully feed the belt into the mechanism...</span>")
			if(!do_after(user, 15 SECONDS, target = src))
				user.apply_damage(5, BRUTE, pick(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM))
				to_chat(user, "<span class='userdanger'>Something chews up your arm!</span>")
				return FALSE
			else
				to_chat(user, "<span class='notice'>You <i>very</i> carefully feed the belt into the mechanism...</span>")
				shells = (shells += 5)
				return TRUE
		if(shells > 0 && shells < 90)
			if(!do_after(user, 3 SECONDS, target = src))
				to_chat(user, "<span class='warning'>You were interrupted!</span>")
				return FALSE
			else
				to_chat(user, "<span class='notice'>You carefully link the chain belts together...</span>")
				shells = (shells += 5)
				return TRUE
