import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'my_globals.dart' as globals;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamiliarFace',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        //https://www.codegrepper.com/code-examples/dart/set+width+to+elevatedbutton+flutter
      ),
      home: login(),
    );
  }
}

/* CLASSES FOR LOGIN START */
class login extends StatefulWidget {


  @override
  loginState createState() => loginState();
}

class loginState extends State<login> {
  bool _initialized = false;

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  //initializes firebase
  Future<void> initializeFlutterFire() async {
    try {
      //wait for firebase to initialize
      await Firebase.initializeApp();
    } catch(e) {
      print(e);
    }
    setState(() {
      _initialized = true;
      initCurrentUser();
    });
  }

  void initCurrentUser() {
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User user) {
      if (user != null) {
        print(user.uid);
        setState(() {
          globals.user=user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context){
    if(_initialized)
      {
        return Scaffold(
          backgroundColor: Color(0xFFE0F7FA),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Icon(
                    Icons.face_retouching_natural,
                    size: 200,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                      "Welcome to FamiliarFace, please sign in:"
                  ),
                ),
                Container(
                  width: 250.0,
                  height: 50.0,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: Color(0xFFE0F7FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                      ),
                      onPressed: () {
                        singInErrorCatcher();
                      },
                      child: Text(
                          "Sign in with Google",
                          style: TextStyle(
                            fontSize: 22,
                          )
                      )
                  ),
                ),
              ],
            ),
          ),
        );
      } else { //firebase is not initialized
      return CircularProgressIndicator(
        backgroundColor: Color(0xFFE0F7FA),
      );
    }
  }

  /* AUTHENITCATION FUNCTIONS */
  //function called before google sign in, to catch
  //any potential sign in erros
  Future<void> singInErrorCatcher() async {
    try{
      await googleSignIn();
      Navigator.push(
           context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
      );
    } catch(error) {
      print(error);
    }
  }

  //signs the user in through google
  Future<UserCredential> googleSignIn() async {  //look at firebase auth for reference
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    print(googleUser.email);
    print(googleUser.displayName);

    // Once signed in, return the UserCredential
    setState(() {
      globals.signedIn = true;
    });

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

/* CLASSES FOR LOGIN END */



/* CLASSES FOR HOME PAGE START */
class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<QueryDocumentSnapshot> allClasses = [];
  bool classesRetrieved = false;

  //handles dynamic links
  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;
          if (deepLink != null) { //THIS IF WILL CATCH THE DEEP LINK
            print(deepLink);
            addUserToClass(deepLink.toString());
          }
        },
        onError: (OnLinkErrorException e) async {
          print('onLinkError');
          print(e.message);
        }
    );
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance
        .getInitialLink(); //gets the link that opened the app, null if it was not opened by a link
    final Uri deepLink = data?.link;
  }

  Future<void> retrieveClasses() async{
    QuerySnapshot snap = await FirebaseFirestore.instance.collection(globals.user.email).get();
    //loops through all documents, appending their names to the myDocs list
    snap.docs.forEach((element) {
      allClasses.add(element);
    });
    print(allClasses.length);
    setState(() {
      classesRetrieved = true;
    });
  }

  @override
  void initState() {
    initDynamicLinks();
    retrieveClasses();
    super.initState();
  }

  @override     // This method is rerun every time setState is called, for instance as done
  Widget build(BuildContext context) {
    if(classesRetrieved)
      {
        return Scaffold(
          backgroundColor: Color(0xFFE0F7FA),
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "FamiliarFace",
              style: TextStyle(
                  fontSize: 30
              ),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                }
                ,),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Icon(
                    Icons.face_retouching_natural,
                    size: 200,
                  ),
                ),
                Container(
                  width: 250.0,
                  height: 50.0,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: Color(0xFFE0F7FA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateClass()),
                        );
                      },
                      child: Text(
                        "Create A Class",
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      )
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    //shrinkWrap: true,
                    itemCount: allClasses.length,
                    itemBuilder: (context, index) {
                      var name = allClasses[index];
                      return Card(
                        child:ListTile(
                            title: Text(name.id.substring(0, name.id.length-7)),
                            onTap:() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => classView(class_ : allClasses[index])),
                              );
                            }
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      } else { //classes havn't been retrieved yet
      return CircularProgressIndicator(
        backgroundColor: Color(0xFFE0F7FA),
      );
    }
  }


  Future<void> incorrectDomainName() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ERROR:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Your email does not share a similar domain name with the user who sent the invite link, you will not be added to this class.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Understood'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> classOwnerAcceptedLink() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ERROR:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You cannot accept an invite link to a class you are the owner of.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Understood'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> addUserToClass(String deepLink) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    //parse the deepLink for classname and userInv ID
    var splitList = deepLink.split('/');
    String userInvID = splitList[4].substring(9);
    String classID = splitList[3].substring(7);
    classID = classID.replaceAll("+", " "); //url replaces spaces with +, so revert that back
    print("$userInvID invted you to $classID");

    //make sure the user who created the link isn't accepting it
    if(globals.user.email == userInvID){
      classOwnerAcceptedLink();
      return;
    }

    //get a copy of the students array from whoever sent the link
    QuerySnapshot snap = await FirebaseFirestore.instance.collection(userInvID).get();
    Map<String, dynamic> userInvClassData;
    snap.docs.forEach((element) {
      if(element.id == classID){
        userInvClassData = element.data();
      }
    });
    //check if the user who sent the invite wants similar domain names or not
    List userInvDomain = userInvID.split('@');
    List userRecDomain = globals.user.email.split('@');
    if(userInvClassData["similarEmails"] == true && userInvDomain[1] != userRecDomain[1]){
      incorrectDomainName();
      return;
    }

    //add the user who was invited to the array
    final List studentsList = userInvClassData["students"];
    studentsList.add(globals.user.email);
    //update the senders student array in their database for this class
    firestore
        .collection(userInvID)
        .doc(classID)
        .update({
      'students' : studentsList,
    })
        .then((value) => print("Students array updated for link sender $userInvID"))
        .catchError((error) => print(error));

    /*update the individul who accepted the links database, so they now are
    enrolled in that class, and their class database array has everyone else
    in the class, excludeing themselves.
    */

    //append the user who sent the invite link, to accurately update everyone class array
    studentsList.add(userInvID);
    for(int i=0; i<studentsList.length; i++) {
      String cur_student = studentsList[i];
      //copy the values form studentsList to a new list
      List tempStudentsList = new List<String>.from(studentsList);
      //remove the current student so we don't add them to their own class database
      tempStudentsList.remove(cur_student);

      //do not alter the link senders class array, it has already been done above
      if (cur_student != userInvID)
      {
        //if the current user is the one who was invited, create a whole new collection for them
        if (cur_student == globals.user.email) {
          firestore
              .collection(globals.user.email)
              .doc(classID)
              .set({
            'name' : globals.user.displayName,
            'isTeacher': false,
            'correctGuess': 0,
            'totalGuess': 0,
            'accuracy': "%0",
            'students': tempStudentsList,
            'similarEmails': userInvClassData['similarEmails'],
            'gamesPlayed': 0,
          })
              .then((value) =>
              print("Class database created for link receiver"))
              .catchError((error) => print(error));
        }
        else {
          //else if they are someone who was already in the class, just update their students array
          firestore
              .collection(cur_student)
              .doc(classID)
              .update({
            'students': tempStudentsList,
          })
              .then((value) =>
              print(
                  "Students array updated $cur_student, who is already in class $classID"))
              .catchError((error) => print(error));
        }
      }
    }

  }

}
/* CLASSES FOR HOME PAGE ENDS */


