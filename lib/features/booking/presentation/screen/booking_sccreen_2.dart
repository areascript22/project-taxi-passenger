import 'package:flutter/material.dart';

class BookingScreen2 extends StatefulWidget {
  const BookingScreen2({super.key});

  @override
  State<BookingScreen2> createState() => _BookingScreen2State();
}

class _BookingScreen2State extends State<BookingScreen2> {
  // 1. Declaración de los GlobalKeys para cada sección
  final GlobalKey _section1Key = GlobalKey();
  final GlobalKey _section2Key = GlobalKey();
  final GlobalKey _section3Key = GlobalKey();
  final GlobalKey _section4Key = GlobalKey(); // Sección Púrpura
  final GlobalKey _section5Key = GlobalKey();
  final GlobalKey _section6Key = GlobalKey();

  @override
  void initState() {
    super.initState();

    // 2. Agregamos un callback que se ejecuta al terminar de construir el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(_section6Key); // Auto-scroll a la sección 4 (Púrpura)
    });
  }

  // 3. Método auxiliar para hacer scroll hacia la llave seleccionada
  void _scrollToSection(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(seconds: 2), // Aumenté un poco la duración para que notes el efecto
        curve: Curves.easeInOut,
      );
    }
  }

  // 4. Método para construir cada sección con su FutureBuilder
  Widget _buildDynamicSection({
    required GlobalKey key,
    required int delayInSeconds,
    required Color finalColor,
    required String title,
  }) {
    return FutureBuilder(
      key: key, // La llave se asigna al FutureBuilder para que el contexto exista inmediatamente
      future: Future.delayed(Duration(seconds: delayInSeconds)),
      builder: (context, snapshot) {
        // Estado de carga: Widget más pequeño simulando el cambio dinámico de espacio
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100, // Altura menor inicial
            width: double.infinity,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Estado final: El contenedor original
        return Container(
          height: 250, // Altura final mayor
          width: double.infinity,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: finalColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Center(
              child: Text(
                "Booking screen 2",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Generamos las secciones dinámicas
            _buildDynamicSection(
              key: _section1Key,
              delayInSeconds: 1,
              finalColor: Colors.blueAccent,
              title: "Sección 1",
            ),
            _buildDynamicSection(
              key: _section2Key,
              delayInSeconds: 2,
              finalColor: Colors.teal,
              title: "Sección 2",
            ),
            _buildDynamicSection(
              key: _section3Key,
              delayInSeconds: 3,
              finalColor: Colors.orangeAccent,
              title: "Sección 3",
            ),
            _buildDynamicSection(
              key: _section4Key,
              delayInSeconds: 4,
              finalColor: Colors.deepPurpleAccent,
              title: "Sección 4",
            ),
            _buildDynamicSection(
              key: _section5Key,
              delayInSeconds: 5,
              finalColor: Colors.redAccent,
              title: "Sección 5",
            ),
            _buildDynamicSection(
              key: _section6Key,
              delayInSeconds: 6,
              finalColor: Colors.blueAccent,
              title: "Sección 6",
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}