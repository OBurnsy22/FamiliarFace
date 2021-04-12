import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import "main.dart";

/* Code block for flutter firebase sign in via google START */
class authenticationPage extends StatefulWidget {
  signOut() => createState().googleSignOut();

  @override
  _authenticationPageState createState() => _authenticationPageState();
}

class _authenticationPageState extends State<authenticationPage> {
  bool signedIn = false;
  User user;


  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance
      .authStateChanges()
      .listen((User user) {
    if (user != null) {
      print(user.uid);
      setState(() {
       this.user=user;
      });
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    if(!signedIn){
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, //aligns children widgets vertically
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
    return MyHomePage(title: 'FamiliarFace');
  }

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
      signedIn = true;
    });
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  void googleSignOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() {
      this.user = null;
    });
  }

}

/* Code block for flutter firebase sign in via google END */