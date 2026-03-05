from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db import connection
from .models import Student
from .serializers import StudentSerializer


@api_view(['GET'])
def health_check(request):
    """Health check endpoint for monitoring."""
    health_status = {
        "status": "healthy",
        "version": request.version,
    }

    # Check database connectivity
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        health_status["database"] = "connected"
    except Exception as e:
        health_status["status"] = "unhealthy"
        health_status["database"] = f"error: {str(e)}"
        return Response(health_status, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    return Response(health_status, status=status.HTTP_200_OK)


class StudentViewSet(viewsets.ModelViewSet):
    """
    A ViewSet for viewing and editing student instances.
    Provides: list, create, retrieve, update, partial_update, destroy
    """
    queryset = Student.objects.all()
    serializer_class = StudentSerializer
