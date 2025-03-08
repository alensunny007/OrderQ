import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark blue and teal colors
    const Color darkBlue = Color(0xFF00122D);
    const Color tealColor = Color(0xFF53E3C6);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          // Solid dark blue background
          color: darkBlue,
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // OrderQ Title Text
            const Text(
              "OrderQ",
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: tealColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            
            // Catchy sentence about OrderQ
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Skip the line, Save your time. Campus dining reimagined at CEV.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tealColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Thank you message
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Thank you for choosing OrderQ! Say goodbye to long queues and hello to more time for what matters — your campus life, your way.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: tealColor,
                ),
              ),
            ),
            
            // Spacer to push footer to bottom
            const Spacer(),
            
            // Footer with Contact Us heading
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text(
                    "Contact Us",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: tealColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Catchy bottom text
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      "Connect with us and be part of the food revolution that's changing campus life at CEV!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: tealColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  // Social media buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // WhatsApp
                      _socialButton(
                        icon: FontAwesomeIcons.whatsapp,
                        color: Colors.green,
                        onTap: () => _launchUrl('https://wa.me/+918590902575'),
                        backgroundColor: tealColor.withOpacity(0.2),
                      ),
                      
                      // GitHub
                      _socialButton(
                        icon: FontAwesomeIcons.github,
                        color: Colors.white,
                        onTap: () => _launchUrl('https://github.com/alensunny007'),
                        backgroundColor: tealColor.withOpacity(0.2),
                      ),
                      
                      // Instagram
                      _socialButton(
                        icon: FontAwesomeIcons.instagram,
                        color: Colors.purple,
                        onTap: () => _launchUrl('https://instagram.com/a.l.e.n.007'),
                        backgroundColor: tealColor.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}