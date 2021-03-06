debug(3).

// Name of the manager
manager("Manager").

// Team of troop.
team("AXIS").
// Type of troop.
type("CLASS_SOLDIER").

// Value of "closeness" to the Flag, when patrolling in defense
patrollingRadius(1).

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
  <-
  ?debug(Mode); if (Mode<=2) { .println("Looking for agents to aim."); }
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
        +found("true");
        if (Team == 100) {  // Only if I'm AXIS
          +bucle2(0);
          while (bucle2(Y) & (Y < Length) & found(Puedo) & Puedo == "true" ){
            .nth(Y, FOVObjects, Object2);
            .nth(2, Object2, Type2);
            if (Type2 < 1000){
              .nth(1, Object2, Team2);
              //.nth(3, Object, Angle1);
              //.nth(3, Object2, Angle2);
              .nth(6, Object, Pos1);
              .nth(6, Object2, Pos2);
              +posiT(Pos1);
              +posiT2(Pos2);
              if (Team2 == 200){
                //if (Angle1 == Angle2)
                //{
                //  -+found("false");
                //}
                -+posiT(Pos1);
                ?posiT(pos( A1, B1, C1));
                
                -+posiT2(Pos2);
                ?posiT2(pos( A2, B2, C2));
              
                if ( A1 == A1){
                  -+found("false");
                }
              }
            }
            -+bucle2(Y+1);
          }
          -posiT(_);
          -posiT2(_);
          ?found(Puedo);
          if (Puedo == "true") { 
            .println("Aiming an enemy. . .", MyTeam, " ", .number(MyTeam) , " ", Team, " ", .number(Team)); 
            +aimed_agent(Object);
            -+aimed("true");
          }
          -bucle2(_);
        }
        -found(_);
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
        ?debug(Mode); if (Mode<=2) { .println("BAJO EL PUNTO DE MIRA TENGO A ALGUIEN DEL EQUIPO ", AimedAgentTeam); }
        ?my_formattedTeam(MyTeam);


        if (AimedAgentTeam == 100) {
        
            .nth(6, AimedAgent, NewDestination);
            ?debug(Mode); if (Mode<=1) { .println("NUEVO DESTINO MARCADO: ", NewDestination); }
            //update_destination(NewDestination);
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
  <-
  
   		
  
    -+enemigoVisto(0);
    ?fovObjects(FOVObjects);
    .length(FOVObjects, Cuantos);
    if (Cuantos > 0){
      -+contador(0);
      while (contador(Cont) & (Cont < Cuantos) & enemigoVisto(0)){
        .nth(Cont, FOVObjects, Object);
        .nth(1, Object, Team);
        .nth(2, Object, Type);
       ?my_ammo_threshold(At);
       ?my_ammo(Ar);
        if(Team==100){
          .nth(6, Object, pos(X,Y,Z));
          -task(_, _, _, _, _);
          !add_task ( task ( 2999 , "TASK_GOTO_POSITION" , M , pos(X,Y,Z), "" ) ) ;
          .my_team("AXIS", A);
          .concat("enemigo_cerca(",X, ", ", Y, ", ", Z, ")", Content1);
          .send_msg_with_conversation_id(A, tell, Content1, "INT");
          
          -+enemigoVisto(1);
        
        }else{
        ?my_ammo_threshold(At2);
       	?my_ammo(Ar2);
        	if(At < At2 & Ar == Ar2){
        		.println("ENEMIGO ALREDEDOR !!!!!!!!!!!!");
            ?my_position(mX, mY, mZ);
        	!add_task ( task ( 2999 , "TASK_PATROLLING" , M , pos(mX, mY, mZ), "" ) ) ;
        	}else{
        		  if( war(false) ){
          	-+war(true);
          }else{
          	.my_name(M);
          	if( st(2) ){
          	if( .substring("TS1", M) ){
			!add_task ( task ( 1998 , "TASK_PATROLLING" , M , pos(45, 0, 210), "" ) ) ;
    	 	-+objective(45, 0, 200);
    		 }
    		 }
          }
        	}
        }
        -+contador(Cont+1);
      }
    }
    .
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
  /*<-?fovObjects(FOVObjects);
    .length(FOVObjects, Cuantos);
    if (Cuantos==0){
      ?my_position(X,Y,Z);
      ?current_task(task(_, _, _, pos(XT,YT,ZT), _));
      if((X-XT)>=0 & (Z-ZT)>=0){
        !add_task(task(2000, "TASK_GOTO_POSITION", A, pos(X-1, Y, Z-1), ""));
      }
      else{
        if((X-XT)<=0 & (Z-ZT)>=0){
          !add_task(task(2000, "TASK_GOTO_POSITION", A, pos(X+1, Y, Z-1), ""));
        }
        else{
          if((X-XT)>=0 & (Z-ZT)<=0){
            !add_task(task(2000, "TASK_GOTO_POSITION", A, pos(X-1, Y, Z+1), ""));
          }
          else{
            if((X-XT)<=0 & (Z-ZT)<=0){
              !add_task(task(2000, "TASK_GOTO_POSITION", A, pos(X+1, Y, Z+1), ""));
            }
          }
        }
      }
    }.*/


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
        +task_priority("TASK_GOTO_POSITION", 750);
        +task_priority("TASK_PATROLLING", 500);
        +task_priority("TASK_WALKING_PATH", 750).   



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
          
         .my_team("fieldops_AXIS", E1);
         //.println("Mi equipo intendencia: ", E1 );
         .concat("cfa(",X, ", ", Y, ", ", Z, ", ", Ar, ")", Content1);
         .send_msg_with_conversation_id(E1, tell, Content1, "CFA");
       
       
       }
       
       ?my_health_threshold(Ht);
       ?my_health(Hr);
       
       if (Hr <= Ht) {  
          ?my_position(X, Y, Z);
          
         .my_team("medic_AXIS", E2);
         //.println("Mi equipo medico: ", E2 );
         .concat("cfm(",X, ", ", Y, ", ", Z, ", ", Hr, ")", Content2);
         .send_msg_with_conversation_id(E2, tell, Content2, "CFM");

       }
       .
       