/* CLASSES FOR SETTINGS PAGE START */
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  File _image;
  final picker = ImagePicker();
  bool picReceived = false;
  String userImage = " ";

  // use Image.network(downloadURL) to display the images
  Future<void> downloadUserPhoto(String usrEmail) async {
    try {
      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref('uploads/$usrEmail/profile.png')
          .getDownloadURL();
      print("Retrieved image for $usrEmail");
      setState(() {
        picReceived = true;
        userImage = downloadURL;
      });
    } catch (e) {
      print("Couldn't retrieve image for $usrEmail, retrieving default image instead");
      try {
        String downloadURL = await firebase_storage.FirebaseStorage.instance
            .ref('uploads/no_image/Unknown_User.png')
            .getDownloadURL();
        print("Retrieved default image for $usrEmail");
        setState(() {
          picReceived = true;
          userImage = downloadURL;
        });
      } catch (e) {
        print("Failed to retrieve default image for $usrEmail");
      }
    }
  }

  @override
  void initState() {
    downloadUserPhoto(globals.user.email);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(picReceived) {
      return Scaffold(
        backgroundColor: Color(0xFFE0F7FA),
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Settings',
            style: TextStyle(
                fontSize: 30
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(bottom: 65),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(userImage),
                  radius: 70,
                ),
              ),
              Container(
                width: 250.0,
                height: 50.0,
                margin: EdgeInsets.only(bottom: 10.0),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      onPrimary: Color(0xFFE0F7FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      imageSelectOptions();
                    },
                    child: Text(
                        "Upload Profile Picture",
                        style: TextStyle(
                          fontSize: 22,
                        )
                    )
                ),
              ),
              Container(
                width: 250.0,
                height: 50.0,
                margin: EdgeInsets.only(top: 10.0, bottom: 100),
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      onPrimary: Color(0xFFE0F7FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      googleSignOut();
                    },
                    child: Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 22,
                        )
                    )
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return CircularProgressIndicator(
        backgroundColor: Color(0xFFE0F7FA),
      );
    }
  }

  //signs out current user and returns them to homepage
  Future<Widget> googleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() {
      globals.user = null;
      globals.signedIn = false;
      //pop twice to return to login screen
      int count = 0;
      Navigator.popUntil(context, (route) {
        return count ++ == 2;
      });
    });
  }

  Future<void> imageSelectOptions() {
    // return pop up box to allow users to select image from gallery or camera
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('IMAGE UPLOAD LOCATION:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Where would you like to upload your image from?'),
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              //margin: const EdgeInsets.all(15.0),
              //padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent)
              ),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  onPrimary: Color(0xFFE0F7FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                onPressed: () async {
                  getImageGallery();
                },
                child: Text("Gallery")
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  onPrimary: Color(0xFFE0F7FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                onPressed: () async {
                  getImageCamera();
                },
                child: Text("Camera")
            ),
            Divider(),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  //https://firebase.flutter.dev/docs/storage/usage/
  Future getImageCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    //final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        //print(_image.path);
        imageToCloud();
      } else {
        print('No image selected.');
      }
    });
  }

  Future getImageGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    //final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        imageToCloud();
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> imageToCloud () async{
    String usrEmail = globals.user.email;
    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('uploads/$usrEmail/profile.png')
          .putFile(_image);
      print("Successfully uploaded image to cloud");
      setState(() {
        picReceived = false;
        userImage = " ";
        downloadUserPhoto(usrEmail);
      });
    } catch (e) {
      print("An error occured while attempting to upload an image");
    }
  }

}
/* CLASSES FOR SETTINGS PAGE END */


