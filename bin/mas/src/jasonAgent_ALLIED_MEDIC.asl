debug(11).

// Name of the manager
manager("Manager").

// Team of troop.
team("ALLIED").
// Type of troop.
type("CLASS_MEDIC").




{ include("jgomas.asl") }




// Plans


/*******************************
*
* Actions definitions
*
*******************************/

/////////////////////////////////
//  GET AGENT TO AIM
/////////////////////////////////
/**
 * Calculates if there is an enemy at sight.
 *
 * This plan scans the list <tt> m_FOVObjects</tt> (objects in the Field
 * Of View of the agent) looking for an enemy. If an enemy agent is found, a
 * value of aimed("true") is returned. Note that there is no criterion (proximity, etc.) for the
 * enemy found. Otherwise, the return value is aimed("false")
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!get_agent_to_aim
<-  ?debug(Mode); if (Mode<=2) { .println("Looking for agents to aim."); }
?fovObjects(FOVObjects);
.length(FOVObjects, Length);

?debug(Mode); if (Mode<=1) { .println("El numero de objetos es:", Length); }

if (Length > 0) {
    +bucle(0);

    -+aimed("false");

    while (aimed("false") & bucle(X) & (X < Length)) {

        //.println("En el bucle, y X vale:", X);

        .nth(X, FOVObjects, Object);
        // Object structure
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        .nth(2, Object, Type);

        ?debug(Mode); if (Mode<=2) { .println("Objeto Analizado: ", Object); }

        if (Type > 1000) {
            ?debug(Mode); if (Mode<=2) { .println("I found some object."); }
        } else {
            // Object may be an enemy
            .nth(1, Object, Team);
            ?my_formattedTeam(MyTeam);

            if (Team == 200) {  // Only if I'm ALLIED

                //Now ensure that there aren't any agents of the same team in front of the enemy

				.nth(4, Object, Distance);	//get the distance between the agent and the targeted enemy

				+safeToFire("true");
				+innerLoop(0);
				while (safeToFire("true") & innerLoop(Y) & (Y < Length)) {//while safeToFire is still true, iterate using innerLoop through all the objects in FOV (# = Length)
					.nth(Y, FOVObjects, TestObject); //assign Object to be the Yth object in FOVObjects
					.nth(2, TestObject, TestObjectType);
					.nth(1, TestObject, TestObjectTeam);
					.nth(3, TestObject, TestObjectAngle);
					.nth(4, TestObject, TestObjectDistance);

					if(TestObjectType < 1000){
						if(TestObjectTeam == 100){	//if the object is an alled agent (on the same team)
							if(TestObjectDistance <= Distance){//if a team mate is closer than the targeted enemy, don't fire
							-+safeToFire("false");
							?debug(Mode); if (Mode<=2) {.println("FRIENDLY FIRE AVOIDED");}
							//have the agent move to a position where it can fire safely

							}
						}
					}
					-+innerLoop(Y+1);
				}

				if(safeToFire("true")){
				 ?debug(Mode); if (Mode<=2) { .println("Aiming an enemy. . .", MyTeam, " ", .number(MyTeam) , " ", Team, " ", .number(Team)); }
	                +aimed_agent(Object);
	                -+aimed("true");	//in these two beliefs, the agent immediately changes direction, shoots at the agent, and then returns to previous direction
				}

            }

        }

        -+bucle(X+1);

    }


}

-bucle(_).

/////////////////////////////////
//  LOOK RESPONSE
/////////////////////////////////
+look_response(FOVObjects)[source(M)]
    <-  //-waiting_look_response;
        .length(FOVObjects, Length);
        if (Length > 0) {
            ///?debug(Mode); if (Mode<=1) { .println("HAY ", Length, " OBJETOS A MI ALREDEDOR:\n", FOVObjects); }
        };
        -look_response(_)[source(M)];
        -+fovObjects(FOVObjects);
        //.//;
        !look.


/////////////////////////////////
//  PERFORM ACTIONS
/////////////////////////////////
/**
* Action to do when agent has an enemy at sight.
*
* This plan is called when agent has looked and has found an enemy,
* calculating (in agreement to the enemy position) the new direction where
* is aiming.
*
*  It's very useful to overload this plan.
*
*/
+!perform_aim_action
    <-  // Aimed agents have the following format:
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        ?aimed_agent(AimedAgent);
        ?debug(Mode); if (Mode<=1) { .println("AimedAgent ", AimedAgent); }
        .nth(1, AimedAgent, AimedAgentTeam);
        ?debug(Mode); if (Mode<=2) { .println("BAJO EL PUNTO DE MIRA TENGO A ALGUIEN DEL EQUIPO ", AimedAgentTeam);             }
        ?my_formattedTeam(MyTeam);


        if (AimedAgentTeam == 200) {

                .nth(6, AimedAgent, NewDestination);
                ?debug(Mode); if (Mode<=1) { .println("NUEVO DESTINO DEBERIA SER: ", NewDestination); }

            }
 .

