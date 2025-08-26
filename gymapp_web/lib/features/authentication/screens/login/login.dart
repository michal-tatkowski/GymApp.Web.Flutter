import 'package:flutter/material.dart';

import '../../../../common/widgets.login_signup/form_divider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key})

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsetsGeometry.directional(),
              child: Column(
                children: [
                  const TLoginHeader(),
                  const TLoginForm(),
                  TFormDivider(dividerText: TTexts.orSignInWith.capitalize!)
                  const SizedBox(height: TSizes.spaceBtwSections),
                  const TSocialButtons(),
                ],
              )
          ),
        )
        }
}