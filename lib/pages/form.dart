/*import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class AddWallDialogueScreen extends StatefulWidget {
  @override
  _AddWallDialogueScreenState createState() => _AddWallDialogueScreenState();
}

class _AddWallDialogueScreenState extends State<AddWallDialogueScreen> {
  TextEditingController _getTextTag = TextEditingController();
  File _image;
  final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
  List<ImageLabel> detectedLabels;
  final Firestore _db = Firestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isUploading = false;
  bool _isCompletedUploading = false;
  List<String> labelsInString = [];
  int likeCount = 0;
  int downloadsCount = 0;

  bool approved = false;
  @override
  void dispose() {
    labeler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Wallpaper"),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: <Widget>[
              InkWell(
                onTap: () {
                  _loadImage();
                },
                child: _image != null
                    ? Image.file(_image)
                    : Image(
                        image: AssetImage("assets/placeholder.jpg"),
                      ),
              ),
              Text("Click on Image to upload Wallpaper.."),
              SizedBox(
                height: 20,
              ),
              labelsInString != null
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        spacing: 10,
                        children: labelsInString.map((label) {
                          return ActionChip(
                            onPressed: (){
                              setState(() {
                              labelsInString.remove(label);  });
                            },
                            label: Text(label),
                            
                          );
                        }).toList(),
                      ),
                    )
                  : Container(),
              SizedBox(
                height: 20,
              ),
              
              if (_image != null) ...[
                Container(
                padding: EdgeInsets.all(20),
                  child: TextField(
                    
                    textCapitalization: TextCapitalization.sentences,
                    controller: _getTextTag,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0)
                      ),
                      hintText: 'Insert additional tags',
                      suffixIcon: IconButton(   icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                      manualTagfunc();
                      });
                    })
                    ),
                    
                  ),
                ),
                 
              ] else ...[
                Container()
              ],
              SizedBox(
                height: 10,
              ),
              if (_isUploading) ...[Text("Uploading Wallpaper...")],
              if (_isCompletedUploading) ...[Text("Uploaded")],
              SizedBox(height: 40),
              RaisedButton(
                 shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),),
                onPressed: () {
                  // if (labelsInString.contains("Flesh")) {
                  //   showDialog(
                  //       context: context,
                  //       builder: (ctx) {
                  //         return AlertDialog(
                  //           shape: RoundedRectangleBorder(
                  //               borderRadius: BorderRadius.circular(18)),
                  //           title: Text("Guidelines Error"),
                  //           content: Text(
                  //               "This Wallpaper contains explicit material. Try different Wallpaper.."),
                  //           actions: <Widget>[
                  //             FlatButton(
                  //               onPressed: () {
                  //                 Navigator.of(ctx).pop();
                  //               },
                  //               child: Text("Ok"),
                  //             ),
                  //           ],
                  //         );
                  //       });
                  // }
                  //  else {
                    manualTagfunc();
                    _uploadWallpaper();

                  
                },
                child: Text("Upload Wallpaper"),
              ),
              SizedBox(
                height: 20,
              )
            ],
          ),
        ),
      ),
    );
  }
  void _uploadedDialogue(){
    showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text("Uploaded"),
              content: Text("Wallpaper is uploaded and will be added once verified.."),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text("Ok"),
                ),
              ],
            );
          });
  }
  void _loadImage() async {
    var image = await ImagePicker().getImage(
        source: ImageSource.gallery
        , imageQuality: 70
        );

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(File(image.path));
    List<ImageLabel> labels = await labeler.processImage(visionImage);
    labelsInString = [];
    for (var l in labels) {
      labelsInString.add(l.text);
    }

    setState(() {
      _image = File(image.path);
    });
  }

  void manualTagfunc() {
    String manualTag = _getTextTag.text;
    if (manualTag.isNotEmpty) {
      labelsInString.add(manualTag);
      _getTextTag.clear();
    }
    
  }

  void _uploadWallpaper() async {
    if (_image != null) {
      String fileName = path.basename(_image.path);

      // print(fileName);
      FirebaseUser user = await _auth.currentUser();
      String uid = user.uid;
      StorageUploadTask task = _storage
          .ref()
          .child("wallpapers")
          .child(uid)
          .child(fileName)
          .putFile(_image);
      task.events.listen((event) {
        if (event.type == StorageTaskEventType.progress) {
          setState(() {
            _isUploading = true;
            // print("uploading");
          });
        }
        if (event.type == StorageTaskEventType.success) {
          setState(() {
            _isCompletedUploading = true;
            _isUploading = false;
          });

          String uploaderUidName;
          if (user.uid == "Xh2F9aV5FMdUDufzECK0RozpAf93") {
            uploaderUidName = "Admin";
            approved = true;
          } else {
            uploaderUidName = user.displayName;
            approved = false;
          }
          event.snapshot.ref.getDownloadURL().then((url) {
            _db.collection("wallpapers").add({
              "approved": approved,
              "url": url,
              "date": DateTime.now(),
              "uploaded_by": uploaderUidName,
              "uploader_uid": uid,
              "tags": labelsInString,
              "likes": likeCount,
              "downloads": downloadsCount,
            });
            _uploadedDialogue();
           // Navigator.of(context).pop();
          });
        }
      });
    } else {
      showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text("Error"),
              content: Text("Select Image to upload.."),
              actions: <Widget>[
                FlatButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text("Ok"),
                ),
              ],
            );
          });
    }
  }
}
*/


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

