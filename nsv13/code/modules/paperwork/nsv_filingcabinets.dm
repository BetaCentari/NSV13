/obj/structure/filingcabinet/biology_reports
	name = "biology report cabinet"
	desc = "A large cabinet with drawers containing information on each of the species biology and ecology."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "filingcabinet"
	density = TRUE
	anchored = TRUE

/obj/structure/filingcabinet/biology_reports/Initialize()
	. = ..()
	new /obj/item/paper/fluff/biology_report/plasmamen(src)
	new /obj/item/paper/fluff/biology_report/ethereal(src)
	new /obj/item/paper/fluff/biology_report/mothpeople(src)
	new /obj/item/paper/fluff/biology_report/lizardfolk(src)
	new /obj/item/paper/fluff/biology_report/felinid(src)
	new /obj/item/paper/fluff/biology_report/ipc(src)
	new /obj/item/paper/fluff/biology_report/human(src)
	update_icon()

