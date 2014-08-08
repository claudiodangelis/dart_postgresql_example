import 'dart:html';

void main() {

  HttpRequest.getString("/getRecords").then((String json) {
    print(json);
  });

  FormElement myForm = querySelector('form#myForm');
  myForm.onSubmit.listen((e) {
    e.preventDefault();

    FormData data = new FormData(myForm);

    HttpRequest.request(myForm.action, method: 'POST', sendData: data)
      .then((resp) {
      print(resp);
    });

  });
}
