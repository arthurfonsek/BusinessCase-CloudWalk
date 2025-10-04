import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class RewardsScreen extends StatelessWidget{
  const RewardsScreen({super.key});
  
  @override 
  Widget build(BuildContext c){
    const code = "DEMO123"; // for demo, wire to user profile later
    final link = "https://foodie.app/invite?code=$code";
    return Scaffold(
      appBar: AppBar(title: const Text("Rewards & Invite")), 
      body: Padding(
        padding: const EdgeInsets.all(16), 
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          const Text("Invite friends and earn points:\n+50 on registration, +100 when they post first review."),
          const SizedBox(height:12),
          SelectableText("Your code: $code\n$link"),
          const SizedBox(height:12),
          ElevatedButton(onPressed: ()=>SharePlus.instance.share(ShareParams(text: "Join me on FoodieMap: $link")), child: const Text("Share Invite Link"))
        ])
      )
    );
  }
}
