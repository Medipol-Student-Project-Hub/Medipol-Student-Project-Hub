from rest_framework import serializers
from .models import Conversation, Message
from users.serializers import UserSerializer


class MessageSerializer(serializers.ModelSerializer):
    """Serializer for Message model"""
    sender_name = serializers.CharField(source='sender.name', read_only=True)
    sender_profile_image = serializers.ImageField(source='sender.profile_image', read_only=True)

    class Meta:
        model = Message
        fields = [
            'id', 'conversation', 'sender', 'sender_name', 'sender_profile_image',
            'content', 'is_read', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'sender', 'created_at', 'updated_at']


class ConversationListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing conversations"""
    last_message = serializers.SerializerMethodField()
    last_message_time = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    other_participant = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id', 'name', 'is_group', 'last_message', 'last_message_time',
            'unread_count', 'other_participant', 'created_at', 'updated_at'
        ]

    def get_last_message(self, obj):
        last_msg = obj.get_last_message()
        return last_msg.content if last_msg else ""

    def get_last_message_time(self, obj):
        last_msg = obj.get_last_message()
        return last_msg.created_at if last_msg else obj.created_at

    def get_unread_count(self, obj):
        user = self.context.get('request').user
        return obj.get_unread_count(user)

    def get_other_participant(self, obj):
        """For one-on-one chats, get the other participant's info"""
        if not obj.is_group:
            user = self.context.get('request').user
            other_users = obj.participants.exclude(id=user.id)
            if other_users.exists():
                other_user = other_users.first()
                return {
                    'id': other_user.id,
                    'name': other_user.name,
                    'email': other_user.email,
                    'profile_image': other_user.profile_image.url if other_user.profile_image else None
                }
        return None


class ConversationDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for conversation with participants"""
    participants = UserSerializer(many=True, read_only=True)
    messages = MessageSerializer(many=True, read_only=True)
    other_participant = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id', 'name', 'participants', 'is_group', 'other_participant',
            'messages', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_other_participant(self, obj):
        """For one-on-one chats, get the other participant's info"""
        if not obj.is_group:
            user = self.context.get('request').user if self.context.get('request') else None
            if user:
                other_users = obj.participants.exclude(id=user.id)
                if other_users.exists():
                    other_user = other_users.first()
                    return {
                        'id': other_user.id,
                        'name': other_user.name,
                        'email': other_user.email,
                        'profile_image': other_user.profile_image.url if other_user.profile_image else None
                    }
        return None


class CreateConversationSerializer(serializers.Serializer):
    """Serializer for creating a new conversation"""
    participant_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1
    )
    name = serializers.CharField(max_length=255, required=False, allow_blank=True)
    is_group = serializers.BooleanField(default=False)
    initial_message = serializers.CharField(required=False, allow_blank=True)

    def create(self, validated_data):
        from users.models import User

        participant_ids = validated_data.pop('participant_ids')
        initial_message = validated_data.pop('initial_message', None)
        request = self.context.get('request')

        # Create conversation
        conversation = Conversation.objects.create(**validated_data)

        # Add participants
        participants = User.objects.filter(id__in=participant_ids)
        conversation.participants.add(*participants)

        # Add creator to participants
        if request and request.user:
            conversation.participants.add(request.user)

        # Send initial message if provided
        if initial_message and request and request.user:
            Message.objects.create(
                conversation=conversation,
                sender=request.user,
                content=initial_message
            )

        return conversation


class SendMessageSerializer(serializers.Serializer):
    """Serializer for sending a message"""
    content = serializers.CharField()

    def create(self, validated_data):
        conversation_id = self.context.get('conversation_id')
        request = self.context.get('request')

        message = Message.objects.create(
            conversation_id=conversation_id,
            sender=request.user,
            content=validated_data['content']
        )
        return message
