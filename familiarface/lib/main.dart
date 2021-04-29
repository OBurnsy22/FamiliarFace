import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/services.dart';
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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.lightBlue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'FamiliarFace'),
    );
  }
}

/* CLASSES FOR HOME PAGE START */
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _initialized = false;

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
    print("in init current user");
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

  //handles dynamic links
  void initDynamicLinks() async {
    print("in initDynamicLinks");
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
    /*
    if (deepLink != null) {
      print("INSIDE SECOND IF");
      addUserToClass(deepLink.toString());
      print(deepLink);
    }*/
  }

  @override
  void initState() {
    super.initState();
    initializeFlutterFire();
    initDynamicLinks();
  }

  @override     // This method is rerun every time setState is called, for instance as done
  Widget build(BuildContext context) {
    if(_initialized) { //If firebase is initialized
      //print(globals.signedIn);
      if (globals.signedIn && globals.user != null) { //IF USER IS SIGNED IN
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
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
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateClass()),
                      );
                    },
                    child: Text("Create A Class")
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyClasses()),
                      );
                    },
                    child: Text("My Classes")
                ),
              ],
            ),
          ),
        );
      } else { //IF USER IS NOT SIGNED IN
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () {
                      singInErrorCatcher();
                    },
                    child: Text("Sign in with Google")
                ),
              ],
            ),
          ),
        );
      }
    } else { //If firebase is not initialized
      return CircularProgressIndicator();
    }
  }

  /* AUTHENITCATION FUNCTIONS */
  //function called before google sign in, to catch
  //any potential sign in erros
  Future<void> singInErrorCatcher() async {
    try{
      await googleSignIn();
    } catch(error) {
      print(error);
    }
  }

  //signs the user in through google
  Future<UserCredential> googleSignIn() async {  //look at firebase auth for reference
    // Trigger the authentication flow
    print("in google sign in");
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


  void addUserToClass(String deepLink) {
    //parse the deepLink for classname and userInv ID
    var splitList = deepLink.split('/');
    String userInvID = splitList[4].substring(11);
    String classID = splitList[3].substring(7);
    classID = classID.replaceAll("+", " "); //url replaces spaces with +, so revert that back
  }

}
/* CLASSES FOR HOME PAGE ENDS */