/* CLASSES FOR CREATE A CLASS START */
class CreateClass extends StatefulWidget {
  @override
  _CreateClassState createState() => _CreateClassState();
}

/*
For organizing data in firebase, create a 'collection' using the users ID so its unique.
Each 'Collection' will be filled with 'Document', which will be the name of the classes they are in.
Each 'Document' will have fields, that represent the students in the class, including a bool that
is true if they are the owner of the class
 */
class _CreateClassState extends State<CreateClass> {
  final form_key = GlobalKey<FormState>();
  bool _checkbox = false;
  String _class = " ";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FA),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Create A Class',
          style: TextStyle(
              fontSize: 30
          ),
        ),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              AddClassForm(),
            ]
        ),
      ),
    );
  }

  /*
   Note to self, ensure the only characters entered in the form field
   for the class name are letters and numbers, special characters may cause
   trouble when extracting the name from the dynamic link
   */
  //form for creating a class
  Form AddClassForm() {
    return Form(
        key: form_key,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: input() + buttons()
        )
    );
  }

  //validates form for creating a class
  bool validateForm(){
    final form = form_key.currentState;
    if(form.validate()){
      form.save();
      setState(() {
        firebaseCreateClass();
      });
      return true;
    }
    return false;
  }

  //input for AddClassForm
  List<Widget> input() {
    return [
      TextFormField(
        key: Key("input_key"),
        decoration: const InputDecoration(
          icon: Icon(Icons.person),
          hintText: 'CSCI 567',
          labelText: 'Name of Class:',
        ),
        onSaved: (String className){
          _class = className;
        },
        validator: (String className) {
          //ensure a class name was entered
          if ((className.isEmpty)) {
            return 'Please enter text';
          }
          //ensure no special characters are in the classname using a regex
          RegExp exp = RegExp(r"([a-z A-Z0-9])");
          Iterable<RegExpMatch> matches = exp.allMatches(className);
          if(matches.length != className.length) {
            return 'Class names only allow letters, numbers, and spaces';
          }
          return null;
        },
      ),
      CheckboxListTile(
          title: Text("Ensure users share similar email domains?"),
          value: _checkbox,
          onChanged: (bool value) {
            setState(() {
              _checkbox = value;
            });
          }
      ),
    ];
  }

  //buttons for AddClassForm
  List<Widget> buttons() {
    return [
      Container(
          width: 250.0,
          height: 50.0,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              onPrimary: Color(0xFFE0F7FA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.0),
              ),
            ),
            key: Key("submit_key"),
            onPressed: validateForm,
            child: Text(
              "Create Class",
              style: TextStyle(
                fontSize: 22,
              ),
            ),
          )
      ),
    ];
  }

  //Creates a class for the specified user in firebase
  Future<void> firebaseCreateClass() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    print(globals.user.uid);
    print(globals.user.email);

    //append a pound and 5 digits to the end of class name, so users
    //can be enrolled in many classes with the same name
    String classUniqueID = "#";
    var rng = new Random();
    for (var i = 0; i < 6; i++) {//generates 0-9
      classUniqueID += rng.nextInt(10).toString();
    }
    _class += classUniqueID;

    firestore
        .collection(globals.user.email)
        .doc(_class)
        .set({
      'name' : globals.user.displayName,
      'isTeacher' : true,
      'correctGuess' : 0,
      'totalGuess' : 0,
      'accuracy' : "%0",
      'students' : [],
      'similarEmails': _checkbox,
      'gamesPlayed' : 0,
    })
        .then((value) => print("Class added to database"))
        .catchError((error) => print(error));
    generateLinkPopup();

  }


  Future<void> generateLinkPopup() {
    // return pop up box with firebase link to invite people
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('SUCCESS:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Your class has been created! Send this link to users so they can join your class.'),
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              //margin: const EdgeInsets.all(15.0),
              //padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent)
              ),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  onPrimary: Color(0xFFE0F7FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
                onPressed: () async {
                  var dynamicLink = await generateDynamicLink(_class);
                  print(dynamicLink);
                  Clipboard.setData(new ClipboardData(text: dynamicLink.toString()));
                },
                child: Text("Generate And Copy To Clipboard ")
            ),
            Divider(),
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //possible help: https://stackoverflow.com/questions/45703215/how-to-generate-a-dynamic-link-for-a-specific-post-in-android-firebase/45704583#45704583
  //https://stackoverflow.com/questions/58481840/flutter-how-to-pass-custom-arguments-in-firebase-dynamic-links-for-app-invite
  Future<Uri> generateDynamicLink (String className) async {
    String userInv = globals.user.email;
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://familface.page.link', //this is the link should match firebase
      link: Uri.parse('https://familface.page.link/?class=$className/?userInv=$userInv'), //this is the deep link, can add parameters
      androidParameters: AndroidParameters(
        packageName: 'com.example.familiarface',
        minimumVersion: 0,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        bundleId: 'com.example.familiarface',
        minimumVersion: '0',
      ),
    );
    final link = await parameters.buildUrl();
    final ShortDynamicLink shortenedLink = await DynamicLinkParameters.shortenUrl(
      link,
      DynamicLinkParametersOptions(shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    return shortenedLink.shortUrl;
  }
}
/* CLASSES FOR CREATE A CLASS END */



