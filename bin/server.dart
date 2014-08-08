// In dart:io ci sono le funzioni lato server
import 'dart:io';
// Come nel client, abbiamo bisogno della classe JSON per codificare i valori
// da restituire
import 'dart:convert' show JSON;

// A differenza delle due precedenti librerie, le seguenti non sono presenti
// nelle librerie di base.

// driver per postgresql
import 'package:postgresql/postgresql.dart';

// Funzioni per la gestione dei mimetypes
import 'package:mime/mime.dart';

// Librerie che espone funzioni ad un più alto livello di astrazione che nel
// nostro caso utilizziamo per gestire un multipart form data
import 'package:http_server/http_server.dart';

main() {

  // Prepariamo l'oggetto "Connection"
  Connection conn;

  // Proviamo a connetterci al db
  connect('postgresql://utente:@localhost:5432/miodb').then((Connection _conn) {
    // La connessione è andata a buon fine quindi valorizziamo l'oggetto
    // "Connection" che abbiamo definito all'inizio di main()
    conn = _conn;
    print("Connesso al server postgresql");
  }, onError: (err) {
    // La connessione non è andata a buon fine.
    // L'oggetto "conn" è "null"
    print("Impossibile connettersi al server postgresql");
  });

  /* Avviamo un server sulla porta 4040. L'indirizzo 0.0.0.0 indica che il server resterà
   * in ascolto su tutte le interfacce di rete della macchina.
   */
  HttpServer.bind('0.0.0.0', 4040).then((HttpServer server) {
    // Binding avviato con successo
    // Il server ora resta in ascolto delle richieste
    server.listen((HttpRequest req) {
      // Il server ha ricevuto una richiesta. Utilizziamo l'operatore
      // ternario per gestire la variabile "path": se la richiesta è "/"
      // allora il server dovrà servire il file index.html, altrimenti
      // servirà la pagina richiesta
      String path = req.uri.path == '/' ? '/index.html' : req.uri.path;

      // Creiamo l'oggetto file con il percorso completo (directory + path)
      File file = new File('../web/$path');

      // Controlliamo che il file esista.
      if (file.existsSync()) {
        // Il file esiste quindi lo apriamo in lettura e ne inoltriamo il
        // contenuto come responso della richiesta
        file.openRead().pipe(req.response);
      } else {

        /* Il file non esiste, quindi probabilmente quello che vogliamo
         * è una delle due azioni di cui abbiamo bisogno nel client, ovvero
         * l'invio di un nuovo record oppure il recupero dei record esistenti
         */
        switch (path) {
          case "/send":
            /* Se il percorso è /send allora dobbiamo ricevere i dati inviati
             * dal client, processarli ed inserirli nella tabella
             */
            String boundary = req.headers.contentType.parameters["boundary"];
            /* Qui "trasformiamo" la richiesta in modo da agevolare il lavoro
             * con il multipart/form-data
             */
            req.transform(new MimeMultipartTransformer(boundary))
              .listen((multipart) {

              /* Analizziamo il contenuto del multipart/form-data */
              HttpMultipartFormData.parse(multipart).forEach((value) {
                /* Se tra i dati inviati esiste un parametro che come "name"
                 * ha "to-do-input", allora dobbiamo utilizzare quel valore
                 */
                if (HttpMultipartFormData.parse(multipart)
                    .contentDisposition.parameters["name"] == "to-do-input") {

                  /* Controlliamo che la connessione sia stata correttamente
                   * stabilita (vedi riga 26)
                    */
                  if (conn != null) {
                    /* Eseguiamo la query, dopodiché inviamo un responso al
                     * client.
                     */
                    conn.execute("INSERT INTO tasklist (task) VALUES ('$value')").then((_) {
                      /* req.response.add() prende in ingresso una lista di bytes
                       * perciò utilizziamo il getter "codeUnits", che restituisce
                       * i bytes della stringa
                        */
                      req.response.add(JSON.encode({"task":[value]}).codeUnits);
                      /* Quando invochiamo il metodo req.response.close() il client
                       * sa che la richiesta è completa e può continuare il suo lavoro
                        */
                      req.response.close();
                    }, onError: (_) {
                      req.response.close();
                    });
                  }

                }
              });
            });
            break;

          /* La richiesta è "/getRecords". Anche in questo caso, il file non
           * esiste, ma noi predisponiamo il server in modo tale da restiruire
           * i valori presenti nella tabella
            */
          case "/getRecords":
            if (conn != null) {
              /* Prepariamo l'oggetto da restituire al client.
               * L'oggetto che stiamo preparando è una mappa, ma al momento
               * dell'invio al client lo convertiremo in stringa JSON
                */
              Map<String, List<String>> ret = {};

              /* Inizializziamo la chiave "task" con una lista vuota */
              ret["task"] = [];

              /* Inviamo la nostra query. Quando la richiesta sarà completata,
               * avremo i risultati come lista di oggetti "Row".
               * Il metodo .then() indica che query() è un Future.
                */
              conn.query('select task from tasklist').toList().then((List<Row> list) {

                // Cicla tutte le righe
                list.forEach((Row row) {
                  // Cicla fra le coppie chiave/valore di ogni riga
                  // Utilizziamo "_" (underscore) come identificatore della chiave
                  // (che nel nostro caso è "task", perché non siamo interessati
                  // a quel valore (è una convenzione di Dart)
                  row.forEach((_, value) {
                    // Aggiungiamo $value alla lista associata alla chiave "task"
                    ret["task"].add(value);
                  });
                });
                // Creiamo il responso della richiesta aggiungendo i bytes
                // della mappa ret che abbiam ocreato alla riga 121
                req.response.add(JSON.encode(ret).codeUnits);
                req.response.close();
              });
            }
            break;

          default:
            req.response.statusCode = HttpStatus.NOT_FOUND;
            req.response.close();
            break;
        }
      }
    });
  });
}
