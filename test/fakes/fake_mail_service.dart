import 'dart:async';

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
  Future<MailMoveResult> moveToTrash(
    int uid, {
    int? validity,
    String? folder,
  }) async {
    moves.add((uid, validity));
    folderArgs.add(folder);
    return moveResult;
  }

  /// The `folder` of every `moveToTrash`, `read`, `mark` and `star` call.
  final List<String?> folderArgs = <String?>[];

  /// What `folders` answers.
  List<MailFolder> folderList = const <MailFolder>[];

  @override
  Future<List<MailFolder>> folders() async => folderList;

  /// Answers for `latest` / `search` by folder (null is the inbox), before
  /// falling back to [result]; and every `(folder, offset, withStarred)`.
  final Map<String?, MailResult> folderResults = <String?, MailResult>{};
  final List<(String?, int, bool)> latestCalls = <(String?, int, bool)>[];

  /// Answers for `latest` by offset, before falling back (a later page).
  final Map<int, MailResult> pageResults = <int, MailResult>{};

  @override
  Future<MailResult> latest({
    int count = 20,
    bool fresh = false,
    int offset = 0,
    String? folder,
    bool withStarred = false,
  }) async {
    counts.add(count);
    latestCalls.add((folder, offset, withStarred));
    if (fresh) freshCalls++;
    return pageResults[offset] ?? folderResults[folder] ?? result;
  }

  /// What `search` answers, and every filter it was given, in order.
  MailResult? searchResult;
  final List<MailFilter> searches = <MailFilter>[];

  @override
  Future<MailResult> search(
    MailFilter filter, {
    int count = 20,
    int offset = 0,
    String? folder,
  }) async {
    searches.add(filter);
    return searchResult ?? result;
  }

  /// What `read` answers, and every `(uid, validity)` it was given.
  MailReadResult readResult = const MailReadGone();

  /// When set, `read` waits for it: a message that is still opening.
  Completer<void>? readGate;

  /// Answers for particular uids, before falling back to [readResult].
  final Map<int, MailReadResult> readResults = <int, MailReadResult>{};
  final List<(int, int?)> reads = <(int, int?)>[];

  /// What `mark` answers, and every `(uid, read, validity)` it was given.
  MailMarkResult? markResult;
  final List<(int, bool, int?)> marks = <(int, bool, int?)>[];

  @override
  Future<MailReadResult> read(int uid, {int? validity, String? folder}) async {
    reads.add((uid, validity));
    folderArgs.add(folder);
    await readGate?.future;
    return readResults[uid] ?? readResult;
  }

  @override
  Future<MailMarkResult> mark(
    int uid, {
    required bool read,
    int? validity,
    String? folder,
  }) async {
    marks.add((uid, read, validity));
    folderArgs.add(folder);
    return markResult ?? MailMarked(read: read);
  }

  /// What `star` answers, and every `(uid, starred, validity)` it was given.
  MailStarResult? starResult;
  final List<(int, bool, int?)> stars = <(int, bool, int?)>[];

  @override
  Future<MailStarResult> star(
    int uid, {
    required bool starred,
    int? validity,
    String? folder,
  }) async {
    stars.add((uid, starred, validity));
    folderArgs.add(folder);
    return starResult ?? MailStarred(starred: starred);
  }

  /// What `send` answers, and every `(to, cc, subject, text)` it was given.
  MailSendResult sendResult = const MailSent();
  final List<(List<String>, List<String>, String, String)> sent =
      <(List<String>, List<String>, String, String)>[];

  @override
  Future<MailSendResult> send({
    required List<String> to,
    List<String> cc = const <String>[],
    required String subject,
    required String text,
  }) async {
    sent.add((to, cc, subject, text));
    return sendResult;
  }
}
