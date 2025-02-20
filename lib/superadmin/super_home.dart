import 'package:flutter/material.dart';

// User model remains the same
class User {
  final String id;
  final String name;
  final String email;
  String role;
  final String dateJoined;
  final String? studentId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.dateJoined,
    this.studentId,
  });
}

class SuperHome extends StatefulWidget {
  const SuperHome({Key? key, required String userId}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<SuperHome> {
  List<User> users = [
    User(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      role: 'student',
      dateJoined: '2024-02-14',
      studentId: 'STU2024001',
    ),
    User(
      id: '2',
      name: 'Aasif Abdullah T K',
      email: 'aasifabdullahtk@gmail.com',
      role: 'student',
      dateJoined: '2024-02-14',
      studentId: 'VDA21CS002',
    ),
    User(
      id: '3',
      name: 'Nihal Roshan K P',
      email: 'nihalroshankp@gmail.com',
      role: 'student',
      dateJoined: '2024-02-14',
      studentId: 'LVDA21CS070',
    ),
    User(
      id: '3',
      name: 'Amal Hisham K',
      email: 'amalhishamkoraliyadan@gmail.com',
      role: 'student',
      dateJoined: '2024-02-14',
      studentId: 'VDA21CS009',
    ),
  ];

  String roleFilter = 'all';
  String searchQuery = '';

  // Custom theme colors
  final mainGradient = const LinearGradient(
    colors: [
      Color(0xFF00122D), // Dark blue
      Color(0xFF53E3C6), // Teal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final cardGradient = const LinearGradient(
    colors: [
      Color(0xFF001736),
      Color(0xFF002147),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Search and filter section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or student ID...',
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.search, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButton<String>(
                        value: roleFilter,
                        dropdownColor: Color(0xFF00122D),
                        style: TextStyle(color: Colors.white),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        underline: SizedBox(),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Roles')),
                          DropdownMenuItem(value: 'student', child: Text('Students')),
                          DropdownMenuItem(value: 'admin', child: Text('Admins')),
                          DropdownMenuItem(value: 'canteen_manager', child: Text('Canteen Managers')),
                          DropdownMenuItem(value: 'cafeteria_manager', child: Text('Cafeteria Managers')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            roleFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Users list
              Expanded(
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: cardGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF53E3C6),
                          child: Text(
                            user.name[0],
                            style: TextStyle(
                              color: Color(0xFF00122D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email,
                              style: TextStyle(color: Colors.white70),
                            ),
                            if (user.studentId != null && user.role == 'student')
                              Text(
                                'Student ID: ${user.studentId}',
                                style: TextStyle(color: Colors.white70),
                              ),
                            Text(
                              'Role: ${_getRoleDisplayName(user.role)}',
                              style: TextStyle(
                                color: _getRoleColor(user.role),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              color: Color(0xFF53E3C6),
                              onPressed: () => _changeUserRole(user),
                              tooltip: 'Change Role',
                            ),
                            IconButton(
                              icon: Icon(Icons.person_remove),
                              color: Colors.redAccent,
                              onPressed: () => _ejectUser(user),
                              tooltip: 'Eject User',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Color(0xFFFF5555);
      case 'canteen_manager':
        return Color(0xFF53E3C6);
      case 'cafeteria_manager':
        return Color(0xFF64B5F6);
      case 'student':
        return Color(0xFFE040FB);
      default:
        return Colors.grey;
    }
  }

  // Other methods remain the same
  List<User> get filteredUsers {
    return users.where((user) {
      bool matchesSearch = user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (user.studentId?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      bool matchesRole = roleFilter == 'all' || user.role == roleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'canteen_manager':
        return 'Canteen Manager';
      case 'cafeteria_manager':
        return 'Cafeteria Manager';
      case 'student':
        return 'Student';
      default:
        return role;
    }
  }

  // Ejection dialog with updated theme
  Future<void> _ejectUser(User user) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF00122D),
          title: Text('Confirm Ejection', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to eject ${user.name}?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Eject', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      setState(() {
        users.removeWhere((u) => u.id == user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} has been ejected'),
          backgroundColor: Color(0xFF00122D),
        ),
      );
    }
  }

  // Role change dialog with updated theme
  Future<void> _changeUserRole(User user) async {
    String? newRole = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF00122D),
          title: Text('Change Role', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select new role for ${user.name}',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Admin', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('admin'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Canteen Manager', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('canteen_manager'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Cafeteria Manager', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('cafeteria_manager'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              SizedBox(height: 8),
              ListTile(
                title: Text('Student', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop('student'),
                tileColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ],
          ),
        );
      },
    );

    if (newRole != null) {
      setState(() {
        user.role = newRole;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name}\'s role has been updated to ${_getRoleDisplayName(newRole)}'),
          backgroundColor: Color(0xFF00122D),
        ),
      );
    }
  }
}