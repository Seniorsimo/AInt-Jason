// Agent Participant in project AInt-Jason.mas2j

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Plans */

+!start : .my_name(Me) <-
	.print(Me, " started.").
	
+initiator(Initiator) : .my_name(Me) <-
	.print("Contacting initiator.");
	.send(Initiator, tell, participant(Me)).

/* Query for cfp requests: accept if free, refuse otherwise */
+?cfp(Task, R)[source(Other)] : initiator(Other) & .my_name(Me) & not proposing(_) & not working(_) <-
	.print("Received cfp ", Task);
	+proposing(Task);
	R = accept(Me).
+?cfp(Task, R)[source(Other)] : initiator(Other) & .my_name(Me) & (proposing(_) | working(_)) <-
	.print("Received cfp ", Task);
	R = refuse(Me).
	
/* Execute the task */
+!task(Task)[source(Other)] : initiator(Other) & proposing(Task) <-
	.print("Received task ", Task);
	-proposing(Task);
	+working(Task);
	.wait(5000); //task take 5 sec.
	-working(Task);
	.send(Other, tell, completed(Task));
	.print("Completed task ", Task).

/* initiator refuse the proposal */
+!refuse(Task)[source(Other)] : initiator(Other) & proposing(Task) <-
	-proposing(Task).
	
	
	
