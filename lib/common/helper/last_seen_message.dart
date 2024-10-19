String lastSeenMessage(int lastSeen) {
  DateTime now = DateTime.now();
  DateTime lastSeenTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);

  Duration differenceDuration = now.difference(lastSeenTime);

  String finalMessage = differenceDuration.inSeconds > 59
      ? differenceDuration.inMinutes > 59
          ? differenceDuration.inHours > 23
              ? " ${differenceDuration.inDays == 1 ? 'umunsi' : 'iminsi'} ${differenceDuration.inDays}"
              : " ${differenceDuration.inHours == 1 ? 'isaha' : 'amasaha'} ${differenceDuration.inHours}"
          : " ${differenceDuration.inMinutes == 1 ? 'umunota' : 'iminota'} ${differenceDuration.inMinutes}"
      : 'umwanya muto';

  return finalMessage;
}
