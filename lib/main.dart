import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const url = String.fromEnvironment('SUPABASE_URL');
const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
bool get connected => url.isNotEmpty && key.isNotEmpty;
const red = Color(0xFFB32632);
const dark = Color(0xFF191B20);
const grey = Color(0xFF74777D);
const paper = Color(0xFFF6F5F2);
String tr(bool am, String en, String amh) => am ? amh : en;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (connected) await Supabase.initialize(url: url, publishableKey: key);
  runApp(const WarkaApp());
}

class WarkaApp extends StatefulWidget {
  const WarkaApp({super.key});
  @override
  State<WarkaApp> createState() => _WarkaAppState();
}
class _WarkaAppState extends State<WarkaApp> {
  bool am = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Warka News',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: red, surface: paper),
      appBarTheme: const AppBarTheme(backgroundColor: paper, foregroundColor: dark, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E3DF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E3DF))),
      ),
    ),
    home: WarkaHome(am: am, changeLanguage: () => setState(() => am = !am)),
  );
}

class Story {
  const Story(this.id, this.category, this.en, this.amh, this.bodyEn, this.bodyAm, {this.sample = false});
  final String id, category, en, amh, bodyEn, bodyAm;
  final bool sample;
  factory Story.fromMap(Map<String, dynamic> m) => Story(
    m['id'].toString(), (m['category'] ?? 'NEWS').toString(),
    (m['title_en'] ?? '').toString(), (m['title_am'] ?? '').toString(),
    (m['body_en'] ?? '').toString(), (m['body_am'] ?? '').toString(),
  );
}
const sampleStories = <Story>[
  Story('intro', 'WELCOME', 'Welcome to Warka News', 'ወደ ዋርካ ዜና በደህና መጡ',
    'Warka brings timely reporting, useful information and voices from communities across Ethiopia. Published reports will appear here when the newsroom connects its publishing account.',
    'ዋርካ ወቅታዊ ዘገባዎችን፣ ጠቃሚ መረጃዎችን እና የማህበረሰቦችን ድምፅ ያቀርባል። የዜና ክፍሉ ሲገናኝ የታተሙ ዘገባዎች እዚህ ይታያሉ።', sample: true),
  Story('voice', 'COMMUNITY', 'Your voice matters', 'ድምፅዎ ዋጋ አለው',
    'Have information about a developing story? Send a tip to the newsroom. Information should be checked before publication.',
    'ስለ እየተከሰተ ያለ ጉዳይ መረጃ አለዎት? ለዜና ክፍሉ ይላኩ። መረጃው ከመታተሙ በፊት መረጋገጥ አለበት።', sample: true),
];

