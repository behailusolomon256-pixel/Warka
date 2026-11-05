import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
bool get backendReady => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (backendReady) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  }
  runApp(const WarkaApp());
}

class WarkaApp extends StatefulWidget {
  const WarkaApp({super.key});
  @override
  State<WarkaApp> createState() => _WarkaAppState();
}
class _WarkaAppState extends State<WarkaApp> {
  bool amharic = false;
  void toggleLanguage() => setState(() => amharic = !amharic);
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Warka News',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFAF9F6),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB51F2A)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFAF9F6), elevation: 0),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
    home: AppShell(amharic: amharic, onLanguage: toggleLanguage),
  );
}

String tr(bool am, String en, String ah) => am ? ah : en;

class AppShell extends StatefulWidget {
  final bool amharic;
  final VoidCallback onLanguage;
  const AppShell({super.key, required this.amharic, required this.onLanguage});
  @override
  State<AppShell> createState() => _AppShellState();
}
class _AppShellState extends State<AppShell> {
  int tab = 0;
  final saved = <String>{};
  @override
  Widget build(BuildContext context) {
    final am = widget.amharic;
    final pages = [
      HomePage(am: am, saved: saved, onSave: (id) => setState(() => saved.contains(id) ? saved.remove(id) : saved.add(id))),
      TipPage(am: am),
      MessagePage(am: am),
      SavedPage(am: am, saved: saved),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: const Text('WARKA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.4, fontSize: 22, color: Color(0xFF171717))),
        actions: [
          TextButton(onPressed: widget.onLanguage, child: Text(am ? 'EN' : 'አማ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB51F2A)))),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.newspaper_outlined), label: tr(am,'News','ዜና')),
          NavigationDestination(icon: const Icon(Icons.campaign_outlined), label: tr(am,'Send tip','ዜና ላክ')),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), label: tr(am,'Messages','መልዕክቶች')),
          NavigationDestination(icon: const Icon(Icons.bookmark_border), label: tr(am,'Saved','የተቀመጡ')),
        ],
      ),
    );
  }
}

class Story {
  final String id, category, titleEn, titleAm, summaryEn, summaryAm, time;
  const Story(this.id,this.category,this.titleEn,this.titleAm,this.summaryEn,this.summaryAm,this.time);
}
const demoStories = [
 Story('1','POLITICS','Regional leaders meet for talks','የክልል መሪዎች ለውይይት ተገናኙ','A developing story. Details will be added as information is verified.','ታሪኩ እየተጠናቀቀ ነው። መረጃው ሲረጋገጥ ዝርዝር ይታከላል።','12 min'),
 Story('2','ECONOMY','New economic update released','አዲስ የኢኮኖሚ መረጃ ተለቀቀ','A short summary will appear here when the publisher posts a verified report.','አሳታሚው የተረጋገጠ ዘገባ ሲያወጣ አጭር ማጠቃለያ እዚህ ይታያል።','38 min'),
 Story('3','COMMUNITY','Community report from the field','ከማህበረሰቡ የመስክ ዘገባ','Follow this space for updates from the newsroom.','ከዜና ክፍሉ የሚመጡ ዝመናዎችን እዚህ ይከታተሉ።','1 hr'),
];

