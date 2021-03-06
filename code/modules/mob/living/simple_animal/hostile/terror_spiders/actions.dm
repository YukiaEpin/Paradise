// ---------- ACTIONS FOR ALL SPIDERS

/datum/action/innate/terrorspider/web
	name = "Web"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "stickyweb1"

/datum/action/innate/terrorspider/web/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/user = owner
	user.Web()

/datum/action/innate/terrorspider/wrap
	name = "Wrap"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "cocoon_large1"

/datum/action/innate/terrorspider/wrap/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/user = owner
	user.FindWrapTarget()
	user.DoWrap()

// ---------- GREEN ACTIONS

/datum/action/innate/terrorspider/greeneggs
	name = "Lay Green Eggs"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "eggs"

/datum/action/innate/terrorspider/greeneggs/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/green/user = owner
	user.DoLayGreenEggs()

// ---------- PRINCE ACTIONS

/datum/action/innate/terrorspider/princesmash
	name = "Smash Welded Vent"
	icon_icon = 'icons/atmos/vent_pump.dmi'
	button_icon_state = "map_vent"

/datum/action/innate/terrorspider/princesmash/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/prince/user = owner
	user.DoPrinceSmash()

// ---------- QUEEN ACTIONS

/datum/action/innate/terrorspider/queen/queennest
	name = "Nest"
	icon_icon = 'icons/mob/terrorspider.dmi'
	button_icon_state = "terror_queen"

/datum/action/innate/terrorspider/queen/queennest/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/queen/user = owner
	user.NestMode()

/datum/action/innate/terrorspider/queen/queensense
	name = "Hive Sense"
	icon_icon = 'icons/mob/actions.dmi'
	button_icon_state = "mindswap"

/datum/action/innate/terrorspider/queen/queensense/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/queen/user = owner
	user.DoHiveSense()

/datum/action/innate/terrorspider/queen/queeneggs
	name = "Lay Queen Eggs"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "eggs"

/datum/action/innate/terrorspider/queen/queeneggs/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/queen/user = owner
	user.LayQueenEggs()

/datum/action/innate/terrorspider/queen/queenfakelings
	name = "Fake Spiderlings"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "spiderling"

/datum/action/innate/terrorspider/queen/queenfakelings/Activate()
	var/mob/living/simple_animal/hostile/poison/terror_spider/queen/user = owner
	user.QueenFakeLings()

// ---------- WEB

/mob/living/simple_animal/hostile/poison/terror_spider/proc/Web()
	var/turf/mylocation = loc
	visible_message("<span class='notice'>[src] begins to secrete a sticky substance.</span>")
	if(do_after(src, delay_web, target = loc))
		if(loc != mylocation)
			return
		else if(istype(loc, /turf/space))
			to_chat(src, "<span class='danger'>Webs cannot be spun in space.</span>")
		else
			var/obj/effect/spider/terrorweb/T = locate() in get_turf(src)
			if(T)
				to_chat(src, "<span class='danger'>There is already a web here.</span>")
			else
				var/obj/effect/spider/terrorweb/W = new /obj/effect/spider/terrorweb(loc)
				W.creator_ckey = ckey

/obj/effect/spider/terrorweb
	name = "terror web"
	desc = "it's stringy and sticky"
	icon = 'icons/effects/effects.dmi'
	anchored = 1 // prevents people dragging it
	density = 0 // prevents it blocking all movement
	health = 20 // two welders, or one laser shot (15 for the normal spider webs)
	icon_state = "stickyweb1"
	var/creator_ckey = null

/obj/effect/spider/terrorweb/New()
	..()
	if(prob(50))
		icon_state = "stickyweb2"

/obj/effect/spider/terrorweb/proc/DeCloakNearby()
	for(var/mob/living/simple_animal/hostile/poison/terror_spider/gray/G in view(6,src))
		if(!G.ckey && G.stat != DEAD)
			G.GrayDeCloak()
			G.Aggro()

