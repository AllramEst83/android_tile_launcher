import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/services/mail_service.dart';

/// Serves [result] for `latest` and keeps the account it was set up with, so a
/// tile and its sheets can be tested without a server.
class FakeMailService implements MailService {
  FakeMailService([this.result = const MailNotSetUp()]);

  MailResult result;

  /// What `setUp` answers: null for success, else the reason it failed.
  String? setUpProblem;

  MailAccountInfo? saved;

  /// Every `(email, host, password)` given to `setUp`, in order.
  final List<(String, String, String)> setUps = <(String, String, String)>[];

  /// The `count` of every `latest` call, in order, and how many of them were
  /// `fresh`.
  final List<int> counts = <int>[];
  int freshCalls = 0;

  int forgets = 0;

  /// What `moveToTrash` answers.
  MailMoveResult moveResult = const MailMoved('Trash');

  /// Every `(uid, validity)` given to `moveToTrash`, in order.
  final List<(int, int?)> moves = <(int, int?)>[];

  @override
  Future<MailAccountInfo?> account() async => saved;

  @override
  Future<String?> setUp({
    required String email,
    required String host,
    required String password,
  }) async {
    setUps.add((email, host, password));
    if (setUpProblem == null) {
      saved = MailAccountInfo(email: email, host: host);
    }
    return setUpProblem;
  }

  @override
  Future<bool> forget() async {
    forgets++;
    final bool had = saved != null;
    saved = null;
    return had;
  }

  @override
  Future<MailMoveResult> moveToTrash(int uid, {int? validity}) async {
    moves.add((uid, validity));
    return moveResult;
  }

  @override
  Future<MailResult> latest({int count = 20, bool fresh = false}) async {
    counts.add(count);
    if (fresh) freshCalls++;
    return result;
  }
}
