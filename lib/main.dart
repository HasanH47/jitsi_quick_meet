import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JitsiQuickMeetApp());
}

class JitsiQuickMeetApp extends StatelessWidget {
  const JitsiQuickMeetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jitsi Quick Meet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          isDense: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final roomCtrl = TextEditingController(text: "dev-standup");
  final nameCtrl = TextEditingController(text: "Hasan");
  final serverCtrl = TextEditingController(); // kosong = pakai meet.jit.si
  final _formKey = GlobalKey<FormState>();

  bool micMuted = false;
  bool camOff = false;
  bool _joining = false;

  final _jitsiMeet = JitsiMeet();

  @override
  void dispose() {
    roomCtrl.dispose();
    nameCtrl.dispose();
    serverCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _joining = true);

    final room = roomCtrl.text.trim();
    final displayName = nameCtrl.text.trim();
    final server = serverCtrl.text.trim();

    final options = JitsiMeetConferenceOptions(
      room: room,
      serverURL: server.isEmpty ? null : server,
      // Kosong => default publik: https://meet.jit.si
      configOverrides: {
        // Nonaktifkan prejoin page biar langsung masuk
        "prejoinPageEnabled": false,
        // Mulai dalam kondisi sesuai toggle
        "startWithAudioMuted": micMuted,
        "startWithVideoMuted": camOff,
        // Optimasi default
        "disableDeepLinking": true,
      },
      featureFlags: {
        "welcomepage.enabled": false,
        "pip.enabled": true,
        "invite.enabled": true,
        "raise-hand.enabled": true,
        // Opsional: hilangkan peringatan room tidak aman di server publik
        "unsaferoomwarning.enabled": false,
      },
      userInfo: JitsiMeetUserInfo(displayName: displayName),
    );

    try {
      await _jitsiMeet.join(options);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal join: $e")));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  String? _validateRoom(String? v) {
    final value = (v ?? "").trim();
    if (value.isEmpty) return "Room ID tidak boleh kosong";
    // Validasi sederhana: huruf, angka, dash, underscore, titik
    final ok = RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value);
    if (!ok) return "Hanya huruf/angka/._- yang diperbolehkan";
    return null;
  }

  String? _validateName(String? v) {
    final value = (v ?? "").trim();
    if (value.isEmpty) return "Nama tampilan tidak boleh kosong";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pad = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    return Scaffold(
      appBar: AppBar(title: const Text('Jitsi Quick Meet'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth > 720 ? 560.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.video_call_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Mulai/Join Meeting",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: roomCtrl,
                              decoration: const InputDecoration(
                                labelText: "Room ID",
                                hintText: "mis. team-sync-123",
                                prefixIcon: Icon(Icons.meeting_room_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9._-]'),
                                ),
                              ],
                              validator: _validateRoom,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: "Nama tampilan",
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: _validateName,
                            ),
                            const SizedBox(height: 12),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              title: const Text(
                                "Pengaturan lanjutan (opsional)",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              children: [
                                Padding(
                                  padding: pad,
                                  child: TextField(
                                    controller: serverCtrl,
                                    decoration: InputDecoration(
                                      labelText: "Custom Server URL (opsional)",
                                      hintText:
                                          "https://meet.jit.si atau https://your.jitsi.server",
                                      prefixIcon: const Icon(
                                        Icons.cloud_outlined,
                                      ),
                                      suffixIcon: serverCtrl.text.isEmpty
                                          ? null
                                          : IconButton(
                                              tooltip: "Kosongkan",
                                              onPressed: () {
                                                serverCtrl.clear();
                                                setState(() {});
                                              },
                                              icon: const Icon(Icons.clear),
                                            ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    "Mute mic saat join meeting",
                                  ),
                                  subtitle: const Text(
                                    "startWithAudioMuted = true",
                                  ),
                                  value: micMuted,
                                  onChanged: (v) =>
                                      setState(() => micMuted = v),
                                  secondary: const Icon(Icons.mic_off_outlined),
                                ),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    "Matikan kamera saat join meeting",
                                  ),
                                  subtitle: const Text(
                                    "startWithVideoMuted = true",
                                  ),
                                  value: camOff,
                                  onChanged: (v) => setState(() => camOff = v),
                                  secondary: const Icon(
                                    Icons.videocam_off_outlined,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: _joining
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.videocam),
                                label: Text(
                                  _joining
                                      ? "Menghubungkan..."
                                      : "Join Meeting",
                                ),
                                onPressed: _joining ? null : _join,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tips: biarkan Server URL kosong untuk memakai server publik Jitsi (meet.jit.si). "
                    "Untuk produksi, sangat disarankan memakai server Jitsi sendiri.",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
