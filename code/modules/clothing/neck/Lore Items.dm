//Lore Implentation Items

/obj/effect/spawner/lootdrop/lore_items
	name = "lore item spawner"
	loot = list(
			/obj/item/clothing/neck/moon_fragment_necklace = 1
			/obj/structure/fluff/bureaucratic_papers = 1
			/obj/item/toy/torch_effigy = 1
			/obj/item/toy/crystal_shard = 1
			/obj/item/toy/old_record = 1
		)

/obj/item/clothing/neck/moon_fragment_necklace
    name = "moon fragment necklace"
    desc = "A piece of Terra's Luna strung on a strong thread. Remember what you're fighting for."
    icon = 'lore_items.dmi'
    icon_state = "moon_fragment_necklace"
	item_state = "moon_fragment_necklace"

/obj/structure/fluff/bureaucratic_papers
	name = "bureaucratic papers"
	desc = "Papers that drone on and on about Nanotrasen company policy and bureaucratic process.mutable_appearance"
	icon = 'icons/obj/stationobjs.dmi'
	iconstate = "paperstack"

/obj/item/toy/torch_effigy
	name = "effigy of the torch"
	desc = "An effigy of the Torch, the religion icon amidst the Dominion of Light"
	icon = 'lore_items.dmi'
	icon_state = "torch_effigy"
	item_state = "torch_effigy"

/obj/item/toy/crystal_shard
	name = "crystal shard"
	desc = "A crystal shard from the Dominion of Light's homeworld, it has a strange texture to it"
	icon = 'lore_items.dmi'
	icon_state = "crystal_shard"
	item_state = "crystal_shard"

/obj/item/toy/old_record
	name = "old record"
	desc = "An ancient vinyl record from long long ago. It has an old label that reads -ng-s fr-m -he Stars. It's a shame there isn't anything to play it on anymore"
	icon = 'lore_items.dmi'
	icon_state = "old_record"
	item_state = "old_record"

//Disabled for now until Bee-Base -DOM

//Ask about digitigrade restrictions
//obj/item/clothing/shoes/spent_shell_anklet
//	name = "spent shell anklet"
//	desc = "An anklet decorated with spent bullet casings. Maybe they were shot at something important."
//  icon = 'lore_items.dmi'
//	icon_state = "shell_anklet"
//	item_state = "shell_anklet"