final GlobalKey<FormBuilderState> _fbKey = GlobalKey<FormBuilderState>();

class Forme extends StatefulWidget {
  @override
  _FormeState createState() => _FormeState();
}

class _FormeState extends State<Forme> {
  File _image;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FormBuilder(
          key: _fbKey,
          initialValue: {
            'date': DateTime.now(),
            'accept_terms': false,
          },
          autovalidate: true,
          child: Column(
            children: <Widget>[
              FormBuilderTextField(
                attribute: "name",
                decoration: InputDecoration(labelText: "Name"),
                validators: [
                  FormBuilderValidators.max(70),
                ],
              ),
              FormBuilderTextField(
                attribute: "phone",
                decoration: InputDecoration(labelText: "Phone"),
                validators: [
                  FormBuilderValidators.numeric(),
                ],
              ),
              FormBuilderTextField(
                attribute: "optional",
                decoration: InputDecoration(labelText: "Optional Phone"),
                validators: [
                  FormBuilderValidators.numeric(),
                ],
              ),
              FormBuilderTextField(
                attribute: "email",
                decoration: InputDecoration(labelText: "E-mail"),
                validators: [
                  FormBuilderValidators.max(70),
                ],
              ),
              FormBuilderTextField(
                attribute: "referral",
                decoration: InputDecoration(labelText: "Referral Number"),
                validators: [
                  FormBuilderValidators.numeric(),
                ],
              ),
              FormBuilderTextField(
                attribute: "address",
                decoration: InputDecoration(labelText: "Address"),
                validators: [
                  FormBuilderValidators.max(70),
                ],
              ),
              FormBuilderDropdown(
                attribute: "selected",
                decoration:
                    InputDecoration(labelText: "Select Mode of Payment"),
                // initialValue: 'Male',
                hint: Text('Choose one'),
                validators: [FormBuilderValidators.required()],
                items: ['UPI', 'Net Banking', 'Cash on Delivery']
                    .map((selected) => DropdownMenuItem(
                        value: selected, child: Text("$selected")))
                    .toList(),
              ),
              Text("Upload Prescription"),
              MaterialButton(
                child: Text("Upload"),
                onPressed: () {
                  _loadImage();
                },
              ),
            ],
          ),
        ),
        Row(
          children: <Widget>[
            MaterialButton(
              child: Text("Submit"),
              onPressed: () {
                _submitButton();
              },
            ),
            MaterialButton(
              child: Text("Reset"),
              onPressed: () {
                _fbKey.currentState.reset();
              },
            ),
          ],
        )
      ],
    );
  }

  void _loadImage() async {
    var image = await ImagePicker()
        .getImage(source: ImageSource.gallery, imageQuality: 70);
    setState(() {
      _image = File(image.path);
    });
  }

  void _submitButton() async {
    
    if (_fbKey.currentState.saveAndValidate()) {
      Firestore.instance
          .collection('Medical')
          .document(_fbKey.currentState.value['name'])
          .setData({
        'name': _fbKey.currentState.value['name'],
        'phone': _fbKey.currentState.value['phone'],
        'optional': _fbKey.currentState.value['optional'],
        'email': _fbKey.currentState.value['email'],
        'referral': _fbKey.currentState.value['referral'],
        'address': _fbKey.currentState.value['address'],
        'selected': _fbKey.currentState.value['selected'],
      });
    }
  }
}

