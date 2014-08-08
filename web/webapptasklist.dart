import 'dart:html';
import 'dart:convert' show JSON;

UListElement ul;

void main() {

  ul = querySelector('#to-do-list');

  HttpRequest.getString("/getRecords").then((String resp) {
    aggiorna(JSON.decode(resp)["task"]);
  });

  FormElement myForm = querySelector('form#myForm');
  myForm.onSubmit.listen((e) {
    e.preventDefault();

    FormData data = new FormData(myForm);

    HttpRequest.request(myForm.action, method: 'POST', sendData: data)
      .then((resp) {
      myForm.reset();
      aggiorna(JSON.decode(resp.responseText)["task"]);
    });
  });
}

void aggiorna(List<String> rows) {
  rows.forEach((row) {
    LIElement li = new LIElement();
    li.text = row;
    ul.append(li);
  });
}