/**
* Action to do when the agent is looking at.
*
* This plan is called just after Look method has ended.
*
* <em> It's very useful to overload this plan. </em>
*
*/
+!perform_look_action
   	<- ?debug(Mode);

   	// Avoid the standing task
	if(not standing_time) {
		.time_in_millis(StandTime);
		+initial_standing_time(StandTime);
		?my_position(X,Y,Z);
		+standing_pos(X,Z);
		+standing_time;
	}
	.time_in_millis(CurrentStandTime);
	?initial_standing_time(FirstStandTime);
	if (CurrentStandTime - FirstStandTime > 5000){
		-+initial_standing_time(CurrentStandTime);
		?my_position(X,Y,Z);
		?standing_pos(Xlast,Zlast);
		if (X == Xlast & Z == Zlast){
			?objective(Xob, Yob, Zob);
			!add_task(task("TASK_GET_OBJECTIVE", M, pos(Xob, Yob, Zob), ""));
			if(Mode==10){.println("I used to be stucked, but now I am free!");}
		}
		-+standing_pos(X,Z);
	}

	// Time initialization
	if(not running_time) {
		.time_in_millis(Time);
		+initial_time(Time);
		+running_time;
	}

	// Check the captain assignment. If not assigned, try again
	?captain_assigned(Cap);
	if(Cap == 0){
		// Ask for the differential time
		.time_in_millis(CurrentTime);
		?initial_time(FirstTime);
		if (CurrentTime - FirstTime > 500 & not sent){
			-+initial_time(CurrentTime);
			+sent;
			// Captain assignment
			?assigned_id(AssignedID);
			.my_team("medic_ALLIED",Ms);
			.concat("assign_captain(", AssignedID, ")", MyID);
			.send_msg_with_conversation_id(Ms, tell, MyID, "AC");
			if (Mode==5){.println("I sent: ", MyID, " to: ", Ms);}
		}
	}
	// Captain assigned
	else{
		// Once the flag has been taken, go to protect the soldier
		if(iHaveIt(true)){
			.println("I HAVE THE FLAG! ");
			?my_position(X,Y,Z);
			.my_team("ALLIED", AW);
			.concat("goProtectTheFlag(",X, ", ", Y, ", ", Z, ")", ProtFlag);
			.send_msg_with_conversation_id(AW, tell, ProtFlag, "INT");
			.println("Come and protect the flag! My position:", X, Y, Z);
		}
	}.


/**
* Action to do if this agent cannot shoot.
*
* This plan is called when the agent try to shoot, but has no ammo. The
* agent will spit enemies out. :-)
*
* <em> It's very useful to overload this plan. </em>
*
*/
+!perform_no_ammo_action .
   /// <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_NO_AMMO_ACTION GOES HERE.") }.

