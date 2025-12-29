from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from .models import Student, Faculty, Notification

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'name', 'profile_image', 'user_type', 'date_joined']
        read_only_fields = ['id', 'date_joined']


class StudentProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    email = serializers.EmailField(write_only=True, required=False)
    name = serializers.CharField(write_only=True, required=False)
    profile_image = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model = Student
        fields = [
            'user', 'student_id', 'department', 'faculty', 'year', 'skills', 'interests',
            'email', 'name', 'profile_image'
        ]
        read_only_fields = ['user']

    def update(self, instance, validated_data):
        user_data = {}
        for field in ['email', 'name', 'profile_image']:
            if field in validated_data:
                user_data[field] = validated_data.pop(field)

        if user_data:
            for attr, value in user_data.items():
                setattr(instance.user, attr, value)
            instance.user.save()

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        return instance


class FacultyProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    email = serializers.EmailField(write_only=True, required=False)
    name = serializers.CharField(write_only=True, required=False)
    profile_image = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model = Faculty
        fields = [
            'user', 'faculty_id', 'department', 'faculty', 'title', 'specialization',
            'office_location', 'years_of_experience',
            'email', 'name', 'profile_image'
        ]
        read_only_fields = ['user']

    def update(self, instance, validated_data):
        user_data = {}
        for field in ['email', 'name', 'profile_image']:
            if field in validated_data:
                user_data[field] = validated_data.pop(field)

        if user_data:
            for attr, value in user_data.items():
                setattr(instance.user, attr, value)
            instance.user.save()

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        return instance


class StudentRegistrationSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True, required=True)
    name = serializers.CharField(required=True)
    student_id = serializers.CharField(required=True)
    department = serializers.CharField(required=True)
    faculty = serializers.CharField(required=False, allow_blank=True)
    year = serializers.ChoiceField(choices=Student.YEAR_CHOICES, required=True)
    skills = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    interests = serializers.ListField(child=serializers.CharField(), required=False, default=list)

    class Meta:
        model = User
        fields = [
            'email', 'password', 'password_confirm', 'name', 'profile_image',
            'student_id', 'department', 'faculty', 'year', 'skills', 'interests'
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def validate_email(self, value):
        return value

    def create(self, validated_data):
        validated_data.pop('password_confirm')

        student_data = {
            'student_id': validated_data.pop('student_id'),
            'department': validated_data.pop('department'),
            'faculty': validated_data.pop('faculty', ''),
            'year': validated_data.pop('year'),
            'skills': validated_data.pop('skills', []),
            'interests': validated_data.pop('interests', []),
        }

        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            name=validated_data['name'],
            user_type='student',
            profile_image=validated_data.get('profile_image')
        )

        Student.objects.create(user=user, **student_data)

        return user


class FacultyRegistrationSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True, required=True)
    name = serializers.CharField(required=True)
    faculty_id = serializers.CharField(required=True)
    department = serializers.CharField(required=True)
    faculty = serializers.CharField(required=False, allow_blank=True)
    title = serializers.CharField(required=False, allow_blank=True)
    specialization = serializers.CharField(required=False, allow_blank=True)
    office_location = serializers.CharField(required=False, allow_blank=True)
    years_of_experience = serializers.IntegerField(required=False, default=0)

    class Meta:
        model = User
        fields = [
            'email', 'password', 'password_confirm', 'name', 'profile_image',
            'faculty_id', 'department', 'faculty', 'title', 'specialization',
            'office_location', 'years_of_experience'
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')

        faculty_data = {
            'faculty_id': validated_data.pop('faculty_id'),
            'department': validated_data.pop('department'),
            'faculty': validated_data.pop('faculty', ''),
            'title': validated_data.pop('title', ''),
            'specialization': validated_data.pop('specialization', ''),
            'office_location': validated_data.pop('office_location', ''),
            'years_of_experience': validated_data.pop('years_of_experience', 0),
        }

        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            name=validated_data['name'],
            user_type='faculty',
            profile_image=validated_data.get('profile_image')
        )

        Faculty.objects.create(user=user, **faculty_data)

        return user


class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({"new_password": "Password fields didn't match."})
        return attrs


class NotificationSerializer(serializers.ModelSerializer):
    """Serializer for notifications"""
    recipient_name = serializers.CharField(source='recipient.name', read_only=True)

    class Meta:
        model = Notification
        fields = [
            'id', 'recipient', 'recipient_name', 'notification_type',
            'title', 'message', 'link', 'is_read', 'created_at'
        ]
        read_only_fields = ['id', 'created_at', 'recipient_name']
