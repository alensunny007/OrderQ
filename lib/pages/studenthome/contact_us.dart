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
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            // Solid dark blue background
            color: darkBlue,
          ),
          child: Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16.0),
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
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Team section title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Our Awesome Team",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: tealColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Subtitle for team
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Meet the developers building the future of campus dining",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: tealColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Team grid - 2x2 layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // First row - 2 team members
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Team Member 1
                        Expanded(
                          child: _teamMemberCard(
                            name: "Alen Sunny",
                            role: "Lead Developer",
                            avatarColor: Colors.purple.withOpacity(0.2),
                            icon: Icons.developer_mode,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Team Member 2
                        Expanded(
                          child: _teamMemberCard(
                            name: "Aasif Abdullah",
                            role: "Project Manager",
                            avatarColor: Colors.pink.withOpacity(0.2),
                            icon: Icons.manage_accounts,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Second row - 2 more team members
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Team Member 3
                        Expanded(
                          child: _teamMemberCard(
                            name: "Amal Hisham",
                            role: "UI/UX Designer",
                            avatarColor: Colors.blue.withOpacity(0.2),
                            icon: Icons.auto_fix_high
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Team Member 4
                        Expanded(
                          child: _teamMemberCard(
                            name: "Nihal Roshan",
                            role: "Lead Developer",
                            avatarColor: Colors.amber.withOpacity(0.2),
                            icon: Icons.developer_mode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Footer with Contact Us heading
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: darkBlue.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Connect With Us",
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
                    
                    const SizedBox(height: 20),
                    
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
  
  Widget _teamMemberCard({
    required String name,
    required String role,
    required Color avatarColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF53E3C6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF53E3C6).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: const Color(0xFF53E3C6),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF53E3C6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Role
          Text(
            role,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF53E3C6).withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}