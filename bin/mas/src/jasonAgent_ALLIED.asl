debug(9).
// 4 -> Position and distances
// 5 -> Captain assignment
// 6 -> Follow the leader
// 7 -> Aiming and enemy sighting
// 8 -> Deploying help
// 9 -> Looking my back
// 10 -> I have the flag and standing avoided

// Name of the manager
manager("Manager").

// Team of troop.
team("ALLIED").
// Type of troop.
type("CLASS_SOLDIER").





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
<-  ?debug(Mode); ?role(R); if (Mode<=2 & R==2) { .println("Looking for agents to aim."); }
?fovObjects(FOVObjects);
.length(FOVObjects, Length);

?debug(Mode); if (Mode==2 & R==2) { .println("El numero de objetos es:", Length); }

if (Length > 0) {
    +bucle(0);

    -+aimed("false");

    while (aimed("false") & bucle(X) & (X < Length)) {

        //.println("En el bucle, y X vale:", X);

        .nth(X, FOVObjects, Object);
        // Object structure
        // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
        .nth(2, Object, Type);

        ?debug(Mode); if (Mode==2 & R==2) { .println("Objeto Analizado: ", Object); }

        if (Type > 1000) {
            ?debug(Mode); if (Mode==2 & R==2) { .println("I found some object."); }
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
	                -+engaging(1);

//                // Time initialization for aiming process
//				if(not aiming_time) {
//					.time_in_millis(AimingTime);
//					+initial_aiming_time(AimingTime);
//					+aiming_time;
//				}
//
//				// Ask for the differential time
//				.time_in_millis(CurrentAimingTime);
//				?initial_aiming_time(FirstAimingTime);
//				if (CurrentAimingTime - FirstAimingTime > 2000){
//					.my_team("ALLIED", MyAttackTeam);
//					.send_msg_with_conversation_id(MyAttackTeam, tell, Enemy, "Enemy");
//					if (Mode==6){.println("I sent: ", Enemy, " to: ", MyAttackTeam);}
//				}
				}
            } else{-+engaging(0);}

        }

        -+bucle(X+1);

    }


}

-bucle(_).

+enemy_in_sight(Object)[source(A)]
	<-debug(Mode);
	+aimed_agent(Object);
    -+engaging(1);
    .nth(6, Object, EnemyPos);
    !add_task(task("TASK_GOTO_POSITION", A, EnemyPos, ""));
	update_destination(EnemyPos);
	if(Mode==6){.println("Aiming enemy at: ", EnemyPos);}.

