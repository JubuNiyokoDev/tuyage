// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:tuyage/common/helper/show_alert_dialog.dart';
// import 'package:tuyage/common/models/status_model.dart';
// import 'package:tuyage/common/models/user_model.dart';
// import 'package:tuyage/common/repository/firebase_storage_repository.dart';
// import 'package:tuyage/common/routes/routes.dart';
// import 'package:uuid/uuid.dart';
// import 'package:tuyage/common/providers/phone_number_cache.dart';

// final statusRepositoryProvider = Provider((ref) => StatusRepository(
//       firestore: FirebaseFirestore.instance,
//       auth: FirebaseAuth.instance,
//       ref: ref,
//     ));

// class StatusRepository {
//   final FirebaseFirestore firestore;
//   final FirebaseAuth auth;
//   final ProviderRef ref;
//   final PhoneNumberCache _phoneNumberCache = PhoneNumberCache();

//   StatusRepository({
//     required this.firestore,
//     required this.auth,
//     required this.ref,
//   });

//   Future<void> uploadStatus({
//     required String username,
//     required String profilePic,
//     required String phoneNumber,
//     required File statusImage,
//     required BuildContext context,
//   }) async {
//     try {
//       var statusId = const Uuid().v1();
//       String uid = auth.currentUser!.uid;

//       // Stocker l'image du statut dans Firebase Storage
//       String imageUrl = await ref
//           .read(firebaseStorageRepositoryProvider)
//           .storeFileToFirebase('/status/$statusId$uid', statusImage);
//       print("Image URL uploaded: $imageUrl");

//       List<Contact> contacts = [];
//       if (await FlutterContacts.requestPermission()) {
//         contacts = await FlutterContacts.getContacts(withProperties: true);
//         print("Contacts retrieved: ${contacts.length}");
//       } else {
//         print("Contacts permission denied");
//         showAlertDialog(
//             context: context, message: 'Contacts permission denied');
//         return;
//       }

//       List<String> uidWhoCanSee = [];

//       for (var contact in contacts) {
//         var rawPhoneNumber =
//             contact.phones.isNotEmpty ? contact.phones[0].number : '';
//         var formattedPhoneNumber = rawPhoneNumber.replaceAll(' ', '');
//         print("Processing phone number: $formattedPhoneNumber");

//         if (formattedPhoneNumber.isNotEmpty) {
//           // Vérifier d'abord dans le cache hybride (mémoire + Hive)
//           String? cachedUid =
//               _phoneNumberCache.getUidFromCache(formattedPhoneNumber);

//           if (cachedUid != null) {
//             // Si trouvé dans le cache, l'ajouter directement
//             print("Found UID in cache for $formattedPhoneNumber: $cachedUid");
//             uidWhoCanSee.add(cachedUid);
//           } else {
//             print("UID not found in cache for $formattedPhoneNumber");
//             // Sinon, interroger Firestore
//             try {
//               var userDataFirebase = await firestore
//                   .collection('users')
//                   .where('phonenumber', isEqualTo: formattedPhoneNumber)
//                   .get();

//               if (userDataFirebase.docs.isNotEmpty) {
//                 var userData =
//                     UserModel.fromMap(userDataFirebase.docs[0].data());
//                 uidWhoCanSee.add(userData.uid);
//                 _phoneNumberCache.addPhoneNumberToCache(
//                     formattedPhoneNumber, userData.uid);
//                 print(
//                     "User UID added to cache for $formattedPhoneNumber: ${userData.uid}");
//               } else {
//                 print("No user found for $formattedPhoneNumber");
//               }
//             } catch (e) {
//               print("Error fetching user from Firestore: $e");
//             }
//           }
//         }
//       }

//       // Sauvegarde du statut dans Firestore
//       List<String> statusImageUrls = [];
//       var statusSnapshot = await firestore
//           .collection('status')
//           .where('uid', isEqualTo: uid)
//           .get();

