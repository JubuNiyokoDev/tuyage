// // ignore_for_file: unused_import

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:tuyage/common/extension/custom_theme_extension.dart';
// import 'package:tuyage/common/widgets/custom_icon_button.dart';
// import 'package:tuyage/feature/auth/controller/auth_controller.dart';
// import 'package:tuyage/feature/auth/widgets/custom_text_field.dart';

// class VerificationPage extends ConsumerWidget {
//   const VerificationPage({
//     super.key,
//     required this.smsCodeId,
//     required this.phoneNumber,
//   });

//   final String smsCodeId;
//   final String phoneNumber;
//   void verifySmsCode(
//     BuildContext context,
//     WidgetRef ref,
//     String smsCode,
//   ) {
//     ref.read(authControllerProvider).verifySmsCode(
//           context: context,
//           smsCodeId: smsCodeId,
//           smsCode: smsCode,
//           mounted: true,
//         );
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         elevation: 0,
//         title: Text(
//           'Verifya numero yawe',
//           style: TextStyle(
//             color: context.theme.authAppbarTextColor,
//           ),
//         ),
//         centerTitle: true,
//         actions: [CustomIconButton(onPressed: () {}, icon: Icons.more_vert)],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               child: RichText(
//                 textAlign: TextAlign.center,
//                 text: TextSpan(
//                     style: TextStyle(
//                       color: context.theme.greyColor,
//                       height: 1.5,
//                     ),
//                     children: [
//                       const TextSpan(
//                           text:
//                               "Wagerageje kwinjira na +25761895940. imbere yogusaba SMS canke Call kugira uronke code."),
//                       TextSpan(
//                           text: " Wihenze numero?",
//                           style: TextStyle(
//                             color: context.theme.blueColor,
//                           ))
//                     ]),
//               ),
//             ),
//             const SizedBox(
//               height: 20,
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 80),
//               child: CustomTextField(
//                 hintText: '- - -  - - -',
//                 fontSize: 30,
//                 autFocus: true,
//                 keyboardType: TextInputType.number,
//                 onChanged: (value) {
//                   if (value.length == 6) {
//                     return verifySmsCode(context, ref, value);
//                   }
//                 },
//               ),
//             ),
//             const SizedBox(
//               height: 20,
//             ),
//             Text(
//               "Injiza ibiharuro 6 vya code",
//               style: TextStyle(color: context.theme.greyColor),
//             ),
//             const SizedBox(
//               height: 30,
//             ),
//             Row(
//               children: [
//                 Icon(
//                   Icons.message,
//                   color: context.theme.greyColor,
//                 ),
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 Text(
//                   "Rungika Kandi SMS",
//                   style: TextStyle(color: context.theme.greyColor),
//                 )
//               ],
//             ),
//             const SizedBox(
//               height: 10,
//             ),
//             Divider(
//               color: context.theme.blueColor!.withOpacity(0.2),
//             ),
//             const SizedBox(
//               height: 10,
//             ),
//             Row(
//               children: [
//                 Icon(
//                   Icons.phone,
//                   color: context.theme.greyColor,
//                 ),
//                 const SizedBox(
//                   height: 20,
//                 ),
//                 Text(
//                   "Nterefona",
//                   style: TextStyle(color: context.theme.greyColor),
//                 )
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
