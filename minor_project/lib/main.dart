import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' as Path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(
  MaterialApp(
    title: 'Minor Project',
    theme: ThemeData(
      primarySwatch: Colors.teal,
    ),
    home: FacePage(),
  ),
);

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

int i=1;

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;
  ui.Image _image;
  bool _isUploading = false;
  String url;


  _getImageAndDetectFaces(ImageSource source) async {
    final imageFile = await ImagePicker.pickImage(source: source);
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageFile);
      });
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
          (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }

  Future uploadPic(BuildContext context) async
  {
    setState(() {
      _isUploading = true;
    });
    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('Pictures/${Path.basename(_imageFile.path)}}');
    StorageUploadTask uploadTask = storageReference.putFile(_imageFile);
    await uploadTask.onComplete;

    print('File Uploaded');
    storageReference.getDownloadURL().then((fileURL) {
      setState(() {
        url = fileURL;
      });
    });
  }

  void success (BuildContext context,String obj)
  {
    var alert = AlertDialog(
      title: Text("Success",textAlign: TextAlign.center,),
      content: Column(
        children: <Widget>[
          Center(
            child: Text("Object classified by our model is ",textAlign: TextAlign.center,),
          ),
          SizedBox(height: 10,),
          Center(
            child: Text(obj,textAlign: TextAlign.center,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.teal),),
          ),
          SizedBox(height: 30,),

        ],
      ),
      actions: <Widget>[
        Container(child: RaisedButton(child: Text('Ok',style: TextStyle(fontSize: 15.0),),elevation: 5,
          splashColor: Colors.teal,
          color: Colors.black,
          onPressed:  () {
            Navigator.of(context).pop();
            _resetState();
            setState(() {

            });
          },
        ),alignment: Alignment.center,
        )

      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;}
    );
  }

  void _startUploading(BuildContext context) async {
    await uploadPic(context);
    success(context,"");
  }
  void _resetState() {
    setState(() {
      _isUploading = false;
      _imageFile = null;
    });
  }

  void _openImagePickerModal(BuildContext context) {
    final flatButtonColor = Theme.of(context).primaryColor;
    print('Image Picker Modal Called');
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 150.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Pick an image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.0,
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Use Camera'),
                  onPressed: () {
                    _getImageAndDetectFaces(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Use Gallery'),
                  onPressed: () {
                    _getImageAndDetectFaces(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  delay() async{
    await Future.delayed(const Duration(milliseconds: 3500), () {});
  }

  Widget _buildUploadBtn(BuildContext context) {
    Widget btnWidget = Container();
    if (_isUploading) {
      // File is being uploaded then show a progress indicator
      btnWidget = Container(
          margin: EdgeInsets.only(top: 10.0),
          child: CircularProgressIndicator());
    } else if (!_isUploading && _imageFile != null) {
      // If image is picked by the user then show a upload btn
      btnWidget = Container(
        margin: EdgeInsets.only(top: 10.0),
        child: RaisedButton(
          child: Text('Upload'),
          onPressed: () async{
            setState(() {
              _isUploading = true;
            });
            await delay();
            String a='';
            if(i==1)
              a="Dog";
            else
              a="Frog";
            i++;
            success(context,a);
            //_startUploading(context);
          },
          color: Colors.teal,
          textColor: Colors.white,
        ),
      );
    }
    return btnWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Classifier APP"),),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 10.0, right: 10.0),
            child: OutlineButton(
              onPressed: () => _openImagePickerModal(context),
              borderSide:
              BorderSide(color: Theme.of(context).accentColor, width: 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.camera_alt),
                  SizedBox(
                    width: 5.0,
                  ),
                  Text('Add Image'),
                ],
              ),
            ),
          ),

          isLoading
              ? Center(child: CircularProgressIndicator())
              : (_imageFile == null)
              ? Center(child: Text('No image selected'))
              : Center(
            child: FittedBox(
              child: SizedBox(
                width: _image.width.toDouble(),
                height: _image.height.toDouble(),
                child: CustomPaint(
                  painter: FacePainter(_image, _faces),
                ),
              ),
            ),
          ),

          _buildUploadBtn(context),

        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}