/////////////////////////////////
//  ANSWER_ACTION_CFM_OR_CFA
/////////////////////////////////
+enemigo_cerca(X,Y,Z)[source(A)]
  <-
  //?current_task(task(C_priority, _, _, _, _));
  -task(1999, _, _, _, _);
  !add_task(task(1999, "TASK_GOTO_POSITION", A, pos(X, Y, Z), "")).
  //-+state(standing);
  //-goto(_,_,_).  
   
+sigueme(SubTeam, X, Z)[source(A)]
  <-
  ?subteam(S);
  if(SubTeam==S){
    -task(1999, _, _, _, _);
    check_position(pos(X+2,0,Z-2));
      if(position(valid)){
        !add_task(task(2000, "TASK_GOTO_POSITION", A, pos(X+2, 0, Z-2), ""));
      }
      else{
        !add_task(task(2000, "TASK_GOTO_POSITION", A, pos(X, 0, Z), ""));
      }
  }.
    
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
  <- ?debug(Mode); if (Mode<=1) { .println("YOUR CODE FOR init GOES HERE.")}
  +st(1);
  +enemigoVisto(0);
  +war(false);
  .my_name(A);
  
	if( .substring("TS1", A) ){
		if( st(1) ){
	!add_task ( task ( 1999 , "TASK_PATROLLING" , A , pos(120, 0, 210), "" ) ) ;
    -+objective(120, 0, 210);
    }
     	if( st(2) ){
			!add_task ( task ( 1998 , "TASK_PATROLLING" , M , pos(45, 0, 210), "" ) ) ;
    	 	-+objective(45, 0, 200);
    		 }
    if( st(3) ){
	!add_task ( task ( 1999 , "TASK_PATROLLING" , A , pos(120, 0, 250), "" ) ) ;
    -+objective(210, 0, 250);
    }
     if( st(4) ){
	!add_task ( task ( 1999 , "TASK_PATROLLING" , A , pos(200, 0, 130), "" ) ) ;
    -+objective(200, 0, 230);
    }
    +subteam(1);
  }
  if( .substring("TS2", A) ){
  	if( st(1) ){
	!add_task ( task ( 1999 , "TASK_PATROLLING" , A , pos(120, 0, 210), "" ) ) ;
    -+objective(120, 0, 210);
    }
      	if( st(2) ){
			!add_task ( task ( 1998 , "TASK_PATROLLING" , M , pos(45, 0, 210), "" ) ) ;
    	 	-+objective(45, 0, 200);
    		 }
    if( st(3) ){
	!add_task ( task ( 1999 , "TASK_PATROLLING" , A , pos(120, 0, 250), "" ) ) ;
    -+objective(210, 0, 250);
    }
     if( st(4) ){
	!add_task ( task ( 1999 , "TASK_PATROLLING" , A , pos(200, 0, 130), "" ) ) ;
    -+objective(200, 0, 230);
    }
    +subteam(1);
  }
  if( .substring("TS3", A) ){
    -+objective(210, 0, 210);
    +subteam(2);
  }.  