class HomePage extends StatelessWidget {
 final bool am; final Set<String> saved; final void Function(String) onSave;
 const HomePage({super.key,required this.am,required this.saved,required this.onSave});
 @override
 Widget build(BuildContext context) => ListView(
  padding: const EdgeInsets.fromLTRB(18,8,18,24),
  children: [
   Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF191919),borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
     const Text('WARKA NEWS',style: TextStyle(color: Colors.white,fontWeight: FontWeight.w900,letterSpacing: 1.2)),
     const SizedBox(height: 8),
     Text(tr(am,'Your country. Your stories. Your voice.','ሀገርዎ። ታሪኮችዎ። ድምፅዎ።'),style: const TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w600)),
     const SizedBox(height: 12),
     Text(tr(am,'INDEPENDENT NEWS • ETHIOPIA','ገለልተኛ ዜና • ኢትዮጵያ'),style: const TextStyle(color: Color(0xFFFF7777),fontSize: 10,fontWeight: FontWeight.bold,letterSpacing: 1)),
    ])),
   const SizedBox(height: 22),
   Row(children:[Text(tr(am,'LATEST NEWS','የቅርብ ጊዜ ዜና'),style: const TextStyle(fontSize: 19,fontWeight: FontWeight.w900)),const Spacer(),Text(tr(am,'DEMO CONTENT','የሙከራ ይዘት'),style: const TextStyle(fontSize: 10,color: Colors.grey))]),
   const SizedBox(height: 8),
   ...demoStories.map((s)=>Card(margin: const EdgeInsets.only(bottom: 10),child: Padding(padding: const EdgeInsets.all(14),child: Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
    Row(children:[Text(s.category,style: const TextStyle(color: Color(0xFFB51F2A),fontWeight: FontWeight.w800,fontSize: 10,letterSpacing: .8)),const Spacer(),Text(s.time,style: const TextStyle(color: Colors.grey,fontSize: 11))]),
    const SizedBox(height: 8),
    Text(tr(am,s.titleEn,s.titleAm),style: const TextStyle(fontWeight: FontWeight.w800,fontSize: 17)),
    const SizedBox(height: 6),
    Text(tr(am,s.summaryEn,s.summaryAm)),
    Align(alignment: Alignment.centerRight,child: IconButton(onPressed: ()=>onSave(s.id),icon: Icon(saved.contains(s.id)?Icons.bookmark:Icons.bookmark_border,color: const Color(0xFFB51F2A)))),
   ])))),
   const SizedBox(height: 6),
   Text(tr(am,'Stories shown here are sample content until the publisher connects the newsroom.','አሳታሚው የዜና ክፍሉን እስኪያገናኝ ድረስ እዚህ የሚታዩት የሙከራ ይዘቶች ናቸው።'),style: const TextStyle(fontSize: 11,color: Colors.grey)),
  ],
 );
}

class TipPage extends StatefulWidget {
 final bool am; const TipPage({super.key,required this.am});
 @override State<TipPage> createState()=>_TipPageState();
}
class _TipPageState extends State<TipPage>{
 final form=GlobalKey<FormState>(); final subject=TextEditingController(); final details=TextEditingController(); final contact=TextEditingController();
 bool anonymous=false; XFile? attachment; bool sending=false;
 Future<void> pick() async { final f=await ImagePicker().pickMedia(); if(f!=null)setState(()=>attachment=f); }
 Future<void> submit() async {
  if(!form.currentState!.validate())return;
  if(!backendReady){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(widget.am,'Connect the newsroom backend before sending tips.','ዜና ለመላክ የዜና ክፍሉን ማገናኘት ያስፈልጋል።')))); return; }
  setState(()=>sending=true);
  try {
   final db=Supabase.instance.client;
   String? path;
   if(attachment!=null){
    final bytes=await attachment!.readAsBytes();
    final ext=attachment!.name.split('.').last;
    path='tips/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await db.storage.from('news-tips').uploadBinary(path,bytes);
   }
   await db.from('news_tips').insert({'subject':subject.text.trim(),'message':details.text.trim(),'contact':anonymous?null:contact.text.trim(),'is_anonymous':anonymous,'media_path':path});
   subject.clear();details.clear();contact.clear();setState(()=>attachment=null);
   if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(widget.am,'Tip sent to the newsroom.','መረጃው ለዜና ክፍሉ ተልኳል።'))));
  } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not send: $e')));}
  finally{if(mounted)setState(()=>sending=false);}
 }
 @override Widget build(BuildContext context)=>Form(key:form,child:ListView(padding:const EdgeInsets.all(18),children:[
  Text(tr(widget.am,'SEND A NEWS TIP','የዜና መረጃ ይላኩ'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
  const SizedBox(height:6),Text(tr(widget.am,'Share what you saw. The newsroom will review it before publication.','ያዩትን መረጃ ያጋሩ። ዜና ክፍሉ ከማተሙ በፊት ይመረምረዋል።')),
  const SizedBox(height:18),
  TextFormField(controller:subject,decoration:InputDecoration(labelText:tr(widget.am,'Subject','ርዕስ'),border:const OutlineInputBorder()),validator:(v)=>v==null||v.trim().isEmpty?tr(widget.am,'Enter a subject','ርዕስ ያስገቡ'):null),
  const SizedBox(height:12),
  TextFormField(controller:details,maxLines:6,decoration:InputDecoration(labelText:tr(widget.am,'What happened? Include place and time.','ምን ተፈጠረ? ቦታና ሰዓት ይጨምሩ።'),border:const OutlineInputBorder()),validator:(v)=>v==null||v.trim().length<10?tr(widget.am,'Please add more detail','ተጨማሪ ዝርዝር ያስገቡ'):null),
  const SizedBox(height:12),
  SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(tr(widget.am,'Send anonymously','ስም ሳይጠቅሱ ይላኩ')),value:anonymous,onChanged:(v)=>setState(()=>anonymous=v)),
  if(!anonymous)TextField(controller:contact,decoration:InputDecoration(labelText:tr(widget.am,'Your contact (optional)','የመገኛ መረጃ (አማራጭ)'),border:const OutlineInputBorder())),
  const SizedBox(height:12),
  OutlinedButton.icon(onPressed:pick,icon:const Icon(Icons.attach_file),label:Text(attachment==null?tr(widget.am,'Attach photo or video','ፎቶ ወይም ቪዲዮ ያያይዙ'):attachment!.name)),
  const SizedBox(height:16),
  FilledButton(onPressed:sending?null:submit,style:FilledButton.styleFrom(backgroundColor:const Color(0xFFB51F2A),padding:const EdgeInsets.all(15)),child:Text(sending?tr(widget.am,'Sending...','በመላክ ላይ...'):tr(widget.am,'Send to newsroom','ለዜና ክፍሉ ይላኩ'))),
  const SizedBox(height:12),Text(tr(widget.am,'Do not send information that could put you or another person at risk. The publisher must verify submissions before reporting.','እርስዎን ወይም ሌላ ሰውን አደጋ ላይ የሚጥል መረጃ አይላኩ። አሳታሚው ከመዘገቡ በፊት መረጃውን ማረጋገጥ አለበት።'),style:const TextStyle(fontSize:11,color:Colors.grey)),
 ]));
}

