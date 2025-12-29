class Project {
  final String id;
  final String title;
  final String description;
  final String category;
  final String faculty;
  final String creator;
  final String status;
  final List<String> lookingFor;
  final int currentTeamSize;
  final int maxTeamSize;
  final String startDate;
  final String duration;
  final int progress;
  final List<String> requirements;
  final List<String> objectives;
  final String? supervisor;
  final List<TeamMember> teamMembers;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.faculty,
    required this.creator,
    required this.status,
    required this.lookingFor,
    required this.currentTeamSize,
    required this.maxTeamSize,
    required this.startDate,
    required this.duration,
    required this.progress,
    required this.requirements,
    required this.objectives,
    this.supervisor,
    required this.teamMembers,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Debug logging
    print('=== Parsing Project ===');
    print('Raw JSON: $json');
    
    // Parse creator name
    String creatorName = '';
    final creatorData = json['creator'];
    if (creatorData is Map) {
      creatorName = creatorData['name']?.toString() ?? 
                   creatorData['user']?['name']?.toString() ?? 
                   creatorData['email']?.toString() ?? 
                   'Unknown';
    } else if (creatorData != null) {
      creatorName = creatorData.toString();
    }
    print('Creator: $creatorName');

    // Parse supervisor name
    String? supervisorName;
    final supervisorData = json['supervisor'] ?? json['supervisor_name'];
    if (supervisorData is Map) {
      supervisorName = supervisorData['name']?.toString() ?? 
                      supervisorData['user']?['name']?.toString() ?? 
                      supervisorData['email']?.toString();
    } else if (supervisorData != null && supervisorData.toString().isNotEmpty) {
      supervisorName = supervisorData.toString();
    }
    print('Supervisor: $supervisorName');

    // Parse tags/lookingFor - backend may use 'tags' or 'looking_for'
    List<String> lookingForList = [];
    final tagsData = json['tags'] ?? json['looking_for'] ?? json['lookingFor'];
    print('Tags data: $tagsData (type: ${tagsData.runtimeType})');
    if (tagsData is List) {
      lookingForList = tagsData.map((e) => e.toString()).toList();
    } else if (tagsData is String && tagsData.isNotEmpty) {
      lookingForList = [tagsData];
    }
    print('Looking for: $lookingForList');

    // Parse requirements - backend may use 'required_skills' or 'requirements'
    List<String> requirementsList = [];
    final reqData = json['required_skills'] ?? json['requirements'];
    print('Requirements data: $reqData (type: ${reqData.runtimeType})');
    if (reqData is List) {
      requirementsList = reqData.map((e) => e.toString()).toList();
    } else if (reqData is String && reqData.isNotEmpty) {
      requirementsList = [reqData];
    }
    print('Requirements: $requirementsList');

    // Parse objectives
    List<String> objectivesList = [];
    final objData = json['objectives'];
    if (objData is List) {
      objectivesList = objData.map((e) => e.toString()).toList();
    }

    // Parse team members
    List<TeamMember> members = [];
    final membersData = json['team_members'] ?? json['teamMembers'] ?? json['members'];
    if (membersData is List) {
      members = membersData
          .map((m) => TeamMember.fromJson(
              m is Map<String, dynamic> ? m : {'id': '0', 'name': m.toString(), 'role': 'Member'}))
          .toList();
    }

    // Parse duration - backend may use 'expected_duration' or 'duration'
    String durationStr = json['expected_duration']?.toString() ?? json['duration']?.toString() ?? '';
    print('Duration: $durationStr');
    
    // Parse start date
    String startDateStr = json['start_date']?.toString() ?? json['startDate']?.toString() ?? '';
    print('Start date: $startDateStr');

    print('=== End Parsing ===\n');

    return Project(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      faculty: json['faculty']?.toString() ?? '',
      creator: creatorName,
      status: json['status']?.toString() ?? 'Planning',
      lookingFor: lookingForList,
      currentTeamSize: _parseInt(json['current_team_size'] ?? json['currentTeamSize'] ?? 0),
      maxTeamSize: _parseInt(json['max_team_size'] ?? json['maxTeamSize'] ?? 5),
      startDate: startDateStr,
      duration: durationStr,
      progress: _parseInt(json['progress'] ?? 0),
      requirements: requirementsList,
      objectives: objectivesList,
      supervisor: supervisorName,
      teamMembers: members,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get teamSizeDisplay => '$currentTeamSize/$maxTeamSize';
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String? avatar;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.avatar,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    String memberName = '';
    
    // Try direct name field
    memberName = json['name']?.toString() ?? '';
    
    // Try nested user
    if (memberName.isEmpty && json['user'] is Map) {
      memberName = json['user']['name']?.toString() ?? '';
    }
    
    // Try email as fallback
    if (memberName.isEmpty) {
      memberName = json['email']?.toString() ?? 
                  json['user']?['email']?.toString() ?? 
                  'Member';
    }

    return TeamMember(
      id: json['id'].toString(),
      name: memberName,
      role: json['role']?.toString() ?? 'Member',
      avatar: json['avatar']?.toString() ?? json['user']?['profile_image']?.toString(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String status;
  final String assignee;
  final String dueDate;
  final String priority;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.assignee,
    required this.dueDate,
    required this.priority,
  });
}

class Milestone {
  final String id;
  final String title;
  final int progress;
  final String dueDate;
  final bool isCompleted;

  Milestone({
    required this.id,
    required this.title,
    required this.progress,
    required this.dueDate,
    required this.isCompleted,
  });
}

class Meeting {
  final String id;
  final String title;
  final String dateTime;
  final String location;
  final List<String> participants;

  Meeting({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.participants,
  });
}