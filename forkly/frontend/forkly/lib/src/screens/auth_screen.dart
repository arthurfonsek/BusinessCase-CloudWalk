import 'package:flutter/material.dart';
import '../services/api.dart';

class AuthScreen extends StatefulWidget { 
  const AuthScreen({super.key}); 
  @override 
  State<AuthScreen> createState()=>_AuthScreenState(); 
}

class _AuthScreenState extends State<AuthScreen>{
  final _api=Api(); 
  final _u=TextEditingController(); 
  final _p=TextEditingController(); 
  final _code=TextEditingController(); 
  String? _resp;
  
  @override 
  Widget build(BuildContext c){
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16), 
        child: Column(children:[
          TextField(controller:_u, decoration: const InputDecoration(labelText:"Username")),
          TextField(controller:_p, obscureText:true, decoration: const InputDecoration(labelText:"Password")),
          TextField(controller:_code, decoration: const InputDecoration(labelText:"Referral code (optional)")),
          const SizedBox(height:12),
          ElevatedButton(onPressed: () async {
            final r=await _api.register(_u.text,_p.text, referral:_code.text.isEmpty?null:_code.text);
            setState(()=>_resp="Your code: ${r['referral_code']}");
          }, child: const Text("Create account")),
          if(_resp!=null) Padding(padding: const EdgeInsets.only(top:12), child: Text(_resp!))
        ])
      )
    );
  }
}
