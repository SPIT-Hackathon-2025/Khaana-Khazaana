import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'lostandfound.dart';

// import 'Dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]).then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ClaimProvider()  ),
        ChangeNotifierProvider(create: (_) => FoundProvider()  )
      ],
      child: MaterialApp(
        title: 'Caretaker App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const CaretakerHomePage(),
      ),
    );
  }
}

class CaretakerHomePage extends StatefulWidget {
  const CaretakerHomePage({super.key});

  @override
  State<CaretakerHomePage> createState() => _CaretakerHomePageState();
}

class _CaretakerHomePageState extends State<CaretakerHomePage> {
  int _selectedIndex = 0;

  static const source = LatLng(19.1206308,72.8404587);
  static const destination = LatLng(19.1772202, 72.951037);

  // Pages for the caretaker app
  final List<Widget> _pages = [
    Center(
      child: CaretakerDashboardPage()
    ),
    ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.person),
          title: Text("Patient 1"),
          subtitle: Text("Heart rate: Normal"),
          trailing: Icon(Icons.arrow_forward),
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text("Patient 2"),
          subtitle: Text("Blood pressure: High"),
          trailing: Icon(Icons.arrow_forward),
        ),
      ],
    ),
    Center(
      child: GoogleMapPage(
        locations: [
          {
            "name": "R city",
            "latLng": LatLng(19.0945902,72.9421997),
            "info": "Famous landmark in New York",
            'image': 'https://media.geeksforgeeks.org/wp-content/cdn-uploads/20191016135223/What-is-Algorithm_-1024x631.jpg'
          },
          {
            "name": "Taj trees",
            "latLng": LatLng(19.0946016,72.9422359),
            "info": "Iconic tower in Paris",
            'image': 'https://media.geeksforgeeks.org/wp-content/cdn-uploads/20191016135223/What-is-Algorithm_-1024x631.jpg',
          },
          {
            "name": "Powai Lake",
            "latLng": LatLng(19.1103994,72.9237242),
            "info": "Wonder of the World in India",
            'image': 'https://media.geeksforgeeks.org/wp-content/cdn-uploads/20191016135223/What-is-Algorithm_-1024x631.jpg',
          },
        ],
      ),
    ),
   // LostAndFoundPage()
    HomePage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.teal,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Patients",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Lost and Found",
          ),
        ],
      ),
    );
  }
}