class WarkaHome extends StatefulWidget {
  const WarkaHome({required this.am, required this.changeLanguage, super.key});
  final bool am;
  final VoidCallback changeLanguage;
  @override
  State<WarkaHome> createState() => _WarkaHomeState();
}
class _WarkaHomeState extends State<WarkaHome> {
  int tab = 0;
  final saved = <String>{};
  void toggle(String id) => setState(() { if (!saved.add(id)) saved.remove(id); });
  @override
  Widget build(BuildContext context) {
    final am = widget.am;
    return Scaffold(
      appBar: AppBar(title: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: red, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.bolt, color: Colors.white)),
        const SizedBox(width: 10),
        const Text('WARKA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 21)),
      ]), actions: [TextButton(onPressed: widget.changeLanguage, child: Text(am ? 'ENGLISH' : 'አማርኛ', style: const TextStyle(color: red, fontWeight: FontWeight.w800))), const SizedBox(width: 8)]),
      body: SafeArea(child: IndexedStack(index: tab, children: [
        NewsPage(am: am, saved: saved, onSave: toggle),
        TipPage(am: am),
        MessagePage(am: am),
        SavedPage(am: am, saved: saved, onSave: toggle),
      ])),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white, selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: tr(am, 'Home', 'ዋና')),
          NavigationDestination(icon: const Icon(Icons.send_outlined), label: tr(am, 'News tip', 'መረጃ')),
          NavigationDestination(icon: const Icon(Icons.mail_outline), label: tr(am, 'Contact', 'ያግኙን')),
          NavigationDestination(icon: const Icon(Icons.bookmark_border), label: tr(am, 'Saved', 'የተቀመጡ')),
        ],
      ),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({required this.am, required this.saved, required this.onSave, super.key});
  final bool am;
  final Set<String> saved;
  final ValueChanged<String> onSave;
  @override
  State<NewsPage> createState() => _NewsPageState();
}
class _NewsPageState extends State<NewsPage> {
  final search = TextEditingController();
  String category = 'ALL';
  late Future<List<Story>> feed;
  @override
  void initState() { super.initState(); feed = loadFeed(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }
  Future<List<Story>> loadFeed() async {
    if (!connected) return sampleStories;
    try {
      final rows = await Supabase.instance.client.from('articles').select('id,category,title_en,title_am,body_en,body_am').eq('published', true).order('created_at', ascending: false);
      return (rows as List).map((e) => Story.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return sampleStories; }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Story>>(
    future: feed,
    builder: (context, snapshot) {
      final all = snapshot.data ?? sampleStories;
      final q = search.text.toLowerCase().trim();
      final list = all.where((s) => (category == 'ALL' || s.category.toUpperCase() == category) && (q.isEmpty || (s.en + s.amh + s.bodyEn + s.bodyAm).toLowerCase().contains(q))).toList();
      return RefreshIndicator(color: red, onRefresh: () async { setState(() => feed = loadFeed()); await feed; }, child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 25), children: [
        Container(padding: const EdgeInsets.all(21), decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr(widget.am, 'ETHIOPIA  •  NEWSROOM', 'ኢትዮጵያ  •  ዜና'), style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 14),
          Text(tr(widget.am, 'The stories that matter.', 'አስፈላጊ ዜናዎች።'), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.15)),
          const SizedBox(height: 8),
          Text(tr(widget.am, 'Independent voices. Local perspective.', 'ገለልተኛ ድምፆች። የአካባቢ እይታ።'), style: const TextStyle(color: Color(0xFFD7D7D7), fontSize: 13)),
        ])),
        const SizedBox(height: 19),
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: tr(widget.am, 'Search stories', 'ዜና ይፈልጉ'), prefixIcon: const Icon(Icons.search), suffixIcon: search.text.isEmpty ? null : IconButton(onPressed: () { search.clear(); setState(() {}); }, icon: const Icon(Icons.close)))),
        const SizedBox(height: 19),
        Row(children: [Expanded(child: Text(tr(widget.am, 'LATEST STORIES', 'አዳዲስ ዘገባዎች'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), if (snapshot.connectionState == ConnectionState.waiting) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))]),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['ALL', 'POLITICS', 'ECONOMY', 'COMMUNITY', 'SPORTS', 'WORLD'].map((c) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(c == 'ALL' ? tr(widget.am, 'All', 'ሁሉም') : c), selected: category == c, onSelected: (_) => setState(() => category = c), selectedColor: red, backgroundColor: Colors.white, labelStyle: TextStyle(color: category == c ? Colors.white : dark, fontSize: 10, fontWeight: FontWeight.w800)))).toList())),
        const SizedBox(height: 12),
        if (list.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(30), child: Text(tr(widget.am, 'No stories found.', 'ዜና አልተገኘም።')))),
        ...list.map((s) => StoryCard(story: s, am: widget.am, saved: widget.saved.contains(s.id), onSave: () => widget.onSave(s.id), onOpen: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => StoryPage(story: s, am: widget.am))))),
        if (all.every((s) => s.sample)) Padding(padding: const EdgeInsets.only(top: 8), child: Text(tr(widget.am, 'Sample content is shown until the newsroom publishes real articles.', 'የዜና ክፍሉ እውነተኛ ዘገባዎችን እስኪያትም ድረስ የሙከራ ይዘት ይታያል።'), style: const TextStyle(color: grey, fontSize: 11))),
      ]));
    },
  );
}

class StoryCard extends StatelessWidget {
  const StoryCard({required this.story, required this.am, required this.saved, required this.onSave, required this.onOpen, super.key});
  final Story story;
  final bool am, saved;
  final VoidCallback onSave, onOpen;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 11),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: Color(0xFFEAE8E4))),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onOpen, child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(6)), child: Text(story.category.toUpperCase(), style: const TextStyle(color: red, fontSize: 9, fontWeight: FontWeight.w900))),
        const Spacer(),
        if (story.sample) Text(tr(am, 'SAMPLE', 'ምሳሌ'), style: const TextStyle(color: grey, fontSize: 9)),
        IconButton(visualDensity: VisualDensity.compact, onPressed: onSave, icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? red : grey)),
      ]),
      Text(am ? story.amh : story.en, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, height: 1.25)),
      const SizedBox(height: 7),
      Text(am ? story.bodyAm : story.bodyEn, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: grey, fontSize: 12, height: 1.5)),
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerRight, child: Text(tr(am, 'READ STORY  ›', 'ያንብቡ  ›'), style: const TextStyle(color: red, fontWeight: FontWeight.w900, fontSize: 10))),
    ]))),
  );
}

