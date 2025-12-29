from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q
from .models import Conversation, Message
from .serializers import (
    ConversationListSerializer,
    ConversationDetailSerializer,
    CreateConversationSerializer,
    MessageSerializer,
    SendMessageSerializer
)


class ConversationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing conversations
    """
    permission_classes = [IsAuthenticated]
    queryset = Conversation.objects.all()

    def get_serializer_class(self):
        if self.action == 'list':
            return ConversationListSerializer
        elif self.action == 'create':
            return CreateConversationSerializer
        return ConversationDetailSerializer

    def get_queryset(self):
        """Get only conversations where the user is a participant"""
        user = self.request.user
        return Conversation.objects.filter(participants=user).distinct()

    def retrieve(self, request, *args, **kwargs):
        """Get conversation details and mark messages as read"""
        conversation = self.get_object()

        # Mark all messages in this conversation as read for the current user
        Message.objects.filter(
            conversation=conversation
        ).exclude(
            sender=request.user
        ).update(is_read=True)

        serializer = self.get_serializer(conversation)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """Send a message in a conversation"""
        conversation = self.get_object()

        # Check if user is a participant
        if request.user not in conversation.participants.all():
            return Response(
                {'detail': 'You are not a participant in this conversation.'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = SendMessageSerializer(
            data=request.data,
            context={'conversation_id': conversation.id, 'request': request}
        )
        serializer.is_valid(raise_exception=True)
        message = serializer.save()

        # Update conversation's updated_at timestamp
        conversation.save()

        return Response(
            MessageSerializer(message).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """Get all messages in a conversation with pagination"""
        conversation = self.get_object()

        # Check if user is a participant
        if request.user not in conversation.participants.all():
            return Response(
                {'detail': 'You are not a participant in this conversation.'},
                status=status.HTTP_403_FORBIDDEN
            )

        messages = conversation.messages.all().order_by('-created_at')  # Newest first

        # Apply pagination
        page = self.paginate_queryset(messages)
        if page is not None:
            serializer = MessageSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def find_or_create(self, request):
        """
        Find existing one-on-one conversation or create a new one
        Expects: { "participant_id": <user_id> }
        """
        participant_id = request.data.get('participant_id')

        if not participant_id:
            return Response(
                {'detail': 'participant_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Find existing one-on-one conversation
        conversations = Conversation.objects.filter(
            participants=request.user,
            is_group=False
        ).filter(
            participants__id=participant_id
        ).distinct()

        if conversations.exists():
            conversation = conversations.first()
            serializer = ConversationDetailSerializer(conversation)
            return Response(serializer.data)

        # Create new conversation
        serializer = CreateConversationSerializer(
            data={
                'participant_ids': [participant_id],
                'is_group': False
            },
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        conversation = serializer.save()

        return Response(
            ConversationDetailSerializer(conversation).data,
            status=status.HTTP_201_CREATED
        )


class MessageViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing messages (read-only)
    Messages are created through ConversationViewSet.send_message
    """
    permission_classes = [IsAuthenticated]
    serializer_class = MessageSerializer
    queryset = Message.objects.all()

    def get_queryset(self):
        """Get only messages from conversations where the user is a participant"""
        user = self.request.user
        return Message.objects.filter(
            conversation__participants=user
        ).distinct()

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a specific message as read"""
        message = self.get_object()
        message.mark_as_read()
        return Response({'status': 'message marked as read'})