/* CLASSES FOR CLASS VIEW START */
class classView extends StatefulWidget {
  final QueryDocumentSnapshot class_;

  classView({Key key, @required this.class_}) : super(key: key);

  @override
  _classViewState createState() => _classViewState();
}


class _classViewState extends State<classView> {
  var studentInfo = new Map();
  var classData = new Map();
  bool varsInitialized = false;
  Map <String, int> gameData = {
    "gamesPlayed": 0,
    "accuracy": 0,
    "correctGuess": 0,
    "totalGuess": 0,
  };

  Future <void> populateStudentInfo() async {
    studentInfo = await gatherStudentData(widget.class_.data(), widget.class_.id);
    setState(() {
      varsInitialized = true;
    });
  }

  @override
  void initState()  {
    classData = widget.class_.data();
    super.initState();
    populateStudentInfo();
  }

  @override
  Widget build(BuildContext context){
    if(varsInitialized) {
      if(classData["isTeacher"] == true){
        return Scaffold(
          backgroundColor: Color(0xFFE0F7FA),
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              widget.class_.id.substring(0, widget.class_.id.length - 7),
              style: TextStyle(
                  fontSize: 30
              ),
            ),
          ),
          body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                matchingGame(classUserData: studentInfo, className: widget.class_.id)),
                          );
                        },
                        child: Text(
                          "Play Game",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                roster(classUserData: studentInfo)),
                          );
                        },
                        child: Text(
                          "View Roster",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                scoreboard(className: widget.class_.id)),
                          );
                        },
                        child: Text(
                          "View Scoreboard",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () async {
                          var dynamicLink = await generateDynamicLink(
                              widget.class_.id);
                          print(dynamicLink);
                          Clipboard.setData(
                              new ClipboardData(text: dynamicLink.toString()));
                        },
                        child: Text(
                          "Generate and Copy Link",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          deleteClassWarning(context);
                        },
                        child: Text(
                          "Delete Class",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                ]
            ),
          ),
        );
      } else{ //user is not the owner of this class
        return Scaffold(
          backgroundColor: Color(0xFFE0F7FA),
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              widget.class_.id.substring(0, widget.class_.id.length - 7),
              style: TextStyle(
                  fontSize: 30
              ),
            ),
          ),
          body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                matchingGame(classUserData: studentInfo, className: widget.class_.id)),
                          );
                        },
                        child: Text(
                          "Play Game",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                roster(classUserData: studentInfo)),
                          );
                        },
                        child: Text(
                          "View Roster",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>
                                scoreboard(className: widget.class_.id)),
                          );
                        },
                        child: Text(
                          "View Scoreboard",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                  Container(
                    width: 250.0,
                    height: 50.0,
                    margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          onPrimary: Color(0xFFE0F7FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          leaveClassWarning(context);
                        },
                        child: Text(
                          "Leave Class",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                    ),
                  ),
                ]
            ),
          ),
        );
      }
    } else {
      return CircularProgressIndicator(
        backgroundColor: Color(0xFFE0F7FA),
      );
    }
  }

  Future<void> leaveClassWarning (BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('WARNING:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to leave this class?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                deleteIndividualFromFirebase();
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteClassWarning (BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('WARNING:'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this class and all its data?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                deleteFromFirebase();
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteIndividualFromFirebase() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    //get a list of users in the same class
    QuerySnapshot snap = await FirebaseFirestore.instance.collection(globals.user.email).get();
    Map<String, dynamic> userInvClassData;
    snap.docs.forEach((element) {
      if(element.id == widget.class_.id){
        userInvClassData = element.data();
      }
    });
    final List studentList = userInvClassData["students"];

    //delete class from this users database
    firestore.collection(globals.user.email).doc(widget.class_.id).delete();

    //delete the user from all other student databases
    for(int i=0; i<studentList.length; i++)
    {
      String cur_student = studentList[i];
      //update the collection minus the user who just left the class
      List tempStudentList;
      Future<DocumentSnapshot> docSnap = firestore.collection(cur_student).doc(widget.class_.id).get();
      docSnap.then( (DocumentSnapshot classDoc) => {
        tempStudentList = new List<String>.from(classDoc["students"]),
        //remove the email from the list and update the database
        tempStudentList.remove(globals.user.email),
        //update student array
        firestore
            .collection(cur_student)
            .doc(widget.class_.id)
            .update({
          'students': tempStudentList,
        })
            .then((value) => print("Students array updated for $cur_student"))
            .catchError((error) => print(error))
      });
    }
    //pop three times so we are back at the home page
    int count = 0;
    Navigator.popUntil(context, (route) {
      return count++ == 3;
    });
  }

  //deletes specified class from firebase
  Future<void> deleteFromFirebase () async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    //get a list of users in this class
    List tempStudentList;
    Future<DocumentSnapshot> docSnap = firestore.collection(globals.user.email).doc(widget.class_.id).get();
    docSnap.then ( (DocumentSnapshot classDoc) => {
      tempStudentList = new List<String>.from(classDoc["students"]),
      for(int i=0; i<tempStudentList.length; i++)
        {
          //delete the class from everyone else who is enrolled in it
          firestore.collection(tempStudentList[i]).doc(widget.class_.id).delete()
        },
      //delete the class from the class owners database
      firestore.collection(globals.user.email).doc(widget.class_.id).delete()
    });

    //pop three times so we are back at the home page
    int count = 0;
    Navigator.popUntil(context, (route) {
      return count++ == 3;
    });
  }

  Future<Uri> generateDynamicLink (String className) async {
    String userInv = globals.user.email;
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://familface.page.link', //this is the link should match firebase
      link: Uri.parse('https://familface.page.link/?class=$className/?userInv=$userInv'), //this is the deep link, can add parameters
      androidParameters: AndroidParameters(
        packageName: 'com.example.familiarface',
        minimumVersion: 0,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        bundleId: 'com.example.familiarface',
        minimumVersion: '0',
      ),
    );
    final link = await parameters.buildUrl();
    final ShortDynamicLink shortenedLink = await DynamicLinkParameters.shortenUrl(
      link,
      DynamicLinkParametersOptions(shortDynamicLinkPathLength: ShortDynamicLinkPathLength.unguessable),
    );
    return shortenedLink.shortUrl;
  }
}
/* CLASSES FOR CLASS VIEW END */


