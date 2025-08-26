import 'package:flutter/material.dart';

import '../../../../common/sizes.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext) {
    return Scaffold(
      appBar: AppBar(),
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(TSizes.defaultSpace)
          child: Column(
              children: [
                Text(TText.singupTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: TSizes.spaceBtwSections,)
              Form(child: )
              ]
          )),
        ),
    )
  }
}