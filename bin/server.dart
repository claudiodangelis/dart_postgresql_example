import 'dart:io';
import 'package:postgresql/postgresql.dart';
import 'package:mime/mime.dart';
import 'package:http_server/http_server.dart';
import 'dart:convert' show JSON;

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

                  if (conn != null) {
                    conn.execute("INSERT INTO tasklist (task) VALUES ('$value')").then((_) {

                      req.response.add(JSON.encode({"task":[value]}).codeUnits);
                      req.response.close();
                    }, onError: (_) {
                      req.response.close();
                    });
                  }

                }
              });
            });
            break;

          case "/getRecords":
            if (conn != null) {
              Map<String, List<String>> ret = {};
              ret["task"] = [];
              conn.query('select task from tasklist').toList().then((List<Row> list) {

                list.forEach((Row row) {
                  row.forEach((_, value) {
                    ret["task"].add(value);
                  });
                });
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

void insert(Map<String, String> data) {
  print(data);
}
void get() {}