//       if (statusSnapshot.docs.isNotEmpty) {
//         Status status = Status.fromMap(statusSnapshot.docs[0].data());
//         statusImageUrls = status.photoUrl;
//         statusImageUrls.add(imageUrl);
//         await firestore
//             .collection('status')
//             .doc(statusSnapshot.docs[0].id)
//             .update({'photoUrl': statusImageUrls});
//         print("Status updated with new image URL.");
//       } else {
//         // Créer un nouveau statut
//         statusImageUrls = [imageUrl];
//         Status status = Status(
//           uid: uid,
//           username: username,
//           phoneNumber: phoneNumber,
//           profilePic: profilePic,
//           statusId: statusId,
//           createdAt: DateTime.now(),
//           photoUrl: statusImageUrls,
//           whoCanSee: uidWhoCanSee,
//         );
//         // Après la sauvegarde dans Firestore
//         await firestore
//             .collection('status')
//             .doc(statusId)
//             .set(status.toMap())
//             .then((_) {
//           showAlertDialog(
//               context: context, message: 'Status added successfully');
//         }).catchError((error) {
//           print("Error saving status to Firestore: $error");
//           showAlertDialog(context: context, message: error.toString());
//         });
//       }

//       Navigator.pushNamed(context, Routes.status);
//     } catch (e) {
//       print("Error uploading status: $e");
//       showAlertDialog(
//         context: context,
//         message: 'Error uploading status: ${e.toString()}',
//       );
//     }
//   }

//   Future<List<Status>> getStatus(BuildContext context) async {
//     List<Status> statusData = [];
//     try {
//       showAlertDialog(
//           context: context, message: "Requesting contacts permission");
//       List<Contact> contacts = [];
//       if (await FlutterContacts.requestPermission()) {
//         showAlertDialog(
//             context: context, message: "Contacts permission granted");
//         contacts = await FlutterContacts.getContacts(withProperties: true);
//         showAlertDialog(
//             context: context, message: "Loaded contacts: ${contacts.length}");
//       } else {
//         showAlertDialog(
//             context: context, message: 'Contacts permission denied');
//         return statusData; // ou montrez une alerte
//       }

//       // Vérifiez si la liste des contacts est vide
//       if (contacts.isEmpty) {
//         showAlertDialog(context: context, message: "No contacts found.");
//         return statusData;
//       }

//       // Créer une liste de numéros de téléphone pour une requête groupée
//       List<String> phoneNumbers = [];
//       for (var contact in contacts) {
//         if (contact.phones.isNotEmpty) {
//           var phoneNumber = contact.phones[0].number.replaceAll(' ', '');
//           if (phoneNumber.isNotEmpty) {
//             phoneNumbers.add(phoneNumber);
//           }
//         }
//       }

//       // Si aucune numéro de téléphone n'est disponible, retournez directement
//       if (phoneNumbers.isEmpty) {
//         showAlertDialog(
//             context: context, message: "No phone numbers available.");
//         return statusData;
//       }

//       // Divisez la liste de numéros de téléphone en sous-listes de 30 éléments maximum
//       List<List<String>> phoneNumberChunks = splitList(phoneNumbers, 30);

//       // Exécuter une requête pour chaque sous-liste
//       for (var chunk in phoneNumberChunks) {
//         try {
//           var statusSnapshot = await firestore
//               .collection('status')
//               .where('phoneNumber', whereIn: chunk)
//               .where('createdAt',
//                   isGreaterThan: DateTime.now()
//                       .subtract(const Duration(hours: 24))
//                       .millisecondsSinceEpoch)
//               .get();

//           // Traitez les statuts récupérés
//           for (var tempData in statusSnapshot.docs) {
//             Status tempStatus = Status.fromMap(tempData.data());
//             if (tempStatus.whoCanSee.contains(auth.currentUser!.uid)) {
//               statusData.add(tempStatus);
//             }
//           }
//         } catch (e) {
//           showAlertDialog(
//               context: context,
//               message: "Error fetching status for chunk: $chunk, error: $e");
//         }
//       }

//       for (var contact in contacts) {
//         if (contact.phones.isNotEmpty) {
//           var phoneNumber = contact.phones[0].number.replaceAll(' ', '');
//           if (phoneNumber.isNotEmpty) {
//             // Vérifier si l'UID est déjà dans le cache
//             String? cachedUid = _phoneNumberCache.getUidFromCache(phoneNumber);
//             if (cachedUid == null) {
//               try {
//                 var userDataFirebase = await firestore
//                     .collection('users')
//                     .where('phonenumber', isEqualTo: phoneNumber)
//                     .get();