/* CLASSES FOR SCOREBOARD START */

class scoreboard extends StatefulWidget {
  final String className;

  scoreboard({Key key, @required this.className}) :super(key: key);

  @override
  scoreboardState createState() => scoreboardState();
}
class scoreboardState extends State<scoreboard> {
  String gamesPlayed = " ";
  String accuracy = " ";
  String correctGuess = " ";
  String totalGuess = " ";
  bool initialized = false;

  Future<void> retrieveScoreboardData() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Future<DocumentSnapshot> docSnap = firestore.collection(globals.user.email).doc(widget.className).get();
    docSnap.then( (DocumentSnapshot classDoc) => {
      gamesPlayed = classDoc["gamesPlayed"].toString(),
      accuracy = classDoc["accuracy"].toString(),
      print(accuracy),
      //case 1 and 2, the size is 3, so its either 1.0 or 0.'num'
      if(accuracy.length <= 3)
        {
          if(accuracy[0] == "1")
            {
              print("in case 1"),
              accuracy == "100"
            }
          else if(accuracy.length != 1)
            {
              print("in case 2"),
              accuracy = accuracy.substring(2),
              accuracy += "0"
            }
        }
      //case 3, its a very long repeating value
      else
        {
          print("in case 3"),
          print(accuracy),
          accuracy = accuracy.substring(2,4)
        },
      correctGuess = classDoc["correctGuess"].toString(),
      totalGuess = classDoc["totalGuess"].toString(),
      setState(() {
        initialized = true;
      }),
    });
  }

  @override
  void initState() {
    retrieveScoreboardData();
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    if(initialized)
    {
      return Scaffold(
          backgroundColor: Color(0xFFE0F7FA),
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "Scoreboard",
              style: TextStyle(
                  fontSize: 30
              ),
            ),
          ),
          body: ListView(
            children: [
              Card(
                child: ListTile(
                  title: Text(
                    "Games Played: $gamesPlayed",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Accuracy: $accuracy%",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Correct Guesses: $correctGuess",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(
                    "Total Guesses: $totalGuess",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          )
      );
    } else {
      return CircularProgressIndicator(
        backgroundColor: Color(0xFFE0F7FA),
      );
    }
  }
}
/* CLASSES FOR SCOREBOARD END */


/* CLASSES FOR ROSTER START */

/* This function will pass a map of all student names and their
corresponding images to 'roster', so it can display them in a list
 */
Future<Map> gatherStudentData(Map<String, dynamic> classData, String className) async {
  List studentEmailList = new List<String>.from(classData["students"]);

  var studentInfo = new Map();

  //using student emails, retrieve their names from their database
  for(int i=0; i<studentEmailList.length; i++)
  {
    String studentName;
    QuerySnapshot snap = await FirebaseFirestore.instance.collection(studentEmailList[i]).get();
    snap.docs.forEach((element) {
      if(element.id == className){
        Map<String, dynamic> data = element.data();
        //capture the students name
        studentName = data["name"];
        //append 6 digit number at the end to ensure uniqueness
        String studentUniqueID = "#";
        var rng = new Random();
        for (var i = 0; i < 6; i++) {//generates 0-9
          studentUniqueID += rng.nextInt(10).toString();
        }
        studentName += studentUniqueID;
      }
    });
    //now retrieve their corresponding pictures from firebase
    String userPictureURL = await downloadUserPhoto(studentEmailList[i]);
    //add to map
    studentInfo[studentName] = userPictureURL;
  }
  //map full of student names and corresponding images
  print(studentInfo);
  //pass this map to the roster page
  return studentInfo;
}

// use Image.network(downloadURL) to display the images
Future<String> downloadUserPhoto(String usrEmail) async {
  try {
    String downloadURL = await firebase_storage.FirebaseStorage.instance
        .ref('uploads/$usrEmail/profile.png')
        .getDownloadURL();
    print("Retrieved image for $usrEmail");
    return downloadURL;
  } catch (e) {
    print("Couldn't retrieve image for $usrEmail, retrieving default image instead");
    try {
      String downloadURL = await firebase_storage.FirebaseStorage.instance
          .ref('uploads/no_image/Unknown_User.png')
          .getDownloadURL();
      print("Retrieved default image for $usrEmail");
      return downloadURL;
    } catch (e) {
      print("Failed to retrieve default image for $usrEmail");
    }
  }
}


class roster extends StatefulWidget{
  var classUserData = new Map();

  roster({Key key, @required this.classUserData}) : super(key : key);

  @override
  rosterState createState() => rosterState();
}


class rosterState extends State<roster> {
  List studentNames = [];
  List studentPhotoURLS = [];

  void splitMap () {
    widget.classUserData.forEach((key, value) {
      studentNames.add(key);
      studentPhotoURLS.add(value);
    });
  }

  @override
  void initState() {
    splitMap();
    super.initState();
  }

  //Roster should show name with a picture of them as well
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFFE0F7FA),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Roster",
          style: TextStyle(
              fontSize: 30
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: widget.classUserData.length,
        itemBuilder: (context, index) {
          String name = studentNames[index];
          String URL = studentPhotoURLS[index];
          return Container(
            height: 100,
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(URL),
                  radius: 50,
                ),
                title: Text(name.substring(0, name.length-7)),
              ),
            ),
          );
        },
      ),
    );
  }
}
/* CLASSES FOR ROSTER END */


