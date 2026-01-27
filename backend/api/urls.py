# api/urls.py
from django.urls import path, include
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.reverse import reverse
from rest_framework.permissions import AllowAny

class ApiRoot(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []  # 避免 / 401

    def get(self, request, *args, **kwargs):
        return Response({
            "user": reverse('user:api-root', request=request),  # → /user/
            "pet":  reverse('pet:api-root',  request=request),  # → /pet/
        })

urlpatterns = [
    path('', ApiRoot.as_view(), name='api-root'),
    path('user/', include(('apps.user.urls', 'user'), namespace='user')),
    path('pet/',  include(('apps.pet.urls',  'pet'),  namespace='pet')),
]
