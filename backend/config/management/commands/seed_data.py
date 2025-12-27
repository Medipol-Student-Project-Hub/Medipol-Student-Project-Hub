"""
Django management command to seed the database with sample data.

Usage:
    python manage.py seed_data          # Seeds all sample data
    python manage.py seed_data --clear  # Clears existing data before seeding
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone
from users.models import User, Student, Faculty
from projects.models import Project, Milestone, JoinRequest, Feedback, Task, Meeting
from teams.models import Team, TeamMembership
from messaging.models import Conversation, Message
from datetime import date, timedelta, datetime
import json


class Command(BaseCommand):
    help = 'Seeds the database with sample data for development'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing data before seeding',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write('Clearing existing data...')
            self.clear_data()

        self.stdout.write('Seeding database with sample data...')

        with transaction.atomic():
            faculty_users = self.create_faculty()
            student_users = self.create_students()
            projects = self.create_projects(student_users, faculty_users)
            self.create_teams_and_memberships(projects, student_users)
            self.create_milestones(projects)
            self.create_join_requests(projects, student_users)
            self.create_feedback(projects, faculty_users)
            self.create_tasks(projects, student_users)
            self.create_meetings(projects, student_users)
            self.create_conversations_and_messages(student_users, faculty_users)

        self.stdout.write(self.style.SUCCESS('Successfully seeded database!'))

    def clear_data(self):
        """Clear all existing data in reverse dependency order."""
        Message.objects.all().delete()
        Conversation.objects.all().delete()
        Meeting.objects.all().delete()
        Task.objects.all().delete()
        Feedback.objects.all().delete()
        JoinRequest.objects.all().delete()
        Milestone.objects.all().delete()
        TeamMembership.objects.all().delete()
        Team.objects.all().delete()
        Project.objects.all().delete()
        Student.objects.all().delete()
        Faculty.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()
        self.stdout.write('Cleared existing data.')

    def create_faculty(self):
        """Create faculty users and profiles."""
        faculty_data = [
            {
                'email': 'mehmet.yildiz@medipol.edu.tr',
                'name': 'Prof. Dr. Mehmet Yildiz',
                'faculty_id': 'FAC001',
                'department': 'Computer Engineering',
                'title': 'Professor',
                'specialization': 'Artificial Intelligence, Machine Learning, Deep Learning',
            },
            {
                'email': 'ayse.kaya@medipol.edu.tr',
                'name': 'Dr. Ayse Kaya',
                'faculty_id': 'FAC002',
                'department': 'Software Engineering',
                'title': 'Associate Professor',
                'specialization': 'Software Architecture, Cloud Computing, DevOps',
            },
            {
                'email': 'ali.demir@medipol.edu.tr',
                'name': 'Dr. Ali Demir',
                'faculty_id': 'FAC003',
                'department': 'Information Systems',
                'title': 'Assistant Professor',
                'specialization': 'Data Science, Business Analytics, Big Data',
            },
            {
                'email': 'fatma.ozer@medipol.edu.tr',
                'name': 'Prof. Dr. Fatma Ozer',
                'faculty_id': 'FAC004',
                'department': 'Health Informatics',
                'title': 'Professor',
                'specialization': 'Medical Imaging, Healthcare AI, Bioinformatics',
            },
            {
                'email': 'hasan.cetin@medipol.edu.tr',
                'name': 'Dr. Hasan Cetin',
                'faculty_id': 'FAC005',
                'department': 'Computer Engineering',
                'title': 'Associate Professor',
                'specialization': 'Cybersecurity, Cryptography, Network Security',
            },
            {
                'email': 'zehra.aksoy@medipol.edu.tr',
                'name': 'Dr. Zehra Aksoy',
                'faculty_id': 'FAC006',
                'department': 'Software Engineering',
                'title': 'Assistant Professor',
                'specialization': 'Mobile Development, Human-Computer Interaction, UX Research',
            },
            {
                'email': 'kemal.yildirim@medipol.edu.tr',
                'name': 'Prof. Dr. Kemal Yildirim',
                'faculty_id': 'FAC007',
                'department': 'Information Systems',
                'title': 'Professor',
                'specialization': 'Database Systems, Distributed Computing, Cloud Architecture',
            },
            {
                'email': 'sema.korkmaz@medipol.edu.tr',
                'name': 'Dr. Sema Korkmaz',
                'faculty_id': 'FAC008',
                'department': 'Computer Engineering',
                'title': 'Associate Professor',
                'specialization': 'Robotics, Computer Vision, Autonomous Systems',
            },
        ]

        faculty_users = []
        for data in faculty_data:
            user, created = User.objects.get_or_create(
                email=data['email'],
                defaults={
                    'name': data['name'],
                    'user_type': 'faculty',
                    'is_active': True,
                }
            )
            if created:
                user.set_password('password123')
                user.save()

            faculty, _ = Faculty.objects.get_or_create(
                user=user,
                defaults={
                    'faculty_id': data['faculty_id'],
                    'department': data['department'],
                    'title': data['title'],
                    'specialization': data['specialization'],
                }
            )
            faculty_users.append(faculty)
            self.stdout.write(f'  Created faculty: {data["name"]}')

        return faculty_users

    def create_students(self):
        """Create student users and profiles."""
        student_data = [
            {
                'email': 'zeynep.arslan@std.medipol.edu.tr',
                'name': 'Zeynep Arslan',
                'student_id': 'STU001',
                'department': 'Computer Engineering',
                'year': '3',
                'skills': ['Python', 'Django', 'React', 'PostgreSQL'],
            },
            {
                'email': 'burak.ozturk@std.medipol.edu.tr',
                'name': 'Burak Ozturk',
                'student_id': 'STU002',
                'department': 'Software Engineering',
                'year': '4',
                'skills': ['Java', 'Spring Boot', 'Kubernetes', 'Docker'],
            },
            {
                'email': 'elif.celik@std.medipol.edu.tr',
                'name': 'Elif Celik',
                'student_id': 'STU003',
                'department': 'Computer Engineering',
                'year': '2',
                'skills': ['Flutter', 'Dart', 'Firebase', 'UI/UX Design'],
            },
            {
                'email': 'can.yilmaz@std.medipol.edu.tr',
                'name': 'Can Yilmaz',
                'student_id': 'STU004',
                'department': 'Information Systems',
                'year': '3',
                'skills': ['Python', 'Machine Learning', 'TensorFlow', 'Data Analysis'],
            },
            {
                'email': 'selin.koc@std.medipol.edu.tr',
                'name': 'Selin Koc',
                'student_id': 'STU005',
                'department': 'Software Engineering',
                'year': '4',
                'skills': ['Node.js', 'TypeScript', 'MongoDB', 'GraphQL'],
            },
            {
                'email': 'emre.sahin@std.medipol.edu.tr',
                'name': 'Emre Sahin',
                'student_id': 'STU006',
                'department': 'Computer Engineering',
                'year': '2',
                'skills': ['C++', 'Embedded Systems', 'IoT', 'Arduino'],
            },
            {
                'email': 'deniz.aydin@std.medipol.edu.tr',
                'name': 'Deniz Aydin',
                'student_id': 'STU007',
                'department': 'Health Informatics',
                'year': '3',
                'skills': ['Python', 'R', 'Healthcare Analytics', 'FHIR'],
            },
            {
                'email': 'mert.aktas@std.medipol.edu.tr',
                'name': 'Mert Aktas',
                'student_id': 'STU008',
                'department': 'Computer Engineering',
                'year': 'grad',
                'skills': ['Deep Learning', 'PyTorch', 'Computer Vision', 'NLP'],
            },
            {
                'email': 'aylin.yildiz@std.medipol.edu.tr',
                'name': 'Aylin Yildiz',
                'student_id': 'STU009',
                'department': 'Software Engineering',
                'year': '3',
                'skills': ['Vue.js', 'Python', 'FastAPI', 'Redis'],
            },
            {
                'email': 'oguz.kara@std.medipol.edu.tr',
                'name': 'Oguz Kara',
                'student_id': 'STU010',
                'department': 'Computer Engineering',
                'year': '4',
                'skills': ['Rust', 'Go', 'Microservices', 'gRPC'],
            },
            {
                'email': 'melis.demir@std.medipol.edu.tr',
                'name': 'Melis Demir',
                'student_id': 'STU011',
                'department': 'Health Informatics',
                'year': '2',
                'skills': ['Python', 'Pandas', 'Scikit-learn', 'Healthcare Data'],
            },
            {
                'email': 'kaan.turk@std.medipol.edu.tr',
                'name': 'Kaan Turk',
                'student_id': 'STU012',
                'department': 'Information Systems',
                'year': '4',
                'skills': ['SQL', 'Power BI', 'Tableau', 'ETL'],
            },
            {
                'email': 'defne.aksoy@std.medipol.edu.tr',
                'name': 'Defne Aksoy',
                'student_id': 'STU013',
                'department': 'Computer Engineering',
                'year': '3',
                'skills': ['Swift', 'iOS Development', 'SwiftUI', 'CoreML'],
            },
            {
                'email': 'arda.sen@std.medipol.edu.tr',
                'name': 'Arda Sen',
                'student_id': 'STU014',
                'department': 'Software Engineering',
                'year': '2',
                'skills': ['Kotlin', 'Android', 'Jetpack Compose', 'Room'],
            },
            {
                'email': 'irem.bozkurt@std.medipol.edu.tr',
                'name': 'Irem Bozkurt',
                'student_id': 'STU015',
                'department': 'Computer Engineering',
                'year': 'grad',
                'skills': ['Kubernetes', 'AWS', 'Terraform', 'CI/CD'],
            },
            {
                'email': 'baris.ozkan@std.medipol.edu.tr',
                'name': 'Baris Ozkan',
                'student_id': 'STU016',
                'department': 'Information Systems',
                'year': '3',
                'skills': ['Blockchain', 'Solidity', 'Web3.js', 'Smart Contracts'],
            },
        ]

        student_users = []
        for data in student_data:
            user, created = User.objects.get_or_create(
                email=data['email'],
                defaults={
                    'name': data['name'],
                    'user_type': 'student',
                    'is_active': True,
                }
            )
            if created:
                user.set_password('password123')
                user.save()

            student, _ = Student.objects.get_or_create(
                user=user,
                defaults={
                    'student_id': data['student_id'],
                    'department': data['department'],
                    'year': data['year'],
                    'skills': data['skills'],
                }
            )
            student_users.append(student)
            self.stdout.write(f'  Created student: {data["name"]}')

        return student_users

    def create_projects(self, students, faculty):
        """Create sample projects."""
        project_data = [
            {
                'title': 'AI-Powered Health Diagnosis Assistant',
                'description': 'A mobile application that uses machine learning to help users understand their symptoms and get preliminary health assessments. The app will use NLP to analyze symptom descriptions and provide relevant health information.',
                'category': 'ai',
                'status': 'in_progress',
                'owner_idx': 0,
                'supervisor_idx': 0,
                'required_skills': ['Python', 'Machine Learning', 'Flutter', 'NLP'],
                'max_team_size': 4,
                'expected_duration': '6 months',
                'tags': ['healthcare', 'AI', 'mobile', 'NLP'],
            },
            {
                'title': 'Campus Event Management System',
                'description': 'A comprehensive web platform for managing university events, including registration, ticketing, and attendance tracking. Students can discover events, RSVP, and receive notifications.',
                'category': 'web',
                'status': 'in_progress',
                'owner_idx': 1,
                'supervisor_idx': 1,
                'required_skills': ['React', 'Node.js', 'PostgreSQL', 'Docker'],
                'max_team_size': 5,
                'expected_duration': '4 months',
                'tags': ['web', 'events', 'university', 'management'],
            },
            {
                'title': 'Smart Library Book Recommendation',
                'description': 'A recommendation system for the university library that suggests books based on student interests, course requirements, and reading history. Uses collaborative filtering and content-based algorithms.',
                'category': 'ai',
                'status': 'draft',
                'owner_idx': 3,
                'supervisor_idx': 2,
                'required_skills': ['Python', 'Machine Learning', 'Data Analysis', 'Django'],
                'max_team_size': 3,
                'expected_duration': '3 months',
                'tags': ['recommendation', 'library', 'machine-learning'],
            },
            {
                'title': 'IoT-Based Smart Classroom',
                'description': 'An IoT solution for smart classroom management including automated attendance, environmental monitoring (temperature, humidity, CO2), and energy optimization.',
                'category': 'engineering',
                'status': 'in_progress',
                'owner_idx': 5,
                'supervisor_idx': 0,
                'required_skills': ['Embedded Systems', 'IoT', 'Python', 'Arduino'],
                'max_team_size': 4,
                'expected_duration': '5 months',
                'tags': ['IoT', 'smart-campus', 'embedded', 'sensors'],
            },
            {
                'title': 'Student Mental Health Tracker',
                'description': 'A mobile app designed to help students track their mental health, mood patterns, and connect with campus counseling services when needed. Features include mood journaling, stress assessments, and resources.',
                'category': 'health',
                'status': 'completed',
                'owner_idx': 6,
                'supervisor_idx': 2,
                'required_skills': ['Flutter', 'Firebase', 'UI/UX Design', 'Healthcare Analytics'],
                'max_team_size': 3,
                'expected_duration': '4 months',
                'tags': ['mental-health', 'wellness', 'mobile', 'healthcare'],
            },
            {
                'title': 'Blockchain-Based Certificate Verification',
                'description': 'A decentralized system for issuing and verifying academic certificates and transcripts using blockchain technology. Prevents fraud and simplifies verification for employers.',
                'category': 'research',
                'status': 'draft',
                'owner_idx': 7,
                'supervisor_idx': 1,
                'required_skills': ['Blockchain', 'Solidity', 'Web3', 'Node.js'],
                'max_team_size': 4,
                'expected_duration': '6 months',
                'tags': ['blockchain', 'security', 'verification', 'academic'],
            },
            {
                'title': 'AR Campus Navigation',
                'description': 'An augmented reality mobile application to help new students and visitors navigate the campus. Uses AR markers and GPS to provide indoor and outdoor navigation.',
                'category': 'mobile',
                'status': 'in_progress',
                'owner_idx': 2,
                'supervisor_idx': 0,
                'required_skills': ['Flutter', 'ARCore', 'Unity', 'Firebase'],
                'max_team_size': 4,
                'expected_duration': '5 months',
                'tags': ['AR', 'navigation', 'mobile', 'campus'],
            },
            {
                'title': 'Online Exam Proctoring System',
                'description': 'A secure online examination system with AI-powered proctoring features including face recognition, eye tracking, and suspicious behavior detection.',
                'category': 'ai',
                'status': 'completed',
                'owner_idx': 4,
                'supervisor_idx': 0,
                'required_skills': ['Python', 'Computer Vision', 'Deep Learning', 'Django'],
                'max_team_size': 5,
                'expected_duration': '6 months',
                'tags': ['proctoring', 'AI', 'education', 'security'],
            },
            {
                'title': 'E-Commerce Platform for Student Marketplace',
                'description': 'A platform where students can buy, sell, and trade used textbooks, electronics, and other items. Features include secure payments, messaging, and reputation system.',
                'category': 'web',
                'status': 'in_progress',
                'owner_idx': 8,
                'supervisor_idx': 1,
                'required_skills': ['Vue.js', 'FastAPI', 'PostgreSQL', 'Redis'],
                'max_team_size': 4,
                'expected_duration': '4 months',
                'tags': ['e-commerce', 'marketplace', 'students', 'web'],
            },
            {
                'title': 'Medical Image Analysis Tool',
                'description': 'A deep learning-based tool for analyzing medical images (X-rays, MRIs) to assist radiologists in detecting abnormalities. Focuses on chest X-ray analysis for common conditions.',
                'category': 'health',
                'status': 'in_progress',
                'owner_idx': 10,
                'supervisor_idx': 3,
                'required_skills': ['Python', 'TensorFlow', 'Medical Imaging', 'CNN'],
                'max_team_size': 3,
                'expected_duration': '8 months',
                'tags': ['medical', 'deep-learning', 'imaging', 'healthcare'],
            },
            {
                'title': 'Campus Security Alert System',
                'description': 'A real-time security alert system for campus emergencies. Includes mobile app notifications, location-based alerts, and integration with campus security systems.',
                'category': 'mobile',
                'status': 'draft',
                'owner_idx': 9,
                'supervisor_idx': 4,
                'required_skills': ['Go', 'React Native', 'Firebase', 'WebSockets'],
                'max_team_size': 5,
                'expected_duration': '5 months',
                'tags': ['security', 'mobile', 'alerts', 'campus'],
            },
            {
                'title': 'Sustainable Campus Energy Dashboard',
                'description': 'A dashboard to monitor and visualize energy consumption across campus buildings. Includes predictive analytics for energy optimization and carbon footprint tracking.',
                'category': 'engineering',
                'status': 'in_progress',
                'owner_idx': 11,
                'supervisor_idx': 6,
                'required_skills': ['Power BI', 'Python', 'SQL', 'IoT'],
                'max_team_size': 3,
                'expected_duration': '4 months',
                'tags': ['sustainability', 'energy', 'dashboard', 'analytics'],
            },
            {
                'title': 'iOS Study Group Finder',
                'description': 'An iOS app to help students find study partners and form study groups based on courses, availability, and location preferences.',
                'category': 'mobile',
                'status': 'in_progress',
                'owner_idx': 12,
                'supervisor_idx': 5,
                'required_skills': ['Swift', 'iOS', 'Firebase', 'UI/UX'],
                'max_team_size': 3,
                'expected_duration': '3 months',
                'tags': ['iOS', 'study', 'social', 'mobile'],
            },
            {
                'title': 'DevOps Pipeline Automation Tool',
                'description': 'A tool to automate CI/CD pipeline creation and management for student projects. Supports multiple cloud providers and includes monitoring and alerting.',
                'category': 'engineering',
                'status': 'completed',
                'owner_idx': 14,
                'supervisor_idx': 1,
                'required_skills': ['Kubernetes', 'Terraform', 'GitHub Actions', 'AWS'],
                'max_team_size': 2,
                'expected_duration': '3 months',
                'tags': ['devops', 'automation', 'cloud', 'CI/CD'],
            },
            {
                'title': 'Decentralized Voting System',
                'description': 'A blockchain-based voting system for student union elections. Ensures transparency, anonymity, and tamper-proof results using smart contracts.',
                'category': 'research',
                'status': 'draft',
                'owner_idx': 15,
                'supervisor_idx': 4,
                'required_skills': ['Solidity', 'Ethereum', 'React', 'Web3.js'],
                'max_team_size': 4,
                'expected_duration': '5 months',
                'tags': ['blockchain', 'voting', 'democracy', 'smart-contracts'],
            },
        ]

        projects = []
        today = date.today()

        for i, data in enumerate(project_data):
            project, created = Project.objects.get_or_create(
                title=data['title'],
                defaults={
                    'description': data['description'],
                    'category': data['category'],
                    'status': data['status'],
                    'owner': students[data['owner_idx']],
                    'supervisor': faculty[data['supervisor_idx']],
                    'required_skills': data['required_skills'],
                    'max_team_size': data['max_team_size'],
                    'start_date': today - timedelta(days=30 * (i % 4)),
                    'expected_duration': data['expected_duration'],
                    'tags': data['tags'],
                }
            )
            projects.append(project)
            if created:
                self.stdout.write(f'  Created project: {data["title"]}')

        return projects

    def create_teams_and_memberships(self, projects, students):
        """Create teams and team memberships for projects."""
        team_configs = [
            {'project_idx': 0, 'members': [0, 2, 3], 'roles': ['owner', 'member', 'member']},
            {'project_idx': 1, 'members': [1, 4], 'roles': ['owner', 'member']},
            {'project_idx': 3, 'members': [5, 6], 'roles': ['owner', 'contributor']},
            {'project_idx': 4, 'members': [6, 2], 'roles': ['owner', 'member']},
            {'project_idx': 6, 'members': [2, 3, 5], 'roles': ['owner', 'member', 'contributor']},
            {'project_idx': 7, 'members': [4, 7, 1], 'roles': ['owner', 'member', 'member']},
            {'project_idx': 8, 'members': [8, 9], 'roles': ['owner', 'member']},  # E-Commerce
            {'project_idx': 9, 'members': [10, 6], 'roles': ['owner', 'contributor']},  # Medical Image
            {'project_idx': 11, 'members': [11, 5], 'roles': ['owner', 'member']},  # Energy Dashboard
            {'project_idx': 12, 'members': [12, 13], 'roles': ['owner', 'member']},  # iOS Study Group
            {'project_idx': 13, 'members': [14], 'roles': ['owner']},  # DevOps Tool
            {'project_idx': 14, 'members': [15, 7], 'roles': ['owner', 'member']},  # Voting System
        ]

        for config in team_configs:
            project = projects[config['project_idx']]
            team, created = Team.objects.get_or_create(
                project=project,
                defaults={'max_members': project.max_team_size}
            )

            if created:
                for member_idx, role in zip(config['members'], config['roles']):
                    student = students[member_idx]
                    TeamMembership.objects.get_or_create(
                        team=team,
                        student=student,
                        defaults={'role': role}
                    )
                    team.members.add(student)

                self.stdout.write(f'  Created team for: {project.title}')

    def create_milestones(self, projects):
        """Create milestones for projects."""
        today = date.today()

        milestone_configs = [
            {'project_idx': 0, 'milestones': [
                ('Requirements Analysis', -30, True),
                ('Dataset Collection', -15, True),
                ('Model Training', 15, False),
                ('Mobile App Development', 45, False),
                ('Testing & Deployment', 75, False),
            ]},
            {'project_idx': 1, 'milestones': [
                ('UI/UX Design', -20, True),
                ('Backend API Development', -5, True),
                ('Frontend Implementation', 20, False),
                ('Integration Testing', 40, False),
            ]},
            {'project_idx': 3, 'milestones': [
                ('Hardware Setup', -25, True),
                ('Sensor Integration', -10, False),
                ('Data Pipeline', 10, False),
                ('Dashboard Development', 30, False),
            ]},
            {'project_idx': 6, 'milestones': [
                ('AR Framework Setup', -15, True),
                ('Campus Mapping', 0, False),
                ('Navigation Algorithm', 20, False),
                ('User Testing', 45, False),
            ]},
            {'project_idx': 8, 'milestones': [
                ('Database Design', -20, True),
                ('User Authentication', -10, True),
                ('Product Listing Feature', 5, False),
                ('Payment Integration', 25, False),
            ]},
            {'project_idx': 9, 'milestones': [
                ('Dataset Preparation', -25, True),
                ('Model Architecture Design', -15, True),
                ('Initial Training', 0, False),
                ('Model Optimization', 20, False),
                ('Clinical Validation', 45, False),
            ]},
            {'project_idx': 12, 'milestones': [
                ('App Design Complete', -12, True),
                ('Core Features Implementation', 5, False),
                ('Matching Algorithm', 15, False),
                ('Beta Testing', 30, False),
            ]},
        ]

        for config in milestone_configs:
            project = projects[config['project_idx']]
            for desc, days_offset, completed in config['milestones']:
                Milestone.objects.get_or_create(
                    project=project,
                    description=desc,
                    defaults={
                        'due_date': today + timedelta(days=days_offset),
                        'is_completed': completed,
                        'completed_date': today + timedelta(days=days_offset - 2) if completed else None,
                    }
                )
            self.stdout.write(f'  Created milestones for: {project.title}')

    def create_join_requests(self, projects, students):
        """Create sample join requests."""
        request_configs = [
            {'project_idx': 0, 'student_idx': 4, 'status': 'pending',
             'message': 'I am very interested in AI and healthcare. I have experience with NLP from my previous coursework.'},
            {'project_idx': 0, 'student_idx': 7, 'status': 'approved',
             'message': 'I would love to contribute my deep learning expertise to this project.'},
            {'project_idx': 1, 'student_idx': 2, 'status': 'pending',
             'message': 'I can help with the mobile app version of the event system.'},
            {'project_idx': 2, 'student_idx': 0, 'status': 'pending',
             'message': 'This aligns with my interest in recommendation systems.'},
            {'project_idx': 3, 'student_idx': 7, 'status': 'rejected',
             'message': 'I am curious about IoT applications.',
             'response': 'Thank you for your interest, but we are looking for students with embedded systems experience.'},
            {'project_idx': 6, 'student_idx': 6, 'status': 'approved',
             'message': 'I can contribute to the healthcare-related features of the navigation app.'},
            {'project_idx': 8, 'student_idx': 11, 'status': 'pending',
             'message': 'I have experience with data analytics and could help with user behavior analysis.'},
            {'project_idx': 9, 'student_idx': 7, 'status': 'approved',
             'message': 'My deep learning experience would be valuable for the medical imaging project.'},
            {'project_idx': 10, 'student_idx': 8, 'status': 'pending',
             'message': 'I am interested in campus security systems and have experience with real-time notifications.'},
            {'project_idx': 12, 'student_idx': 2, 'status': 'pending',
             'message': 'I can help with the UI/UX design for the iOS app.'},
            {'project_idx': 14, 'student_idx': 0, 'status': 'pending',
             'message': 'I am interested in blockchain technology and would love to contribute to the voting system.'},
        ]

        for config in request_configs:
            project = projects[config['project_idx']]
            student = students[config['student_idx']]

            defaults = {
                'status': config['status'],
                'message': config['message'],
            }
            if config['status'] == 'rejected':
                defaults['response_message'] = config.get('response', '')

            JoinRequest.objects.get_or_create(
                project=project,
                student=student,
                defaults=defaults
            )
        self.stdout.write('  Created join requests')

    def create_feedback(self, projects, faculty):
        """Create faculty feedback for projects."""
        feedback_configs = [
            {'project_idx': 0, 'faculty_idx': 0,
             'comment': 'Excellent progress on the AI model. Consider adding more diverse training data for better accuracy.'},
            {'project_idx': 1, 'faculty_idx': 1,
             'comment': 'Good architecture choices. Make sure to implement proper authentication and rate limiting.'},
            {'project_idx': 4, 'faculty_idx': 2,
             'comment': 'Outstanding work! The app has received positive feedback from the counseling department.'},
            {'project_idx': 7, 'faculty_idx': 0,
             'comment': 'The proctoring system is working well. Consider adding support for multiple camera angles.'},
            {'project_idx': 8, 'faculty_idx': 1,
             'comment': 'The marketplace concept is solid. Focus on building trust features like user verification and ratings.'},
            {'project_idx': 9, 'faculty_idx': 3,
             'comment': 'Impressive work on the medical imaging pipeline. The preprocessing approach is well-documented.'},
            {'project_idx': 11, 'faculty_idx': 6,
             'comment': 'The dashboard visualizations are clear and informative. Consider adding export functionality.'},
            {'project_idx': 12, 'faculty_idx': 5,
             'comment': 'The matching algorithm shows promise. Test with a larger user base before launch.'},
            {'project_idx': 13, 'faculty_idx': 1,
             'comment': 'Excellent DevOps practices demonstrated. The documentation is comprehensive and well-structured.'},
            {'project_idx': 14, 'faculty_idx': 4,
             'comment': 'The blockchain implementation is secure. Consider gas optimization for the smart contracts.'},
        ]

        for config in feedback_configs:
            project = projects[config['project_idx']]
            faculty_member = faculty[config['faculty_idx']]

            Feedback.objects.get_or_create(
                project=project,
                faculty=faculty_member,
                defaults={'comments': config['comment']}
            )
        self.stdout.write('  Created faculty feedback')

    def create_tasks(self, projects, students):
        """Create tasks for projects."""
        today = date.today()

        task_configs = [
            # AI Health Diagnosis project tasks
            {'project_idx': 0, 'tasks': [
                {'title': 'Set up development environment', 'description': 'Install Python, TensorFlow, and Flutter SDK', 'status': 'completed', 'priority': 'high', 'assignee_idx': 0, 'days_offset': -20},
                {'title': 'Design database schema', 'description': 'Create ERD for patient data and symptoms', 'status': 'completed', 'priority': 'high', 'assignee_idx': 2, 'days_offset': -15},
                {'title': 'Collect training dataset', 'description': 'Gather medical symptom data from open sources', 'status': 'in_progress', 'priority': 'medium', 'assignee_idx': 3, 'days_offset': 5},
                {'title': 'Build NLP preprocessing pipeline', 'description': 'Tokenization, stemming, and entity extraction', 'status': 'todo', 'priority': 'high', 'assignee_idx': 0, 'days_offset': 10},
                {'title': 'Create Flutter UI mockups', 'description': 'Design main screens and navigation flow', 'status': 'in_progress', 'priority': 'medium', 'assignee_idx': 2, 'days_offset': 7},
            ]},
            # Campus Event Management tasks
            {'project_idx': 1, 'tasks': [
                {'title': 'Set up React project structure', 'description': 'Initialize Create React App with TypeScript', 'status': 'completed', 'priority': 'high', 'assignee_idx': 1, 'days_offset': -25},
                {'title': 'Design REST API endpoints', 'description': 'Document all API endpoints for events CRUD', 'status': 'completed', 'priority': 'high', 'assignee_idx': 4, 'days_offset': -20},
                {'title': 'Implement user authentication', 'description': 'JWT-based auth with refresh tokens', 'status': 'completed', 'priority': 'urgent', 'assignee_idx': 1, 'days_offset': -10},
                {'title': 'Build event listing page', 'description': 'Display events with filters and search', 'status': 'in_progress', 'priority': 'high', 'assignee_idx': 4, 'days_offset': 3},
                {'title': 'Add event registration feature', 'description': 'Allow students to RSVP to events', 'status': 'todo', 'priority': 'medium', 'assignee_idx': 1, 'days_offset': 15},
            ]},
            # IoT Smart Classroom tasks
            {'project_idx': 3, 'tasks': [
                {'title': 'Order Arduino sensors', 'description': 'Purchase temperature, humidity, and CO2 sensors', 'status': 'completed', 'priority': 'high', 'assignee_idx': 5, 'days_offset': -30},
                {'title': 'Set up Raspberry Pi hub', 'description': 'Configure Pi as central data collection node', 'status': 'completed', 'priority': 'high', 'assignee_idx': 5, 'days_offset': -20},
                {'title': 'Write sensor data collection code', 'description': 'Arduino code to read and transmit sensor data', 'status': 'in_progress', 'priority': 'high', 'assignee_idx': 6, 'days_offset': 0},
                {'title': 'Build data visualization dashboard', 'description': 'Real-time charts using Chart.js', 'status': 'todo', 'priority': 'medium', 'assignee_idx': 5, 'days_offset': 20},
            ]},
            # AR Campus Navigation tasks
            {'project_idx': 6, 'tasks': [
                {'title': 'Research ARCore capabilities', 'description': 'Evaluate AR frameworks for indoor navigation', 'status': 'completed', 'priority': 'high', 'assignee_idx': 2, 'days_offset': -25},
                {'title': 'Map campus buildings', 'description': 'Create 3D models of main buildings', 'status': 'in_progress', 'priority': 'high', 'assignee_idx': 3, 'days_offset': -5},
                {'title': 'Implement AR marker detection', 'description': 'Detect and anchor AR content to markers', 'status': 'in_progress', 'priority': 'medium', 'assignee_idx': 2, 'days_offset': 5},
                {'title': 'Add turn-by-turn navigation', 'description': 'Visual arrows and voice guidance', 'status': 'todo', 'priority': 'high', 'assignee_idx': 5, 'days_offset': 25},
            ]},
            # E-Commerce Marketplace tasks
            {'project_idx': 8, 'tasks': [
                {'title': 'Design product listing schema', 'description': 'Define fields for items: title, price, condition, etc.', 'status': 'completed', 'priority': 'high', 'assignee_idx': 8, 'days_offset': -15},
                {'title': 'Implement image upload', 'description': 'Allow sellers to upload product photos', 'status': 'in_progress', 'priority': 'medium', 'assignee_idx': 8, 'days_offset': 0},
                {'title': 'Build messaging system', 'description': 'In-app chat between buyers and sellers', 'status': 'todo', 'priority': 'high', 'assignee_idx': 8, 'days_offset': 10},
            ]},
            # Medical Image Analysis tasks
            {'project_idx': 9, 'tasks': [
                {'title': 'Collect X-ray dataset', 'description': 'Download NIH ChestX-ray dataset', 'status': 'completed', 'priority': 'urgent', 'assignee_idx': 10, 'days_offset': -20},
                {'title': 'Preprocess images', 'description': 'Resize, normalize, and augment images', 'status': 'completed', 'priority': 'high', 'assignee_idx': 10, 'days_offset': -10},
                {'title': 'Train CNN model', 'description': 'Train ResNet50 for abnormality detection', 'status': 'in_progress', 'priority': 'high', 'assignee_idx': 10, 'days_offset': 5},
                {'title': 'Create evaluation metrics', 'description': 'Implement precision, recall, F1 score', 'status': 'todo', 'priority': 'medium', 'assignee_idx': 10, 'days_offset': 20},
            ]},
            # iOS Study Group Finder tasks
            {'project_idx': 12, 'tasks': [
                {'title': 'Design app wireframes', 'description': 'Create Figma mockups for all screens', 'status': 'completed', 'priority': 'high', 'assignee_idx': 12, 'days_offset': -18},
                {'title': 'Set up Firebase project', 'description': 'Configure Firestore and Authentication', 'status': 'completed', 'priority': 'high', 'assignee_idx': 12, 'days_offset': -12},
                {'title': 'Build profile creation flow', 'description': 'Allow students to add courses and availability', 'status': 'in_progress', 'priority': 'high', 'assignee_idx': 12, 'days_offset': 0},
                {'title': 'Implement matching algorithm', 'description': 'Find compatible study partners', 'status': 'todo', 'priority': 'high', 'assignee_idx': 12, 'days_offset': 14},
            ]},
        ]

        for config in task_configs:
            project = projects[config['project_idx']]
            for task_data in config['tasks']:
                assignee = students[task_data['assignee_idx']] if task_data.get('assignee_idx') is not None else None
                Task.objects.get_or_create(
                    project=project,
                    title=task_data['title'],
                    defaults={
                        'description': task_data['description'],
                        'status': task_data['status'],
                        'priority': task_data['priority'],
                        'assignee': assignee,
                        'due_date': today + timedelta(days=task_data['days_offset']),
                    }
                )
            self.stdout.write(f'  Created tasks for: {project.title}')

    def create_meetings(self, projects, students):
        """Create meetings for projects."""
        now = timezone.now()

        meeting_configs = [
            # AI Health project meetings
            {'project_idx': 0, 'meetings': [
                {'title': 'Weekly Sprint Review', 'description': 'Review progress and plan next week', 'days_offset': -7, 'location': 'Engineering Building Room 301', 'participants': [0, 2, 3]},
                {'title': 'Model Architecture Discussion', 'description': 'Decide on neural network architecture', 'days_offset': 3, 'location': '', 'meeting_link': 'https://meet.google.com/abc-defg-hij', 'participants': [0, 3]},
                {'title': 'UI/UX Review Session', 'description': 'Review Flutter app designs', 'days_offset': 7, 'location': 'Library Meeting Room 2', 'participants': [0, 2]},
            ]},
            # Campus Event Management meetings
            {'project_idx': 1, 'meetings': [
                {'title': 'Backend API Planning', 'description': 'Define API contracts and database schema', 'days_offset': -14, 'location': 'Tech Hub Room 102', 'participants': [1, 4]},
                {'title': 'Frontend Integration Meeting', 'description': 'Connect React frontend to backend APIs', 'days_offset': 5, 'location': '', 'meeting_link': 'https://zoom.us/j/123456789', 'participants': [1, 4]},
            ]},
            # IoT Smart Classroom meetings
            {'project_idx': 3, 'meetings': [
                {'title': 'Hardware Setup Session', 'description': 'Assemble and test sensor array', 'days_offset': -10, 'location': 'Electronics Lab', 'participants': [5, 6]},
                {'title': 'Data Pipeline Review', 'description': 'Review data flow from sensors to dashboard', 'days_offset': 8, 'location': 'Engineering Building Room 205', 'participants': [5, 6]},
            ]},
            # AR Navigation meetings
            {'project_idx': 6, 'meetings': [
                {'title': 'Campus Mapping Field Trip', 'description': 'Walk campus and collect AR marker locations', 'days_offset': 2, 'location': 'Main Campus Entrance', 'participants': [2, 3, 5]},
                {'title': 'AR Testing Session', 'description': 'Test AR features in various lighting conditions', 'days_offset': 12, 'location': 'Library Atrium', 'participants': [2, 3]},
            ]},
            # Medical Image Analysis meetings
            {'project_idx': 9, 'meetings': [
                {'title': 'Dataset Review with Supervisor', 'description': 'Review dataset quality with faculty advisor', 'days_offset': 4, 'location': 'Health Sciences Building Room 401', 'participants': [10]},
                {'title': 'Model Evaluation Meeting', 'description': 'Analyze model performance metrics', 'days_offset': 15, 'location': '', 'meeting_link': 'https://teams.microsoft.com/meeting123', 'participants': [10]},
            ]},
        ]

        for config in meeting_configs:
            project = projects[config['project_idx']]
            for meeting_data in config['meetings']:
                meeting, created = Meeting.objects.get_or_create(
                    project=project,
                    title=meeting_data['title'],
                    defaults={
                        'description': meeting_data['description'],
                        'date_time': now + timedelta(days=meeting_data['days_offset']),
                        'location': meeting_data.get('location', ''),
                        'meeting_link': meeting_data.get('meeting_link', ''),
                    }
                )
                if created:
                    for participant_idx in meeting_data['participants']:
                        meeting.participants.add(students[participant_idx])
            self.stdout.write(f'  Created meetings for: {project.title}')

    def create_conversations_and_messages(self, students, faculty):
        """Create conversations and messages between users."""
        now = timezone.now()

        # Get user objects from students and faculty
        student_users = [s.user for s in students]
        faculty_users = [f.user for f in faculty]

        conversation_configs = [
            # Student to student conversations
            {
                'participants': [student_users[0], student_users[2]],  # Zeynep and Elif
                'is_group': False,
                'messages': [
                    {'sender_idx': 0, 'content': 'Hey Elif! How is the Flutter UI coming along?', 'hours_ago': 48},
                    {'sender_idx': 1, 'content': 'Hi Zeynep! Making good progress. I finished the home screen design.', 'hours_ago': 47},
                    {'sender_idx': 0, 'content': 'That sounds great! Can you share the Figma link?', 'hours_ago': 46},
                    {'sender_idx': 1, 'content': 'Sure! I will send it over tonight after I make some final tweaks.', 'hours_ago': 45},
                    {'sender_idx': 0, 'content': 'Perfect, thanks!', 'hours_ago': 44},
                ]
            },
            {
                'participants': [student_users[1], student_users[4]],  # Burak and Selin
                'is_group': False,
                'messages': [
                    {'sender_idx': 0, 'content': 'Selin, did you review the API documentation I sent?', 'hours_ago': 24},
                    {'sender_idx': 1, 'content': 'Yes! The endpoints look good. I have a few suggestions for the error handling.', 'hours_ago': 23},
                    {'sender_idx': 0, 'content': 'Great, let us discuss in tomorrow meeting.', 'hours_ago': 22},
                ]
            },
            # Student to faculty conversation
            {
                'participants': [student_users[0], faculty_users[0]],  # Zeynep and Prof. Mehmet
                'is_group': False,
                'messages': [
                    {'sender_idx': 0, 'content': 'Prof. Yildiz, I have a question about the model architecture.', 'hours_ago': 72},
                    {'sender_idx': 1, 'content': 'Of course, Zeynep. What would you like to know?', 'hours_ago': 70},
                    {'sender_idx': 0, 'content': 'Should we use BERT or a simpler model for symptom classification?', 'hours_ago': 69},
                    {'sender_idx': 1, 'content': 'For your use case, I would recommend starting with a simpler model like BiLSTM. You can always try BERT later if needed.', 'hours_ago': 68},
                    {'sender_idx': 0, 'content': 'That makes sense. Thank you for the guidance!', 'hours_ago': 67},
                ]
            },
            {
                'participants': [student_users[5], faculty_users[0]],  # Emre and Prof. Mehmet
                'is_group': False,
                'messages': [
                    {'sender_idx': 0, 'content': 'Hello Professor, the IoT sensors arrived today!', 'hours_ago': 36},
                    {'sender_idx': 1, 'content': 'Excellent news! When can you start the integration?', 'hours_ago': 35},
                    {'sender_idx': 0, 'content': 'We plan to start this weekend. The lab is available Saturday.', 'hours_ago': 34},
                    {'sender_idx': 1, 'content': 'Good. Send me photos of the setup when you are done.', 'hours_ago': 33},
                ]
            },
            # Group conversation for project team
            {
                'participants': [student_users[0], student_users[2], student_users[3]],  # AI Health team
                'is_group': True,
                'name': 'AI Health Project Team',
                'messages': [
                    {'sender_idx': 0, 'content': 'Team meeting tomorrow at 2 PM. Everyone available?', 'hours_ago': 20},
                    {'sender_idx': 1, 'content': 'I will be there!', 'hours_ago': 19},
                    {'sender_idx': 2, 'content': 'Works for me too.', 'hours_ago': 18},
                    {'sender_idx': 0, 'content': 'Great! I will book the meeting room.', 'hours_ago': 17},
                    {'sender_idx': 1, 'content': 'Should I prepare the UI mockups presentation?', 'hours_ago': 16},
                    {'sender_idx': 0, 'content': 'Yes please! That would be helpful.', 'hours_ago': 15},
                ]
            },
            {
                'participants': [student_users[2], student_users[3], student_users[5]],  # AR Navigation team
                'is_group': True,
                'name': 'AR Navigation Team Chat',
                'messages': [
                    {'sender_idx': 0, 'content': 'Has anyone tested the AR markers in low light?', 'hours_ago': 12},
                    {'sender_idx': 1, 'content': 'Not yet. We should do that before the demo.', 'hours_ago': 11},
                    {'sender_idx': 2, 'content': 'I can test it tonight in the library.', 'hours_ago': 10},
                    {'sender_idx': 0, 'content': 'Perfect! Let us know how it goes.', 'hours_ago': 9},
                ]
            },
            # More student conversations
            {
                'participants': [student_users[8], student_users[9]],  # Aylin and Oguz
                'is_group': False,
                'messages': [
                    {'sender_idx': 0, 'content': 'Hey Oguz, can you help me with the Go backend?', 'hours_ago': 8},
                    {'sender_idx': 1, 'content': 'Sure! What do you need help with?', 'hours_ago': 7},
                    {'sender_idx': 0, 'content': 'I am having trouble with the gRPC setup.', 'hours_ago': 6},
                    {'sender_idx': 1, 'content': 'I will send you some resources. It is tricky at first but gets easier.', 'hours_ago': 5},
                ]
            },
            {
                'participants': [student_users[10], faculty_users[3]],  # Melis and Prof. Fatma
                'is_group': False,
                'messages': [
                    {'sender_idx': 0, 'content': 'Dr. Ozer, I finished preprocessing the X-ray images.', 'hours_ago': 4},
                    {'sender_idx': 1, 'content': 'Well done, Melis! What augmentation techniques did you use?', 'hours_ago': 3},
                    {'sender_idx': 0, 'content': 'Rotation, flipping, and contrast adjustment.', 'hours_ago': 2},
                    {'sender_idx': 1, 'content': 'Good choices. Make sure to document your preprocessing pipeline.', 'hours_ago': 1},
                ]
            },
        ]

        for config in conversation_configs:
            participants = config['participants']

            # Create conversation
            conversation = Conversation.objects.create(
                is_group=config['is_group'],
                name=config.get('name', '')
            )
            conversation.participants.add(*participants)

            # Add messages
            for msg in config['messages']:
                sender = participants[msg['sender_idx']]
                Message.objects.create(
                    conversation=conversation,
                    sender=sender,
                    content=msg['content'],
                    created_at=now - timedelta(hours=msg['hours_ago']),
                    is_read=msg['hours_ago'] > 6  # Messages older than 6 hours are read
                )

        self.stdout.write(f'  Created {len(conversation_configs)} conversations with messages')