class MessagePage extends StatefulWidget {final bool am;const MessagePage({super.key,required this.am});@override State<MessagePage> createState()=>_MessagePageState();}
class _MessagePageState extends State<MessagePage>{
 final name=TextEditingController();final contact=TextEditingController();final message=TextEditingController();bool sending=false;
 Future<void> send() async {
  if(message.text.trim().length<3)return;
  if(!backendReady){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(widget.am,'Messaging will work after the publisher connects the backend.','አሳታሚው የጀርባ ስርዓቱን ካገናኘ በኋላ መልዕክት መላክ ይቻላል።'))));return;}
  setState(()=>sending=true);
  try{await Supabase.instance.client.from('publisher_messages').insert({'sender_name':name.text.trim(),'contact':contact.text.trim(),'message':message.text.trim()});message.clear();if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(tr(widget.am,'Message sent.','መልዕክቱ ተልኳል።'))));}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not send: $e')));}
  finally{if(mounted)setState(()=>sending=false);}
 }
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[
  Text(tr(widget.am,'CONTACT THE PUBLISHER','አሳታሚውን ያነጋግሩ'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
  const SizedBox(height:6),Text(tr(widget.am,'Ask a question or send a private message to the newsroom.','ጥያቄ ይጠይቁ ወይም ለዜና ክፍሉ የግል መልዕክት ይላኩ።')),
  const SizedBox(height:18),
  TextField(controller:name,decoration:InputDecoration(labelText:tr(widget.am,'Name (optional)','ስም (አማራጭ)'),border:const OutlineInputBorder())),
  const SizedBox(height:12),TextField(controller:contact,decoration:InputDecoration(labelText:tr(widget.am,'Contact (optional)','መገኛ (አማራጭ)'),border:const OutlineInputBorder())),
  const SizedBox(height:12),TextField(controller:message,maxLines:6,decoration:InputDecoration(labelText:tr(widget.am,'Your message','መልዕክትዎ'),border:const OutlineInputBorder())),
  const SizedBox(height:16),FilledButton(onPressed:sending?null:send,style:FilledButton.styleFrom(backgroundColor:const Color(0xFFB51F2A),padding:const EdgeInsets.all(15)),child:Text(tr(widget.am,'Send message','መልዕክት ይላኩ'))),
 ]);
}

class SavedPage extends StatelessWidget {
 final bool am;final Set<String> saved;const SavedPage({super.key,required this.am,required this.saved});
 @override Widget build(BuildContext context){final items=demoStories.where((s)=>saved.contains(s.id)).toList();return ListView(padding:const EdgeInsets.all(18),children:[
  Text(tr(am,'SAVED STORIES','የተቀመጡ ዜናዎች'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
  if(items.isEmpty)Padding(padding:const EdgeInsets.only(top:30),child:Text(tr(am,'Stories you bookmark will appear here.','ያስቀመጧቸው ዜናዎች እዚህ ይታያሉ።'))),
  ...items.map((s)=>ListTile(title:Text(tr(am,s.titleEn,s.titleAm)),subtitle:Text(s.category))),
 ]);}
}