/* CLASSES FOR SETTINGS PAGE START */
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                    onPressed: () {
                      googleSignOut();
                    },
                    child: Text("Logout")
                ),
              ],
          ),
      ),
    );
  }

  //signs out current user and returns them to homepage
  Future<Widget> googleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() {
      globals.user = null;
      globals.signedIn = false;
    });
    await Future.delayed(Duration(seconds: 2)); //wait 2 seconds for vars to update
    Navigator.pop(context);
    //force a naviagtion event to go back to the homepage
    //pop the entire stack and push the home page back onto the stack
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
      appBar: AppBar(
        title: Text('Create A Class'),
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
          // This optional block of code can be used to run
          // code when the user saves the form.
        },
        validator: (String className) {
          if ((className.isEmpty)) {
            return 'Please enter text';
          }
          return null;
        },
      ),
      CheckboxListTile(
          title: Text("Ensure users share same school email?"),
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
      ElevatedButton(
        key: Key("submit_key"),
        onPressed: validateForm,
        child: Text("Create Class"),
      )
    ];
  }

  //Creates a class for the specified user in firebase
  Future<void> firebaseCreateClass() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    print(globals.user.uid);
    print(globals.user.email);

    //collection query to see if user email is already in database
    QuerySnapshot collValue = await firestore
      .collection(globals.user.email).get();

    if(collValue.size == 0) //if the user doesn't have a collection, add one using their email
    {
      firestore
          .collection(globals.user.email)
          .doc(_class)
          .set({  // use '.update' is the collections/documents already exist
        'isTeacher' : true,
        'correctGuess' : 0,
        'totalGuess' : 0,
        'accuracy' : "%0",
        'students' : [],
        'similarEmails': _checkbox,
        'gamesPlayed' : 0,
      })
          .then((value) => print("Class database created"))
          .catchError((error) => print(error));
      generateLinkPopup();
    }
    else { //user has a collection, so see if document already exists, if it does throw error
      DocumentSnapshot document = await firestore.collection(globals.user.email).doc(_class).get();
      if(document.exists) //if it exists throw error (can't be enrolled in duplicate classes)
        {
          return showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('ERROR:'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Text('A user may not be enrolled in multiple classes sharing the same name.'),
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
      else
        {
          firestore
              .collection(globals.user.email)
              .doc(_class)
              .set({
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
    }
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


/* CLASSES FOR MY CLASSES START */
class MyClasses extends StatefulWidget {
  @override
  _MyClassesState createState() => _MyClassesState();
}

class _MyClassesState extends State<MyClasses> {
  var myDocs = [];
  List<QueryDocumentSnapshot> allClasses = [];
  bool classesRetrieved = false;

  @override
  Widget build(BuildContext context) {
    if(classesRetrieved) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Classes'),
        ),
        body: ListView.builder(
          itemCount: allClasses.length,
          itemBuilder: (context, index) {
            var name = allClasses[index];
            return ListTile(
              title: Text(name.id),
              onTap:() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => classView(class_ : allClasses[index])),
                );
              }
            );
          },
        ),
      );
    } else {
      return CircularProgressIndicator();
    }
  }

  @override
  void initState() {
    retrieveClasses();
    super.initState();
  }

  Future<void> retrieveClasses() async{ //possible hint for responsive lists: https://stackoverflow.com/questions/51415556/flutter-listview-item-click-listener/52771937
    QuerySnapshot snap = await FirebaseFirestore.instance.collection(globals.user.email).get();
    //loops through all documents, appending their names to the myDocs list
    snap.docs.forEach((element) {
      allClasses.add(element);
    });
    print(allClasses.length);
    setState(() {
      classesRetrieved = true;
    });
    /*print(allClasses[0].data());
    Map<String, dynamic> myData = allClasses[0].data();
    print(myData["accuracy"]); */
  }
}
/* CLASSES FOR MY CLASSES END */




/* CLASSES FOR CLASS VIEW START */
class classView extends StatefulWidget {
  final QueryDocumentSnapshot class_;

  classView({Key key, @required this.class_}) : super(key: key);

  @override
  _classViewState createState() => _classViewState();
}


class _classViewState extends State<classView> {
  //final QueryDocumentSnapshot class_;

  //constructor that requires a QueryDocumentSnapshot
  //classView({Key key, @required this.class_}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.class_.id),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                //navigate to play game
              },
              child: Text("Play Game")
            ),
            ElevatedButton(
              onPressed: () {
                //naviagete to roster
              },
              child: Text("View Roster")
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => scoreboard(classData : widget.class_.data())),
                  );
                },
                child: Text("View Scoreboard")
            ),
            ElevatedButton(
              onPressed: () {
                //copy link to clipboard
              },
              child: Text("Generate and Copy Link")
            ),
            ElevatedButton(
                onPressed: () {
                  deleteClassWarning(context);
                },
                child: Text("Delete Class")
            ),
          ]
        ),
      ),
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

  //deletes specified class from firebase
  Future<void> deleteFromFirebase () {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore.collection(globals.user.email).doc(widget.class_.id).delete();

    //pop three times so we are back at the home page
    int count = 0;
    Navigator.popUntil(context, (route) {
        return count++ == 3;
    });
  }
}
/* CLASSES FOR CLASS VIEW END */



/* CLASSES FOR SCOREBOARD START */
class scoreboard extends StatelessWidget {
 final Map<String, dynamic> classData;

 //constructor that requires a Map
 scoreboard({Key key, @required this.classData}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Scoreboard"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(classData["gamesPlayed"].toString()),
          ),
          ListTile(
            title: Text(classData["accuracy"].toString()),
          ),
          ListTile(
            title: Text(classData["correctGuess"].toString()),
          ),
          ListTile(
            title: Text(classData["totalGuess"].toString()),
          ),
        ],
      )
    );
  }
}
/* CLASSES FOR SCOREBOARD END */