class StoryPage extends StatelessWidget {
  const StoryPage({required this.story, required this.am, super.key});
  final Story story;
  final bool am;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('WARKA')), body: ListView(padding: const EdgeInsets.all(21), children: [
    Text(story.category, style: const TextStyle(color: red, fontWeight: FontWeight.w900)),
    const SizedBox(height: 14),
    Text(am ? story.amh : story.en, style: const TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w900)),
    const Divider(height: 35),
    Text(am ? story.bodyAm : story.bodyEn, style: const TextStyle(fontSize: 16, height: 1.8)),
    if (story.sample) Padding(padding: const EdgeInsets.only(top: 22), child: Text(tr(am, 'This is sample content, not a current news report.', 'ይህ የሙከራ ይዘት ነው።'), style: const TextStyle(color: grey, fontSize: 12))),
    const SizedBox(height: 20),
    OutlinedButton.icon(onPressed: () async { await Clipboard.setData(ClipboardData(text: (am ? story.amh : story.en) + '\n\n' + (am ? story.bodyAm : story.bodyEn))); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(am, 'Copied.', 'ተቀድቷል።')))); }, icon: const Icon(Icons.copy), label: Text(tr(am, 'Copy story', 'ዜናውን ቅዳ'))),
  ]));
}

class TipPage extends StatefulWidget {
  const TipPage({required this.am, super.key});
  final bool am;
  @override
  State<TipPage> createState() => _TipPageState();
}
class _TipPageState extends State<TipPage> {
  final form = GlobalKey<FormState>();
  final subject = TextEditingController(), details = TextEditingController(), contact = TextEditingController();
  bool anonymous = false, sending = false;
  XFile? media;
  @override
  void dispose() { subject.dispose(); details.dispose(); contact.dispose(); super.dispose(); }
  Future<void> pick() async { final file = await ImagePicker().pickMedia(); if (file != null && mounted) setState(() => media = file); }
  void notice(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  Future<void> submit() async {
    final am = widget.am;
    if (!(form.currentState?.validate() ?? false)) return;
    if (!connected) { notice(tr(am, 'Newsroom submissions are not connected yet.', 'የዜና ክፍሉ ገና አልተገናኘም።')); return; }
    setState(() => sending = true);
    try {
      String? path;
      if (media != null) {
        final f = media!;
        final ext = f.name.contains('.') ? f.name.split('.').last : 'bin';
        path = 'tips/' + DateTime.now().microsecondsSinceEpoch.toString() + '.' + ext;
        await Supabase.instance.client.storage.from('news-tips').uploadBinary(path, await f.readAsBytes());
      }
      await Supabase.instance.client.from('news_tips').insert({'subject': subject.text.trim(), 'message': details.text.trim(), 'contact': anonymous ? null : contact.text.trim(), 'is_anonymous': anonymous, 'media_path': path});
      subject.clear(); details.clear(); contact.clear();
      if (mounted) setState(() => media = null);
      notice(tr(am, 'Your tip was sent to the newsroom.', 'መረጃዎ ተልኳል።'));
    } catch (_) { notice(tr(am, 'Could not send. Please try again later.', 'መላክ አልተቻለም። ቆይተው ይሞክሩ።')); }
    finally { if (mounted) setState(() => sending = false); }
  }
  @override
  Widget build(BuildContext context) => Form(key: form, child: ListView(padding: const EdgeInsets.all(20), children: [
    heading(widget.am, Icons.campaign_outlined, 'Send a news tip', 'የዜና መረጃ ይላኩ'),
    const SizedBox(height: 8),
    Text(tr(widget.am, 'Share what you know. The newsroom reviews submissions before publication.', 'የሚያውቁትን ያጋሩ። ዜና ክፍሉ ከማተሙ በፊት ይመረምረዋል።'), style: const TextStyle(color: grey)),
    const SizedBox(height: 20),
    TextFormField(controller: subject, decoration: InputDecoration(labelText: tr(widget.am, 'Subject', 'ርዕስ')), validator: (v) => v == null || v.trim().isEmpty ? tr(widget.am, 'Enter a subject', 'ርዕስ ያስገቡ') : null),
    const SizedBox(height: 12),
    TextFormField(controller: details, minLines: 5, maxLines: 8, decoration: InputDecoration(labelText: tr(widget.am, 'What happened? Include place and time.', 'ምን ተፈጠረ? ቦታና ሰዓት ይጨምሩ።'), alignLabelWithHint: true), validator: (v) => v == null || v.trim().length < 10 ? tr(widget.am, 'Add more detail', 'ተጨማሪ ዝርዝር ያስገቡ') : null),
    SwitchListTile(contentPadding: EdgeInsets.zero, value: anonymous, onChanged: (v) => setState(() => anonymous = v), title: Text(tr(widget.am, 'Send anonymously', 'ስም ሳይጠቅሱ ይላኩ'))),
    if (!anonymous) TextField(controller: contact, decoration: InputDecoration(labelText: tr(widget.am, 'Contact (optional)', 'መገኛ (አማራጭ)'))),
    const SizedBox(height: 12),
    OutlinedButton.icon(onPressed: pick, icon: const Icon(Icons.attach_file), label: Text(media == null ? tr(widget.am, 'Attach photo or video', 'ፎቶ ወይም ቪዲዮ ያያይዙ') : media!.name)),
    const SizedBox(height: 18),
    FilledButton(onPressed: sending ? null : submit, style: FilledButton.styleFrom(backgroundColor: red, padding: const EdgeInsets.all(16)), child: sending ? const CircularProgressIndicator(color: Colors.white) : Text(tr(widget.am, 'Send to newsroom', 'ለዜና ክፍሉ ይላኩ'))),
    const SizedBox(height: 12),
    Text(tr(widget.am, 'Do not send material that could put you or another person at risk. Information must be verified before publication.', 'ሰውን አደጋ ላይ የሚጥል መረጃ አይላኩ። ከመታተሙ በፊት መረጃው መረጋገጥ አለበት።'), style: const TextStyle(color: grey, fontSize: 11)),
  ]));
}

class MessagePage extends StatefulWidget {
  const MessagePage({required this.am, super.key});
  final bool am;
  @override
  State<MessagePage> createState() => _MessagePageState();
}
class _MessagePageState extends State<MessagePage> {
  final name = TextEditingController(), contact = TextEditingController(), message = TextEditingController();
  bool sending = false;
  @override
  void dispose() { name.dispose(); contact.dispose(); message.dispose(); super.dispose(); }
  Future<void> send() async {
    final am = widget.am;
    if (message.text.trim().length < 3) { notice(tr(am, 'Write a message first.', 'መጀመሪያ መልዕክት ይጻፉ።')); return; }
    if (!connected) { notice(tr(am, 'Publisher messaging is not connected yet.', 'የአሳታሚው መልዕክት አገልግሎት ገና አልተገናኘም።')); return; }
    setState(() => sending = true);
    try {
      await Supabase.instance.client.from('publisher_messages').insert({'sender_name': name.text.trim(), 'contact': contact.text.trim(), 'message': message.text.trim()});
      message.clear(); notice(tr(am, 'Message sent to the publisher.', 'መልዕክቱ ተልኳል።'));
    } catch (_) { notice(tr(am, 'Could not send. Please try again later.', 'መላክ አልተቻለም።')); }
    finally { if (mounted) setState(() => sending = false); }
  }
  void notice(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    heading(widget.am, Icons.mail_outline, 'Contact the publisher', 'አሳታሚውን ያነጋግሩ'),
    const SizedBox(height: 8),
    Text(tr(widget.am, 'Send a private message to the Warka newsroom.', 'ለዋርካ ዜና ክፍል የግል መልዕክት ይላኩ።'), style: const TextStyle(color: grey)),
    const SizedBox(height: 20),
    TextField(controller: name, decoration: InputDecoration(labelText: tr(widget.am, 'Name (optional)', 'ስም (አማራጭ)'))),
    const SizedBox(height: 12),
    TextField(controller: contact, decoration: InputDecoration(labelText: tr(widget.am, 'Phone or email (optional)', 'ስልክ ወይም ኢሜይል'))),
    const SizedBox(height: 12),
    TextField(controller: message, minLines: 5, maxLines: 8, decoration: InputDecoration(labelText: tr(widget.am, 'Your message', 'መልዕክትዎ'))),
    const SizedBox(height: 18),
    FilledButton(onPressed: sending ? null : send, style: FilledButton.styleFrom(backgroundColor: red, padding: const EdgeInsets.all(16)), child: Text(tr(widget.am, 'Send message', 'መልዕክት ይላኩ'))),
  ]);
}

class SavedPage extends StatelessWidget {
  const SavedPage({required this.am, required this.saved, required this.onSave, super.key});
  final bool am;
  final Set<String> saved;
  final ValueChanged<String> onSave;
  @override
  Widget build(BuildContext context) {
    final items = sampleStories.where((s) => saved.contains(s.id)).toList();
    return ListView(padding: const EdgeInsets.all(20), children: [
      heading(am, Icons.bookmark_outline, 'Saved stories', 'የተቀመጡ ዜናዎች'),
      const SizedBox(height: 15),
      if (items.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(30), child: Text(tr(am, 'Stories you save will appear here.', 'ያስቀመጧቸው ዜናዎች እዚህ ይታያሉ።'), style: const TextStyle(color: grey)))),
      ...items.map((s) => StoryCard(story: s, am: am, saved: true, onSave: () => onSave(s.id), onOpen: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => StoryPage(story: s, am: am))))),
    ]);
  }
}

Widget heading(bool am, IconData icon, String en, String amh) => Row(children: [
  Container(width: 43, height: 43, decoration: BoxDecoration(color: const Color(0xFFFFE9E9), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: red)),
  const SizedBox(width: 12),
  Expanded(child: Text(tr(am, en, amh), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
]);