/obj/effect/spider/terrorweb/CanPass(atom/movable/mover, turf/target)
	if(istype(mover, /mob/living/simple_animal/hostile/poison/terror_spider))
		return 1
	if(istype(mover, /obj/item/projectile/terrorqueenspit))
		return 1
	if(isliving(mover))
		var/mob/living/M = mover
		if(M.lying)
			return 1
		if(prob(80))
			to_chat(mover, "<span class='danger'>You get stuck in [src] for a moment.</span>")
			M.Stun(4) // 8 seconds.
			M.Weaken(4) // 8 seconds.
			DeCloakNearby()
			if(iscarbon(mover))
				spawn(70)
					if(mover.loc == loc)
						qdel(src)
			return 1
		else
			return 0
	if(istype(mover, /obj/item/projectile))
		return prob(20)
	return ..()

/obj/effect/spider/terrorweb/bullet_act(obj/item/projectile/Proj)
	if(Proj.damage_type != BRUTE && Proj.damage_type != BURN)
		visible_message("<span class='danger'>[src] is undamaged by [Proj]!</span>")
		// Webs don't care about disablers, tasers, etc. Or toxin damage. They're organic, but not alive.
		return
	..()

// ---------- WRAP

/mob/living/simple_animal/hostile/poison/terror_spider/proc/FindWrapTarget()
	if(!cocoon_target)
		var/list/choices = list()
		for(var/mob/living/L in oview(1,src))
			if(Adjacent(L) && !L.anchored)
				if(L.stat == DEAD)
					choices += L
		for(var/obj/O in oview(1,src))
			if(Adjacent(O) && !O.anchored)
				if(!istype(O, /obj/effect/spider/terrorweb) && !istype(O, /obj/effect/spider/cocoon) && !istype(O, /obj/effect/spider/spiderling/terror_spiderling))
					choices += O
		if(choices.len)
			cocoon_target = input(src,"What do you wish to cocoon?") in null|choices
		else
			to_chat(src, "<span class='danger'>There is nothing nearby you can wrap.</span>")

/mob/living/simple_animal/hostile/poison/terror_spider/proc/DoWrap()
	if(cocoon_target && busy != SPINNING_COCOON)
		if(cocoon_target.anchored)
			cocoon_target = null
			return
		busy = SPINNING_COCOON
		visible_message("<span class='notice'>[src] begins to secrete a sticky substance around [cocoon_target].</span>")
		stop_automated_movement = 1
		walk(src,0)
		if(do_after(src, 40, target = cocoon_target.loc))
			if(busy == SPINNING_COCOON)
				if(cocoon_target && isturf(cocoon_target.loc) && get_dist(src,cocoon_target) <= 1)
					var/obj/effect/spider/cocoon/C = new(cocoon_target.loc)
					var/large_cocoon = 0
					C.pixel_x = cocoon_target.pixel_x
					C.pixel_y = cocoon_target.pixel_y
					for(var/obj/O in C.loc)
						if(istype(O, /obj/item))
							O.loc = C
						else if(istype(O, /obj/machinery) || istype(O, /obj/structure))
							O.loc = C
							large_cocoon = 1
					for(var/mob/living/L in C.loc)
						if(istype(L, /mob/living/simple_animal/hostile/poison/terror_spider))
							continue
						if(L.stat != DEAD)
							continue
						if(iscarbon(L))
							regen_points += regen_points_per_kill
							fed++
							visible_message("<span class='danger'>[src] sticks a proboscis into [L] and sucks a viscous substance out.</span>")
							to_chat(src, "<span class='notice'>You feel invigorated!</span>")
						else
							visible_message("<span class='danger'>[src] wraps [L] in a web.</span>")
						large_cocoon = 1
						last_cocoon_object = 0
						L.loc = C
						C.pixel_x = L.pixel_x
						C.pixel_y = L.pixel_y
						break
					if(large_cocoon)
						C.icon_state = pick("cocoon_large1","cocoon_large2","cocoon_large3")
		cocoon_target = null
		busy = 0
		stop_automated_movement = 0

/mob/living/simple_animal/hostile/poison/terror_spider/prince/proc/DoPrinceSmash()
	for(var/obj/machinery/atmospherics/unary/vent_pump/P in view(1,src))
		if(P.welded)
			P.welded = 0
			P.update_icon()
			visible_message("<span class='danger'>[src] smashes the welded cover off [P]!</span>")
			return
	for(var/obj/machinery/atmospherics/unary/vent_scrubber/C in view(1,src))
		if(C.welded)
			C.welded = 0
			C.update_icon()
			visible_message("<span class='danger'>[src] smashes the welded cover off [C]!</span>")
			return
	to_chat(src, "<span class='danger'>There is no unwelded vent close enough to do this.</span>")