/*import 'package:flutter/material.dart';  
import 'package:file_picker/file_picker.dart';


class MyApp extends StatelessWidget {  
  @override  
  Widget build(BuildContext context) {  
    final appTitle = 'Flutter Form Demo';  
    return MaterialApp(  
      title: appTitle,  
      home: Scaffold(  
        appBar: AppBar(  
          title: Text(appTitle),  
        ),  
        body: MyCustomForm(),  
      ),  
    );  
  }  
}  
// Create a Form widget.  
class MyCustomForm extends StatefulWidget {  
  @override  
  MyCustomFormState createState() {  
    return MyCustomFormState();  
  }  
}  
// Create a corresponding State class. This class holds data related to the form.  
class MyCustomFormState extends State<MyCustomForm> {  
  // Create a global key that uniquely identifies the Form widget  
  // and allows validation of the form.  
  final _formKey = GlobalKey<FormState>();  
  
  @override  
  Widget build(BuildContext context) {  
    // Build a Form widget using the _formKey created above.  
    return Form(  
      key: _formKey, 
      autovalidate: true, 
      child: ListView(    
        children: <Widget>[  
          TextFormField(  
            decoration: const InputDecoration(  
              icon: const Icon(Icons.person),  
              hintText: 'Enter your name',  
              labelText: 'Name',  
            ),
            validator: ,  
          ),  
          TextFormField(  
            decoration: const InputDecoration(  
              icon: const Icon(Icons.phone),  
              hintText: 'Enter a phone number',  
              labelText: 'Phone',  
            ), 
             
          ),  
          TextFormField(  
            decoration: const InputDecoration(  
              icon: const Icon(Icons.phone),  
              hintText: 'Enter a phone number',  
              labelText: 'Optional Phone ',  
            ),  
          ),  
          TextFormField(  
            decoration: const InputDecoration(  
            icon: const Icon(Icons.email),  
            hintText: 'Enter your Email',  
            labelText: 'E-mail',  
            ),  
           ), 
           TextFormField(  
            decoration: const InputDecoration(  
            icon: const Icon(Icons.people),  
            hintText: 'Enter your referral',  
            labelText: 'Referral Number',  
            ),  
           ),  
          /*  new Container(  
              padding: const EdgeInsets.only(left: 50.0, top: 40.0),  
              child: RaisedButton(
          onPressed: () {},
          textColor: Colors.white,
          padding: const EdgeInsets.all(0.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
                ],
              ),
            ),
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              'Choose Files',
              style: TextStyle(fontSize: 20)
            ),
          ),
        )),*/
              TextFormField(  
            decoration: const InputDecoration(  
            icon: const Icon(Icons.home),  
            hintText: 'Enter your Address',  
            labelText: 'Address',  
            ),  
           ),  
          Center(
            child: new Container(  
                padding: const EdgeInsets.only(left: 20.0, top: 40.0),  
                child: RaisedButton(
            onPressed: () {},
            textColor: Colors.black,
            padding: const EdgeInsets.all(0.0),
             child: const Text(
                'Submit',
                style: TextStyle(fontSize: 20)
              ),
        )),
          ),  
        ],  
      ),  
    );  
  }  
}  */
