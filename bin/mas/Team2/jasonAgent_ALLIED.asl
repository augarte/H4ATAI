debug(2).

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
*/
+!get_agent_to_aim
<-  ?debug(Mode); if (Mode<=2) { .println("Looking for agents to aim."); }
  ?fovObjects(FOVObjects);
  .length(FOVObjects, Length);
  ?debug(Mode); if (Mode<=1) { .println("Number of objects within my FOV:", Length); }

  !friend_in_sight;

  +bucle(0);

  -+aimed("false");

  while (aimed("false") & bucle(X) & (X < Length) & safeFOV("true")) {

    .nth(X, FOVObjects, Object);
    // Object structure
    // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
    .nth(2, Object, Type);

    ?debug(Mode); if (Mode<=1) { .println("Analyzed object: ", Object); }

    if (Type > 1000) {
      ?debug(Mode); if (Mode<=1) { .println("I found some object, but it's not another agent."); }
    } else {
      +aimed_agent(Object);
      -+aimed("true");
    }

    -+bucle(X+1);
  }

  -bucle(_).


/////////////////////////////////
//  OJECTIVE CARRYING BEHAVIOUR
/////////////////////////////////

+objectivePackTaken(on)
	<- ?debug(Mode); if (Mode<=3) { .println("THIS MOTHER FUCKIN AGENT HAS THE FUCKING FLAG!!!"); };
		+iHaveTheFlag(true);
    .my_name(MyName);
    !add_task(task(4000, "TASK_GOTO_POSITION", MyName, pos(StartX, StartY, StartZ), ""));
		?my_position(X,Y,Z);
		.my_team("ALLIED", E1);
		.concat("goto(",X, ", ", Y, ", ", Z, ")", Content1);
    .send_msg_with_conversation_id(E1, tell, Content1, "INT");
		.println("I just sent a message to everyone!").

+goto(X,Y,Z)[source(A)]
	<-
		.println("Received a message of the type goto from ", A).

+protectFlagCarrier(X,Y,Z)[source(A)] //called if the agent has the flag. Sends a message w/ its location so all other agents can come give help.
	<-
		.println("Received a message of the type protectFlagCarrier from ", A);
		//Add logic that has agent go protect the agent with the flag, who is currently located at X, Y, Z
		!add_task(task(1800, "TASK_GOTO_POSITION", A, pos(X, Y, Z), "")); // (OPTIONAL_PRIORITY, TASK_NAME, AGENT_WHO_TRIGGERED_TASK, POSITION, OPTIONAL_CONTENT)
		-+state(standing);
		-goto(_,_,_).


/////////////////////////////////
//  FRIENDLY FIRE BEHAVIOUR
/////////////////////////////////

+!friend_in_sight
<-  ?debug(Mode); if (Mode<=2) { .println("Checking whether there are friends within my line of sight."); }
  +safeFOV("true");
  ?fovObjects(FOVObjects);
  .length(FOVObjects, Length);

  +bucle(0);

  while (bucle(X) & (X < Length)) {
    .nth(X, FOVObjects, Object);
    // Object structure
    // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
    .nth(2, Object, Type);

  	// Object may be an enemy
  	.nth(1, Object, Team);
  	?my_formattedTeam(MyTeam);

  	if (Team == 100){
  		?debug(Mode); if (Mode<=2) { .println("There is a friend in my line of sight."); }
  		-safeFOV("true");
  	}
    -+bucle(X+1);
  }
  -bucle(_).

+!spreadOut
<-  ?debug(Mode); if (Mode<=2) { .println("Spreading out."); }
  ?my_position(X,Y,Z);
  .random(R1);
  .random(R2);
  RX = R1*2.5;
  RZ = R2*2.5;

  if(X+RX > 256){
     RX = - RX;
  }
  if(Z+RZ > 256){
     RZ = - RZ;
  }
  check_position(pos(X+RX, Y, Z+RZ));
  if(position(valid))
  {
    .println("Sending the agents to a position");
    .my_name(MyName);
  	!add_task(task(1900, "TASK_GOTO_POSITION", MyName, pos(X+RX, Y, Z+RZ), ""));
    .println("Avocado");
  }
  -position(valid).


/////////////////////////////////
//  LOOK RESPONSE
/////////////////////////////////
+look_response(FOVObjects)[source(M)]
    <-  //-waiting_look_response;
        .length(FOVObjects, Length);
        if (Length > 0) {
            ?debug(Mode); if (Mode<=1) { .println("There are  ", Length, "  objects within my line of sight:\n", FOVObjects); }
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
*/
+!perform_look_action
<- ?debug(Mode); if (Mode<=1) { .println("I'm looking at my environment."); }

  if(iHaveTheFlag(true)) {
  //if the current agent has the flag, it will send out a message to all other agents each turn with its location
    .println("I HAVE THE FLAG :)))) PLEASE PROTECT ME NOW!!");
    ?my_position(X,Y,Z);
    .my_team("ALLIED", E1);
    .concat("protectFlagCarrier(",X, ", ", Y, ", ", Z, ")", Content1);
    .send_msg_with_conversation_id(E1, tell, Content1, "INT");
    .println("I just sent a message to everyone!");
  } else {
   ?fovObjects(FOVObjects);
   .length(FOVObjects, Length);

    +bucle(0);
   	while (bucle(X) & (X < Length)) {
      .nth(X, FOVObjects, Object);
      // Object structure
      // [#, TEAM, TYPE, ANGLE, DISTANCE, HEALTH, POSITION ]
      .nth(2, Object, Type);

     	// Object may be an enemy
     	.nth(1, Object, Team);
      ?my_formattedTeam(MyTeam);

      if (Team == 100){
      	.nth(4, Object, Dist);
        .println(Dist);
      	if(Dist < 5)
      	{
      	  ?debug(Mode); if (Mode<=2) { .println("Spreading out since there team mates too close to me."); }
      		!spreadOut;
      	}
      }
      -+bucle(X+1);
    }
    -bucle(_);
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
+!perform_injury_action .
    ///<- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR PERFORM_INJURY_ACTION GOES HERE.") }.


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
        +task_priority("TASK_SPREAD_OUT", 1250);
        +task_priority("TASK_GOTO_POSITION", 750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 1750).



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
	<-	?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR UPDATE_TARGETS GOES HERE.") }.



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
   <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR init GOES HERE.")}.