/**
     * Action to do when an agent is being shot.
     *
     * This plan is called every time this agent receives a messager from
     * agent Manager informing it is being shot.
     *
     * <em> It's very useful to overload this plan. </em>
     *
     */
+!perform_injury_action
	<-?debug(Mode);
	// Look back if an injury is made while I don't have the flag
	?aimed(Aim);
	?iHaveIt(Flag);
	if (Flag == false){
		if (Aim == "false"){
			if(Mode==9){.println("Shooter behind");}
			?injuries(Inj);
			-+injuries(Inj+1);
			if (Inj == 0){
				?my_position(Xp, Yp, Zp);
				-+past_pos(Xp, Yp, Zp);
			} else{
				-+injuries(0);
				?past_pos(Xp, Yp, Zp);
				!add_task(task("TASK_GOTO_POSITION", M, pos(Xp, Yp, Zp), ""));
				update_destination(pos(Xp, Yp, Zp));
				if (Mode==9){.println("Looking my back");}
			}
		}else{if(Mode==9){.println("Shooter in front");}}
	}.


/////////////////////////////////
//  SETUP PRIORITIES
/////////////////////////////////
/**  You can change initial priorities if you want to change the behaviour of each agent  **/
+!setup_priorities
    <-  +task_priority("TASK_NONE",0);
        +task_priority("TASK_GIVE_MEDICPAKS", 2000);
        +task_priority("TASK_GIVE_AMMOPAKS", 0);
        +task_priority("TASK_GIVE_BACKUP", 0);
        +task_priority("TASK_GET_OBJECTIVE",1000);
        +task_priority("TASK_ATTACK", 1000);
        +task_priority("TASK_RUN_AWAY", 1500);
        +task_priority("TASK_GOTO_POSITION", 1750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 1700).



/////////////////////////////////
//  UPDATE TARGETS
/////////////////////////////////
/**
 * Action to do when an agent is thinking about what to do.
 *
 * This plan is called at the beginning of the state "standing"
 * The user can add or eliminate targets adding or removing tasks or changing priorities
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!update_targets
	<-	?debug(Mode);
	?objective(Xob, Yob, Zob);
	!add_task(task("TASK_GET_OBJECTIVE", M, pos(Xob, Yob, Zob), ""));
	if (Mode<=1) { .println("YOUR CODE FOR UPDATE_TARGETS GOES HERE.") }.

// ID's comparison to assign captain
+assign_captain(ID)[source(A)]
	<-?debug(Mode);
	?assigned_id(AssignedID);
	if (AssignedID > ID){
		?role(R);
		-+role(R+1);
		if (Mode==5){.println("I am the captain of: ", A, " Role: ", R+1);}
	} else {
		if (Mode==5){.println("I am not the captain, but: ", A);}
	}
	-assign_captain(_)[source(_)];.

+brace_yourself(Assigned)[source(A)]
	<-?debug(Mode);
	-+captain_assigned(Assigned);
	?role(R);
	if(Mode==5){.println("Oh captain my captain Role: ", R);}
	-brace_yourself(_)[source(_)].

// Plan to position around captain
+around_me(X,Y,Z)[source(M)]
	<- ?debug(Mode); if(Mode<=6){.println("Positioning around: ", M);}
	?role(R);
	if (R == 0){OfSx=-4;OfSz=0;} if (R == 1){OfSx=-8;OfSz=0;}
		!add_task(task("TASK_GOTO_POSITION", M, pos(X+OfSx,Y,Z+OfSz), ""));
		update_destination(pos(X+OfSx,Y,Z+OfSz));
	-around_me(_)[source(_)];.

+objectivePackTaken(on)
	<- ?debug(Mode); if (Mode<=3) { .println("I HAVE THE FLAG!"); };
		-+iHaveIt(true);
		?my_position(X,Y,Z);
		.my_team("ALLIED", E1);
		.concat("goProtectTheFlag(",X, ", ", Y, ", ", Z, ")", Content1);
		.send_msg_with_conversation_id(E1, tell, Content1, "INT");.

+goProtectTheFlag(X,Y,Z)[source(A)]
		// Plan to position around the flag
	<- ?debug(Mode); if(Mode<=4){.println("Protecting the flag");}
		!add_task(task("TASK_GOTO_POSITION", M, pos(X,Y,Z), ""));
		update_destination(pos(X,Y,Z));
		-goProtectTheFlag(_)[source(_)];.

+deploy_help(D)[source(A)]
	<-?debug(Mode);
	?role(R);
	if (R == D){
		if(not medic_first_time) {
			.time_in_millis(MedicTime);
			+initial_medic_time(MedicTime);
			+medic_first_time;
		}
		.time_in_millis(CurrentMedicTime);
		?initial_medic_time(FirstMedicTime);
		if (CurrentMedicTime - FirstMedicTime > 2000){
			-+initial_medic_time(CurrentMedicTime);
			if (Mode == 8){.println("Deploying medic pack: ", R);}
			create_medic_pack;
		}
	}.


/////////////////////////////////
//  CHECK MEDIC ACTION (ONLY MEDICS)
/////////////////////////////////
/**
 * Action to do when a medic agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
 +!checkMedicAction
     <-  -+medicAction(on).
      // go to help


/////////////////////////////////
//  CHECK FIELDOPS ACTION (ONLY FIELDOPS)
/////////////////////////////////
/**
 * Action to do when a fieldops agent is thinking about what to do if other agent needs help.
 *
 * By default always go to help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
 +!checkAmmoAction
     <-  -+fieldopsAction(on).
      //  go to help



/////////////////////////////////
//  PERFORM_TRESHOLD_ACTION
/////////////////////////////////
/**
 * Action to do when an agent has a problem with its ammo or health.
 *
 * By default always calls for help
 *
 * <em> It's very useful to overload this plan. </em>
 *
 */
