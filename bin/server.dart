import 'dart:io';
import 'package:postgresql/postgresql.dart';
import 'package:mime/mime.dart';
import 'package:http_server/http_server.dart';

main() {

  Connection conn;
  connect('postgresql://utente:@localhost:5432/miodb').then((Connection _conn) {
    conn = _conn;
    print("Connesso al server postgresql");
  }, onError: (err) {
    print("Impossibile connettersi al server postgresql");
  });

  HttpServer.bind('0.0.0.0', 4040).then((HttpServer server) {
    server.listen((HttpRequest req) {
      String path = req.uri.path == '/' ? '/index.html' : req.uri.path;
      File file = new File('../web/$path');

      if (file.existsSync()) {
        file.openRead().pipe(req.response);
      } else {

        switch (path) {
          case "/send":
            // invia
            String boundary = req.headers.contentType.parameters["boundary"];
            req.transform(new MimeMultipartTransformer(boundary))
              .listen((multipart) {

              HttpMultipartFormData.parse(multipart).forEach((value) {
                if (HttpMultipartFormData.parse(multipart)
                    .contentDisposition.parameters["name"] == "to-do-input") {

                  print(value);
                  // TODO
                }
              });
            });
            break;

          case "/getRecords":
            if (conn != null) {
              conn.query('select task from tasklist').toList().then((list) {
                print(list);
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

void insert(Map<String, String> data) {
  print(data);
}
void get() {}
