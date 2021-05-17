import 'package:firebase_auth/firebase_auth.dart';


bool signedIn = false;
User user;
String loginDynamicLink = "";
bool caughtInSignIn = false;