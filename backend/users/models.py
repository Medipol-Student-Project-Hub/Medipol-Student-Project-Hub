from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.core.validators import EmailValidator, FileExtensionValidator
from django.core.exceptions import ValidationError
from django.utils import timezone


def validate_image_size(value):
    """Validate that uploaded image is not larger than 5MB"""
    max_size = 5 * 1024 * 1024  # 5MB
    if value.size > max_size:
        raise ValidationError(f'Image file too large. Maximum size is 5MB, got {value.size / (1024*1024):.2f}MB.')


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Users must have an email address')

        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    USER_TYPE_CHOICES = (
        ('student', 'Student'),
        ('faculty', 'Faculty'),
    )

    email = models.EmailField(max_length=255, unique=True, validators=[EmailValidator()])
    name = models.CharField(max_length=255)
    profile_image = models.ImageField(
        upload_to='profile_images/',
        null=True,
        blank=True,
        validators=[
            FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'gif', 'webp']),
            validate_image_size
        ]
    )
    user_type = models.CharField(max_length=10, choices=USER_TYPE_CHOICES)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name', 'user_type']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-date_joined']

    def __str__(self):
        return f"{self.name} ({self.email})"

    def get_full_name(self):
        return self.name

    def get_short_name(self):
        return self.email


class Student(models.Model):
    YEAR_CHOICES = (
        ('1', 'Freshman (1st Year)'),
        ('2', 'Sophomore (2nd Year)'),
        ('3', 'Junior (3rd Year)'),
        ('4', 'Senior (4th Year)'),
        ('grad', 'Graduate Student'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True, related_name='student_profile')
    student_id = models.CharField(max_length=50, unique=True)
    department = models.CharField(max_length=255)
    faculty = models.CharField(max_length=255, blank=True)  # Faculty name (e.g., "Faculty of Engineering")
    year = models.CharField(max_length=10, choices=YEAR_CHOICES)
    skills = models.JSONField(default=list, blank=True)
    interests = models.JSONField(default=list, blank=True)  # Student interests

    class Meta:
        verbose_name = 'Student'
        verbose_name_plural = 'Students'
        ordering = ['student_id']

    def __str__(self):
        return f"{self.user.name} - {self.student_id}"


class Faculty(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True, related_name='faculty_profile')
    faculty_id = models.CharField(max_length=50, unique=True)
    department = models.CharField(max_length=255)
    faculty = models.CharField(max_length=255, blank=True)  # Faculty name (e.g., "Faculty of Engineering")
    title = models.CharField(max_length=100, blank=True)
    specialization = models.TextField(blank=True)
    office_location = models.CharField(max_length=255, blank=True)
    years_of_experience = models.PositiveIntegerField(default=0)

    class Meta:
        verbose_name = 'Faculty Member'
        verbose_name_plural = 'Faculty Members'
        ordering = ['faculty_id']

    def __str__(self):
        return f"{self.title} {self.user.name}" if self.title else self.user.name