/////////////////////////////////
//  LOOK RESPONSE
/////////////////////////////////
+look_response(FOVObjects)[source(M)]
    <-  //-waiting_look_response;
        .length(FOVObjects, Length);
        if (Length > 0) {
            ?debug(Mode); if (Mode<=1) { .println("HAY ", Length, " OBJETOS A MI ALREDEDOR:\n", FOVObjects); }
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
        ?debug(Mode); if (Mode==6) { .println("AimedAgent ", AimedAgent); }
        .nth(1, AimedAgent, AimedAgentTeam);
        ?debug(Mode); if (Mode==6) { .println("BAJO EL PUNTO DE MIRA TENGO A ALGUIEN DEL EQUIPO ", AimedAgentTeam);}
        ?my_formattedTeam(MyTeam);


        if (AimedAgentTeam == 200) {

                .nth(6, AimedAgent, NewDestination);
                ?debug(Mode); if (Mode==6) { .println("NUEVO DESTINO DEBERIA SER: ", NewDestination); }

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

    if (Mode==4) {
	// Print the position of the agent and its distance to objective
	?my_position(X, Y, Z);
	?objective(ObjectiveX, ObjectiveY, ObjectiveZ);
	.println("My position is: X = ", math.round(X), " Y = ", Y, " Z = ", math.round(Z));
	DistanceXf = X-ObjectiveX;
	DistanceZf = Z-ObjectiveZ;
	.println("My distance to flag is: ", math.round(math.sqrt(DistanceXf*DistanceXf + DistanceZf*DistanceZf)));
	?first_position(Xi,Zi);
	DistanceXb = X-Xi;
	DistanceZb = Z-Zi;
	.println("Distance to base is: ", math.round(math.sqrt(DistanceXb*DistanceXb + DistanceZb*DistanceZb)));
	}

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

	// Check the captain assignment. If not assigned, try again
	?captain_assigned(Cap);
	if(Cap == 0){
		// Time initialization
		if(not running_time) {
			.time_in_millis(Time);
			+initial_time(Time);
			+running_time;
		}

		// Ask for the differential time
		.time_in_millis(CurrentTime);
		?initial_time(FirstTime);
		if (CurrentTime - FirstTime > 800){
			-+initial_time(CurrentTime);
			// Role in the team
		   	-+role(0);
			// Captain assignment
			?assigned_id(AssignedID);
			.my_team("backup_ALLIED",Bks);
			.concat("assign_captain(", AssignedID, ")", MyID);
			.send_msg_with_conversation_id(Bks, tell, MyID, "AC");
			if (Mode==5){.println("I sent: ", MyID, " to: ", Bks);}
		}else{if (Mode==5){.println("Waiting");}}
	}
	// Captain assigned
	else{
		// Once the flag has been taken, go to protect the soldier
		if(iHaveIt(true)){
			if(Mode==10){.println("I HAVE THE FLAG! ");}
			?my_position(X,Y,Z);
			.my_team("ALLIED", AW);
			.concat("goProtectTheFlag(",X, ", ", Y, ", ", Z, ")", ProtFlag);
			.send_msg_with_conversation_id(AW, tell, ProtFlag, "INT");
			if(Mode==10){.println("Come and protect the flag! My position:", X, Y, Z);}
		}

		?role(R);
//		// Actions for soldier 0
//		if(R == 0){
//
//		}
//		// Actions for soldier 1
//		if(R == 1){
//
//		}
		// Actions for captain
		if(R == 2){
			?engaging(Engage);
			?flag_taken(FlagTkn);
			if(Engage == 0 & FlagTkn == false){
				// Add condition to keep forming while not an enemy has been seen

				if(not grouping_time) {
					.time_in_millis(GroupingTime);
					+initial_grouping_time(GroupingTime);
					+grouping_time;
				}
				// Send the position of the captain to be followed
				.time_in_millis(CurrentGroupingTime);
				?initial_grouping_time(FirstGroupingTime);
				if (CurrentGroupingTime - FirstGroupingTime > 5000){
					-+initial_grouping_time(CurrentGroupingTime);
					?my_position(X, Y, Z);
					?begin_position(Xf,Zf);
					if(X > (Xf-5) & not ready_to_form){
						+ready_to_form;
						.my_team("ALLIED", MyTeam);
						.concat("around_me(", X, ",", Y, ",",Z , ")", Mypos);
						.send_msg_with_conversation_id(MyTeam, tell, Mypos, "F");
						if (Mode==6){.println("I sent: ", Mypos, " to: ", MyTeam, " for the first time");}
					}
					if(ready_to_form){
						.my_team("ALLIED", MyTeam);
						.concat("around_me(", X, ",", Y, ",",Z , ")", Mypos);
						.send_msg_with_conversation_id(MyTeam, tell, Mypos, "F");
						if (Mode==6){.println("I sent: ", Mypos, " to: ", MyTeam, " after being ready");}
					}
				}
			}
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
	if(Mode==8){.println("Being attacked");}
	?deploy(D);
	-+deploy(D+1);
	.my_team("medic_ALLIED",MT);
	.concat("deploy_help(", D, ")", Dh);
	.send_msg_with_conversation_id(MT, tell, Dh, "DH");
	if (Mode==8){.println("I sent: ", Dh, " to: ", MT);}
	if (D == 1){-+deploy(0)};

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
        +task_priority("TASK_GIVE_BACKUP", 1000);
        +task_priority("TASK_GET_OBJECTIVE",1000);
        +task_priority("TASK_ATTACK", 1000);
        +task_priority("TASK_RUN_AWAY", 1500);
        +task_priority("TASK_GOTO_POSITION", 1750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 1500).



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
		if (R == 1){
			.println("I AM THE CAPTAIN");
			.my_team("ALLIED", MyTeam);
			.concat("brace_yourself(", 1, ")", By);
			.send_msg_with_conversation_id(MyTeam, tell, By, "B");
			-+captain_assigned(1);
			?begin_position(Xf,Zf);
			!add_task(task("TASK_GOTO_POSITION", M, pos(Xf,0,Zf), ""));
			.println("Moving to ",Xf, " - ", Zf);
		}
		if (Mode==5){.println("I am the captain of: ", A, " Role: ", R+1);}
	} else {if (Mode==5){.println("I am not the captain, but: ", A);}}
	-assign_captain(_)[source(_)];.

+brace_yourself(Assigned)[source(A)]
	<-?debug(Mode);
	-+captain_assigned(Assigned);
	?role(R);
	if(Mode==5){.println("Oh captain my captain Role: ", R);}
	-brace_yourself(_)[source(_)].

// Plan to position around captain
+around_me(X,Y,Z)[source(M)]
	<- ?debug(Mode);
	?engaging(Engage);
	if (Engage == 0){
		if(Mode==6){.println("Positioning around: ", M);}
		?role(R);
		if (R == 0){OfSx=-4;OfSz=4;} if (R == 1){OfSx=-4;OfSz=-4;}
			!add_task(task("TASK_GOTO_POSITION", M, pos(X+OfSx,Y,Z+OfSz), ""));
			update_destination(pos(X+OfSx,Y,Z+OfSz));
	} else{if(Mode==6){.println("Refusing formation");}}
	-around_me(_)[source(_)];.

+objectivePackTaken(on)
	<- ?debug(Mode); if (Mode<=3) { .println("I HAVE THE FLAG!"); };
		-+iHaveIt(true);
		?my_position(X,Y,Z);
		.my_team("ALLIED", E1);
		.concat("goProtectTheFlag(",X, ", ", Y, ", ", Z, ")", Content1);
		.send_msg_with_conversation_id(E1, tell, Content1, "INT");
		?role(R);
		if (R == 2){+flag_taken(true);}.

+goProtectTheFlag(X,Y,Z)[source(A)]
		// Plan to position around the flag
	<- ?debug(Mode); if(Mode<=4){.println("Protecting the flag");}
		!add_task(task("TASK_GOTO_POSITION", M, pos(X,Y,Z), ""));
		update_destination(pos(X,Y,Z));
		-goProtectTheFlag(_)[source(_)];.


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
   	if (Mode==4) {.println("Initial allied position: X = ",math.round(Xi)," Y = ",math.round(Yi)," Z = ",math.round(Zi));}
   	// Role in the team
   	+role(0);
   	// Captain assigned flag
   	+captain_assigned(0);
   	// Position to do the group
   	+begin_position(140,240);
   	// Position done
   	+position_done(0);
   	// Engaging mode
   	+engaging(0);
   	// Turn to deploy medic packs
   	+deploy(0);
   	// Injuries counter
   	+injuries(0);
   	// Past position to look your back
   	+past_pos(0,0,0);
   	// Flag has been taken
   	+flag_taken(false);
   	// I have the flag
   	+iHaveIt(false);
   	// Aimed init
   	+aimed("false");
	.



// ?my_team, buscar el arreglo y si tiene tres entradas de soldado, mandar mensaje y nombrarse capitán.
// Validate if the random position is in the map.
// Get_aim generation of a new random position (check postiion) assign the new dest using set position
// patrol around the whole grid

// To follow, send a message to the partner to follow him

//Taken flag function to send message

// JSON book p 175-6

// Refusing formation for all the soldiers

