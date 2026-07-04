enum UpdateStatus { upToDate, outdated, restartRequired, unavailable }

class UpdateTrack {
  const UpdateTrack(this.name);

  final String name;
}

class Patch {
  const Patch({required this.number});

  final int number;
}

class ShorebirdUpdater {
  Future<UpdateStatus> checkForUpdate({UpdateTrack? track}) async {
    return UpdateStatus.unavailable;
  }

  Future<void> update({UpdateTrack? track}) async {}

  Future<Patch?> readCurrentPatch() async => null;
}
