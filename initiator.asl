// Agent Initiator in project AInt-Jason.mas2j

/* Initial beliefs and rules */

// There are 3 tasks
task(imageTask1).
task(imageTask2).
task(imageTask3).

has_task(Task) :- 
	.findall(X, (task(X) & not completed(X) & not running(X)), List)
	& not .empty(List)
	& .nth(0, List, Task).

/* Initial goals */

!start.

/* Plans */

+!start : .my_name(Me) <-
	.print(Me, " started.");
	.broadcast(tell, initiator(Me));
	!executeTasks.
		
+!executeTasks : has_task(T) <-
	!task(T);
	?executeTasks.

/* Se non ci sono più task da eseguire, mi fermo, in caso contrario ripeto */
-!executeTasks : not has_task(T) <- .print("No more task to execute").
-!executeTasks : true <- !executeTasks.

/* Tenta di eseguire Task */
+!task(Task) : true <-
	+running(Task);
	.print("Executing task ",Task);
	?available(Task, Partecipant);			// Recupera un Partecipant
	if (.literal(Partecipant)) {
		//.print("Available: ", Partecipant);
		!send_task(Task, Partecipant);		// Gli invia Task
	} else {
		.print("No free partecipant");
		-running(Task);
	}.
	
/* Invia Task a Partecipant */
+!send_task(Task, Partecipant) <-
	.print("Sending task ", Task, " to ", Partecipant);
	.send(Partecipant, achieve, task(Task)).
	
/* Verifica se vi è almeno un Participant disponibile per l'esecuzione di Task.
   Se almeno un Partecipant accetta il task, il suo nome viene restituito in Partecipant */
+?available(Task, Partecipant) <-
	.findall(P, participant(P), L);							// Recupera tutti i Partecipant conosciuti
	!cfp(Task,L);											// Li contatta per le disponibilità
	.findall(X, cfp(Task, accept(X)), Part_accept);			// Recupera i Partecipant che hanno accettato
	.print("Accepted by ", Part_accept);
	.findall(Y, cfp(Task, refuse(Y)), Part_refuse);			// Recupera i Partecipant che hanno rifiutato
	.print("Refused by ", Part_refuse);
	if (not .empty(Part_accept)){
		.member(Partecipant, Part_accept);					// Estrae un Partecipant fra quelli che hanno accettato
		.difference(Part_accept, [Partecipant], Difference);// Genera una lista di chi ha accettato ma non è stato scelto
		!refuse(Task, Difference);							// Rifiuta le proposte di questi ultimi
	}
	!clean(Task).											// Ripulisce (facoltativo, vedi commento seguente)
	
/* Il goal !clean può essere rimosso nel caso in cui si voglia tenere traccia
   delle risposte dei vari partecipant relative ad ogni task.
   le goal è stato inserito per permette un'analisi della base di conoscenza,
   in fase di sviluppo e debug, molto più rapida */
	
/* Rimuove dalla base di conoscenza le informazioni raccolte da cfp */
+!clean(Task) <-
	.findall(X, cfp(Task, X), Cfps);
	//.print("Cleaning ", Cfps);
	for( .member(B, Cfps) ){
		-cfp(Task, B);
	}.

/* Rifiuta le richieste degli agenti Partecipants */
+!refuse(Task, Partecipants) <-
	.print("Refusing ", Partecipants);
	.send(Partecipants, achieve, refuse(Task)).
	
/* Effettua una richiesta per l'esecuzione di Task agli agenti Partecipants */
+!cfp(Task, Participants) <-
	.print("Sending CFP to ", Participants, " for task ", Task);
	.send(Participants, askOne, cfp(Task,_), Responses, 2000);
	for( .member(cfp(Task,B), Responses) ){
		// Attenzione: questa riga è scritta così per avere i cfp con source(self)
		+cfp(Task, B);
	}.

+completed(Task) : running(Task) <-
	.print("Task ", Task, " completed successfully.");
	-running(Task).