//                 if (userDataFirebase.docs.isNotEmpty) {
//                   var userData =
//                       UserModel.fromMap(userDataFirebase.docs[0].data());
//                   // Ajouter au cache
//                   _phoneNumberCache.addPhoneNumberToCache(
//                       phoneNumber, userData.uid);
//                   showAlertDialog(
//                       context: context,
//                       message:
//                           "User UID cached for $phoneNumber: ${userData.uid}");
//                 }
//               } catch (e) {
//                 showAlertDialog(
//                     context: context,
//                     message: "Error adding UID to cache for $phoneNumber: $e");
//               }
//             }
//           }
//         }
//       }
//     } catch (e) {
//       showAlertDialog(
//           context: context, message: 'Error fetching status: ${e.toString()}');
//     }

//     return statusData;
//   }

//   List<List<String>> splitList(List<String> phoneNumbers, int chunkSize) {
//     List<List<String>> chunks = [];
//     for (var i = 0; i < phoneNumbers.length; i += chunkSize) {
//       chunks.add(phoneNumbers.sublist(
//           i,
//           i + chunkSize > phoneNumbers.length
//               ? phoneNumbers.length
//               : i + chunkSize));
//     }
//     return chunks;
//   }
// }

// import 'dart:io';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:tuyage/common/models/status_model.dart';
// import 'package:tuyage/feature/auth/controller/auth_controller.dart';
// import 'package:tuyage/feature/status/repository/status_repository.dart';

// final statusControllerProvider = Provider((ref) {
//   final statusRepository = ref.read(statusRepositoryProvider);
//   return StatusController(
//     ref: ref,
//     statusRepository: statusRepository,
//   );
// });

// class StatusController {
//   final StatusRepository statusRepository;
//   final ProviderRef ref;

//   StatusController({required this.ref, required this.statusRepository});

//   addStatus(File file, BuildContext context) {
//     ref.watch(userInfoAuthProvider).whenData((value) {
//       statusRepository.uploadStatus(
//         username: value!.username,
//         profilePic: value.profileImageUrl ?? '',
//         phoneNumber: value.phoneNumber,
//         statusImage: file,
//         context: context,
//       );
//     });
//   }

//   Future<List<Status>> getStatus(BuildContext context) async {
//     List<Status> statuses = await statusRepository.getStatus(context);
//     return statuses;
//   }
// }

// import 'dart:io';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter/material.dart';
// import 'package:tuyage/common/utils/coloors.dart';
// import 'package:tuyage/feature/status/controller/status_controller.dart';

// class ConfirmStatusScreen extends ConsumerStatefulWidget {
//   final File file;

//   const ConfirmStatusScreen({Key? key, required this.file}) : super(key: key);

//   @override
//   _ConfirmStatusScreenState createState() => _ConfirmStatusScreenState();
// }

// class _ConfirmStatusScreenState extends ConsumerState<ConfirmStatusScreen> {
//   bool isLoading = false;

//   Future<void> addStatus(WidgetRef ref, BuildContext context) async {
//     setState(() {
//       isLoading =
//           true; // Met à jour l'état pour afficher le dialogue de chargement
//     });

//     // Affiche un dialogue de chargement
//     final loadingDialog = showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       await ref.read(statusControllerProvider).addStatus(widget.file, context);
//       Navigator.pop(context); // Ferme le dialogue de chargement
//       Navigator.pop(context); // Ferme l'écran de confirmation
//     } catch (e) {
//       Navigator.pop(context); // Ferme le dialogue de chargement
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Error'),
//           content: Text(e.toString()),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context); // Ferme le dialogue d'erreur
//                 setState(() {
//                   isLoading = false; // Restaure l'état de chargement
//                 });
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         ),
//       );
//     } finally {
//       // Assurez-vous que l'état de chargement est réinitialisé même si une erreur se produit
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: isLoading
//             ? const CircularProgressIndicator()
//             : AspectRatio(
//                 aspectRatio: 9 / 16,
//                 child: Image.file(widget.file),
//               ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: isLoading
//             ? null
//             : () => addStatus(
//                 ref, context), // Désactivez le bouton pendant le chargement
//         child: const Icon(
//           Icons.done,
//           color: Colors.white,
//         ),
//         backgroundColor: Coloors.greenDark,
//       ),
//     );
//   }
// }
