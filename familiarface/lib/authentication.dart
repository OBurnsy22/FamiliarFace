import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import "main.dart";

/* Code block for flutter firebase sign in via google START */
class authenticationPage extends StatefulWidget {

  @override
  _authenticationPageState createState() => _authenticationPageState();
}

class _authenticationPageState extends State<authenticationPage> {
  bool signedIn = false;

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
                    googleSignIn();
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

  Future<UserCredential> googleSignIn() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    /*
    print(googleUser.email);
    print(googleUser.displayName);
     */
    // Once signed in, return the UserCredential
    setState(() {
      signedIn = true;
    });
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}

/* Code block for flutter firebase sign in via google END */