/* CLASSES FOR GAME START */
/* For the game, wrap the CircleAvatar and text widgets in GestureDetectors,
so when they are tapped a function can then be called. To ensure they matched up the
right name with the right picture, index the map with the name they pressed, and see
if the corresponding URL is the one to the picture they tapped
 */
/* CLASSES FOR GAME START */
class matchingGame extends StatefulWidget{
  var classUserData = new Map();
  String className = " ";

  matchingGame({Key key, @required this.classUserData, this.className}) : super(key : key);

  @override
  matchingGameState createState() => matchingGameState();
}

class matchingGameState extends State<matchingGame> {
  //vars for handling game logic
  List studentNames = [], studentPhotoURLS = [];
  String currentSelectedAvatar = " ", currentSelectedName = " ";
  var avatarColorList, textColorList;
  bool avatarSelected = false, textSelected = false, initialized = false;
  //vars for keeping track of game stats
  int gamesPlayed, correctGuess, totalGuess;
  String accuracy;

  void splitMap () {
    widget.classUserData.forEach((key, value) {
      studentNames.add(key);
      studentPhotoURLS.add(value);
    });
    //shuffle lists for the game
    studentNames.shuffle();
    studentPhotoURLS.shuffle();
  }

  Future<void> retrieveScoreboardData() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Future<DocumentSnapshot> docSnap = firestore.collection(globals.user.email).doc(widget.className).get();
    docSnap.then((DocumentSnapshot snap) => {
      gamesPlayed = snap["gamesPlayed"],
      accuracy = snap["accuracy"].toString(),
      correctGuess = snap["correctGuess"],
      totalGuess = snap["totalGuess"],
      setState(() {
        initialized = true;
        gamesPlayed += 1;
      })
    });
  }

  @override
  void initState() {
    retrieveScoreboardData();
    splitMap();
    //initialize the color list
    avatarColorList = List.filled(studentNames.length, Colors.white, growable: false);
    textColorList = List.filled(studentNames.length, Colors.black, growable: false);
    //increment games played
    super.initState();
  }

  //use a list view and wrap the text and circle avatar in gesture detectors
  @override
  Widget build(BuildContext context) {
    if(initialized)
    {
      return Scaffold(
        backgroundColor: Color(0xFFE0F7FA),
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Matching Game",
            style: TextStyle(
                fontSize: 30
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: ListView.builder(
          itemCount: studentNames.length,
          itemBuilder: (context, index) {
            String name = studentNames[index];
            return Container(
              height: 100,
              child: ListTile(
                leading: GestureDetector(
                  onTap: () {
                    setState(() {
                      currentSelectedAvatar = studentPhotoURLS[index];
                      if(avatarColorList[index] == Colors.white)
                      {
                        for(int i=0; i<avatarColorList.length; i++)
                        {
                          avatarColorList[i] = Colors.white;
                        }
                        avatarColorList[index] = Colors.green;
                        avatarSelected = true;
                      }
                      else{
                        avatarColorList[index] = Colors.white;
                        avatarSelected = false;
                      }
                      //check if there is a selection on both sides
                      if(avatarSelected && textSelected)
                      {
                        selectionValidation();
                      }
                    });
                  },
                  child: CircleAvatar(
                      radius: 50,
                      backgroundColor: avatarColorList[index],
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(studentPhotoURLS[index]),
                      )
                  ),
                ),
                trailing: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentSelectedName = studentNames[index];
                        if(textColorList[index] == Colors.black)
                        {
                          for(int i=0; i<textColorList.length; i++)
                          {
                            textColorList[i] = Colors.black;
                          }
                          textColorList[index] = Colors.green;
                          textSelected = true;
                        }
                        else{
                          textColorList[index] = Colors.black;
                          textSelected = false;
                        }
                        //check if there is a selection on both sides
                        if(avatarSelected && textSelected)
                        {
                          selectionValidation();
                        }
                      });
                    },
                    child: Text(
                      name.substring(0, name.length-7),
                      style: TextStyle(
                        color: textColorList[index],
                        fontSize: 20,
                      ),
                    )
                ),
              ),
            );
          },
        ),
      );
    } else {
      return CircularProgressIndicator(
        backgroundColor: Color(0xFFE0F7FA),
      );
    }
  }

  /*this function will check if the users selected avatar lines up with
  the corresponding name. It will also update the game data map respectively
   */
  void selectionValidation() {
    totalGuess += 1;
    /*
      if they guessed correctly, remove the corresponding name and url
      from their respective lists
     */
    if(widget.classUserData[currentSelectedName] == currentSelectedAvatar)
    {
      print("Correct Match");
      studentNames.remove(currentSelectedName);
      studentPhotoURLS.remove(currentSelectedAvatar);
      correctGuess += 1;
    }
    else
    {
      print("Incorrect Match");
    }

    //reset the colors for both lists
    for(int i=0; i<textColorList.length; i++)
    {
      textColorList[i] = Colors.black;
      avatarColorList[i] = Colors.white;
    }
    //reset the bools for selection
    avatarSelected = false;
    textSelected = false;
    //update accuracy
    accuracy = (correctGuess / totalGuess).toString();
    //check if there are any more game values left, if not update game stats and return
    if(studentNames.length <= 0)
    {
      updateGameStats();
      Navigator.pop(context);
    }
  }

  Future<void> updateGameStats() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore
        .collection(globals.user.email)
        .doc(widget.className)
        .update({
      'accuracy' : accuracy,
      'totalGuess' : totalGuess,
      'correctGuess' : correctGuess,
      'gamesPlayed' : gamesPlayed,
    })
        .then((value) => print("Game stats updated"))
        .catchError((error) => print(error));
  }
}
/* CLASSES FOR GAME END */