+!performThresholdAction
       <-

       ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_TRESHOLD_ACTION GOES HERE.") }

       ?my_ammo_threshold(At);
       ?my_ammo(Ar);

       if (Ar <= At) {
          ?my_position(X, Y, Z);

         .my_team("fieldops_ALLIED", E1);
         //.println("Mi equipo intendencia: ", E1 );
         .concat("cfa(",X, ", ", Y, ", ", Z, ", ", Ar, ")", Content1);
         .send_msg_with_conversation_id(E1, tell, Content1, "CFA");


       }

       ?my_health_threshold(Ht);
       ?my_health(Hr);

       if (Hr <= Ht) {
          ?my_position(X, Y, Z);

         .my_team("medic_ALLIED", E2);
         //.println("Mi equipo medico: ", E2 );
         .concat("cfm(",X, ", ", Y, ", ", Z, ", ", Hr, ")", Content2);
         .send_msg_with_conversation_id(E2, tell, Content2, "CFM");

       }
       .

/////////////////////////////////
//  ANSWER_ACTION_CFM_OR_CFA
/////////////////////////////////



+cfm_agree[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfm_agree GOES HERE.")};
      -cfm_agree.

+cfa_agree[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfa_agree GOES HERE.")};
      -cfa_agree.

+cfm_refuse[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfm_refuse GOES HERE.")};
      -cfm_refuse.

+cfa_refuse[source(M)]
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR cfa_refuse GOES HERE.")};
      -cfa_refuse.


/////////////////////////////////
//  Initialize variables
/////////////////////////////////

+!init
   <- ?debug(Mode);

   	?my_position(Xi, Yi, Zi);
   	+first_position(Xi,Zi);
   	// Role in the team
   	+role(0);
   	// Captain assigned flag
   	+captain_assigned(0);
   	+arrived(0);
   	+iHaveIt(false);
   	// Aimed init
   	+aimed("false");

   	if (Mode==4) {.println("Initial allied position: X = ",math.round(Xi)," Y = ",math.round(Yi)," Z = ",math.round(Zi));}.
