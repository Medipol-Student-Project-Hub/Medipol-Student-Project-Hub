import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import '../models/project.dart';
import 'project_detail_page.dart';
import 'create_project_page.dart';
import 'profile_page.dart';
import 'messaging_page.dart';
import 'notifications_page.dart';
import 'professor_dashboard.dart';
import 'join_requests_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load projects when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);
      projectProvider.loadProjects();
      projectProvider.loadMyProjects();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserName = authProvider.currentUser?.name;

    // Filter out user's own projects from Explore tab
    final exploreProjects = projectProvider.projects
        .where((p) => p.creator != currentUserName)
        .toList();

    final projects = _selectedTab == 0 ? exploreProjects : projectProvider.myProjects;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Medipol Project Hub'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'Join Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JoinRequestsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.bell),
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.messageSquare),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessagingPage(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                if (authProvider.userType == 'faculty') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfessorDashboard(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                }
              },
              child: const CircleAvatar(
                backgroundColor: Color(0xFF0EA5E9),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: const Icon(LucideIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
              ),
              onChanged: (value) {
                projectProvider.searchProjects(value);
              },
            ),
          ),

          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() => _selectedTab = index);
              },
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF0EA5E9),
              tabs: const [
                Tab(text: 'Explore Projects'),
                Tab(text: 'My Projects'),
              ],
            ),
          ),

          // Project List
          Expanded(
            child: projectProvider.isLoading && projects.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : projects.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedTab == 0
                                    ? LucideIcons.search
                                    : LucideIcons.folderOpen,
                                size: 64,
                                color: const Color(0xFF6B7280),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedTab == 0
                                    ? 'No projects found'
                                    : 'You haven\'t joined any projects yet',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedTab == 0
                                    ? 'Try adjusting your search or create a new project'
                                    : 'Explore projects and join one to get started',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_selectedTab == 0) {
                                    projectProvider.loadProjects();
                                  } else {
                                    setState(() {
                                      _tabController.animateTo(0);
                                      _selectedTab = 0;
                                    });
                                  }
                                },
                                icon: Icon(_selectedTab == 0
                                    ? Icons.refresh
                                    : LucideIcons.search),
                                label: Text(_selectedTab == 0
                                    ? 'Refresh'
                                    : 'Explore Projects'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (_selectedTab == 0) {
                            await projectProvider.loadProjects();
                          } else {
                            await projectProvider.loadMyProjects();
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            return _buildProjectCard(context, projects[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProjectPage(),
            ),
          );
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Project'),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailPage(project: project),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${project.creator}${project.faculty.isNotEmpty ? ' • ${project.faculty}' : ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF6B7280),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(project.status),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
              ),
              const SizedBox(height: 12),

              // Looking For
              if (project.lookingFor.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: project.lookingFor
                      .take(3)
                      .map((role) => _buildBadge(role))
                      .toList(),
                ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  const Icon(
                    LucideIcons.users,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.teamSizeDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                  ),
                  const SizedBox(width: 16),
                  if (project.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        project.category,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    const greenColor = Color(0xFF10B981);
    const blueColor = Color(0xFF0EA5E9);
    const grayColor = Color(0xFF6B7280);

    Color color;
    switch (status) {
      case 'Recruiting':
        color = greenColor;
        break;
      case 'In Progress':
        color = blueColor;
        break;
      default:
        color = grayColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(14, 165, 233, 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0EA5E9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}