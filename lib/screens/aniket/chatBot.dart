import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;



class ChatBotScreen extends StatefulWidget {
  static const routeName = '/home';
  const ChatBotScreen({Key? key}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  //final ReminderService _reminderService = ReminderService();
  bool isLoading = false;
  double homeLat = 0;
  double homeLong = 0;
  bool _isNotificationSent = false;
  bool _isMounted = false;
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isChatVisible = false;
  Offset _offset = const Offset(50, 400);
  double _chatBottomPosition = 130;
  FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText _speech; // Speech-to-text instance
  bool _isListening = false; // Track listening state
  String _spokenText = ''; // Hold recognized text
  final ScrollController _scrollController = ScrollController();
  bool _loading=false;




  Future<String> getBotResponse(String query) async {
    final url = Uri.parse('/chat');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': query}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return _getIntent(responseData['text']);
    } else {
      return 'Error: ${response.statusCode}';
    }
  }


  Future<String> _getIntent(String userMessage) async {
    if (userMessage.toLowerCase().contains('1')) {
      // Navigator.push(context, MaterialPageRoute(builder: (context) => FirstGameScreen()));
      return 'Routing you to the game page 1...';
    } else if (userMessage.toLowerCase().contains('2')) {
      // Navigator.push(context, MaterialPageRoute(builder: (context) => LetterClickGameScreen()));
      return 'Routing you to the game page 2...';
    } else if (userMessage.toLowerCase().contains('3')) {
      // Navigator.push(context, MaterialPageRoute(builder: (context) => QuizPage()));
      return 'Routing you to the game page 3...';
    } else if (userMessage.toLowerCase().contains('living room') && userMessage.toLowerCase().contains('kitchen')) {
      _speak("From the kitchen, walk past the dining area to reach the living room.");
      return "From the kitchen, walk past the dining area to reach the living room.";
    }
    else if (userMessage.toLowerCase().contains('bathroom') && userMessage.toLowerCase().contains('bedroom')) {
      _speak("From the bedroom, head down the hallway to reach the bathroom.");
      return "From the bedroom, head down the hallway to reach the bathroom.";
    }
    else if (userMessage.toLowerCase().contains('garage') && userMessage.toLowerCase().contains('living room')) {
      _speak("From the living room, exit through the main door to reach the garage.");
      return "From the living room, exit through the main door to reach the garage.";
    }
    else if (userMessage.toLowerCase().contains('map')) {

      // Position position = await Geolocator.getCurrentPosition(
      //   desiredAccuracy: LocationAccuracy.best,
      // );
      // Navigator.push(context, MaterialPageRoute(builder: (context){
      //   return GoogleMapPage(destinationLocation: LatLng(19.1772202,72.951037), sourceLocation: LatLng(position.latitude,position.longitude));
      // }));
      _speak("Don't Worry Follow the Map");
      return "Don't Worry Follow the Map";
    }
    else if (userMessage.toLowerCase().contains('rec')) {
      setState(() {
        _isChatVisible=false;
      });

      //_speak("Don't Worry Follow the Map");
      return "Redirecting to Recognize Page";
    }
    else if (userMessage.toLowerCase().contains('rem')) {


      // Navigator.push(context, MaterialPageRoute(builder: (context){
      //   return NotesScreen();
      // }));
      //_speak("Don't Worry Follow the Map");
      return "Redirecting to Todo Page";
    }

    else {
      return 'Sorry, this feature is not in the app.';
    }
  }

  void _sendMessage(String message) async {
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({'user': message});
      });

      final botResponse = await getBotResponse(message);

      setState(() {
        _messages.add({'bot': botResponse});
      });

      _controller.clear();
      _scrollToBottom();
    }
  }
  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
          });
          if (!_speech.isListening) {
            _sendMessage(_spokenText); // Send the recognized text
          }
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _scrollToBottom();
  }

  void _scrollToBottom(){
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> checkLanguageAvailability(bool available) async {
    if (!available) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Text-to-Speech Not Available'),
            content: Text(
                'Text-to-Speech functionality is not available on this device.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }


  void _speak(String text) async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setLanguage("en-IN");

    await flutterTts.speak(text);
  }


  bool _isDoneFirst=false;
  @override
  void initState() {
    super.initState();
    _isMounted = true;

    _speech = stt.SpeechToText();
    // scheduleNotifications();
    flutterTts.isLanguageAvailable("en-IN").then((available) {
      checkLanguageAvailability(available);
    });


  }



  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }



  Widget _buildChatWindow() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            // Chat Header
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFF5ECFF),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text(
                      'Chatur',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _isChatVisible = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Chat Messages
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.containsKey('user');
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color: isUser ? Color(0xFFF5ECFF) : Color(0xFFE197FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isUser ? message['user']! : message['bot']!,
                        style: TextStyle(color: isUser ? Colors.black : Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Input Field
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      onTap: (){},
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask about app features...',
                        border: OutlineInputBorder(),
                      ),
                      //onSubmitted: (value) => _sendMessage(value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    color: _isListening ? Colors.red : Colors.black,
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      //_sendMessage(_controller.text);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.top-1000;
    // int selectedIndex = Provider.of<PageProvider>(context).index;
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: (){
        setState(() {
          _isChatVisible = !_isChatVisible;
        });
      },child: Icon(Iconsax.message),),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () {
                // signOut();
              },
              icon: Icon(
                Iconsax.logout,
                color: Colors.white,
              ))
        ],
        title: Text(
            'YaadonKiBaarat',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w900)
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          // Floating Action Button

          if (_isChatVisible)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: bottomInset > 0 ? bottomInset + 10 : _chatBottomPosition,
              right: 20,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 300,
                  height: MediaQuery.of(context).size.height * 0.5, // Adjust height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _buildChatWindow(),
                ),
              ),
            ),

        ],
      ),

      //body: pages[selectedIndex],
      // extendBody: (selectedIndex == 3 || selectedIndex == 1) ? false : true,
    );
  }
}

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const NavigationItem({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: Icon(
        icon,
        color: Colors.white,
        size: 25,
      ),
      label: text,
    );
  }
}