// Importo la libreria html che contiene definizioni x gestione DOM e richieste
// HTTP lato server
import 'dart:html';

// Importo dart:convert e mostro solo la class JSON che ci servirà x manipolare
// i dati che tornano dal server
import 'dart:convert' show JSON;

// Dichiariamo questo elemento come elemento top-level così da poter essere
// utilizzato da ogni funzione dell'app
UListElement ul;

void main() {

  // Selezioniamo l'elemento <ul>
  ul = querySelector('#to-do-list');

  // Inoltriamo la richiesta al server per ottenere i campi presenti nella tabella.
  // Il percorso "/getRecords" in realtà non esiste, ma il server sa che se
  // riceve la richiesta x quel percorso allora si comporterà in un certo modo,
  // ovvero recuperare i dati presenti nella tabella e restituirli al client.
  HttpRequest.getString("/getRecords").then((String resp) {

    // Quando la richiesta è completa, ovvero quando il server manda il suo
    // responso, allora invochiamo la funzione aggiorna().
    // Utilizziamo il metodo then() perché .getString() è un Future

    // Il metodo JSON.decode() prende una stringa JSON e la converte in un oggetto
    // Map, siccome la struttura del JSON che ci viene restituito dal server è
    //
    //    {
    //      "task": [
    //        "valore1", "valore2", "valore3"
    //      ]
    //    }
    //
    // allora alla funzione aggiorna gli passiamo solo il valore della chiave "task"
    aggiorna(JSON.decode(resp)["task"]);
  });

  // Selezioniamo il form dal DOM
  FormElement myForm = querySelector('form#myForm');
  // Registriamo una funzione di callback x l'evento submit
  myForm.onSubmit.listen((e) {
    // Impediamo che al submit venga caricata la pagina definita come "action"
    e.preventDefault();

    // Creiamo un nuovo elemento FormData con i dati del form
    FormData data = new FormData(myForm);

    // Inviamo una richiesta al server con i dati del server.
    // Anche in questo caso la pagina definita in "myForm.action" non esiste
    // ma il server sa che se riceve una richiesta x quella pagina dovrà
    // comportarsi in un certo modo.
    HttpRequest.request(myForm.action, method: 'POST', sendData: data)
      .then((resp) {
      // La richiesta è completa
      // Resettiamo il form
      myForm.reset();
      // Invochiamo la funzione aggiorna()
      aggiorna(JSON.decode(resp.responseText)["task"]);
    });
  });
}

void aggiorna(List<String> rows) {
  // Cicla per ogni elemento di rows
  rows.forEach((row) {
    // Crea un nuovo elemento <li>...
    LIElement li = new LIElement();
    // ... gli imposta il testo
    li.text = row;
    // ... lo accoda ai nodi di <ul>
    ul.append(li);
  });
}
