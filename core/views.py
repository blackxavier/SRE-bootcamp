from rest_framework import viewsets
from .models import Student
from .serializers import StudentSerializer


class StudentViewSet(viewsets.ModelViewSet):
    """
    A ViewSet for viewing and editing student instances.
    Provides: list, create, retrieve, update, partial_update, destroy
    """
    queryset = Student.objects.all()
    serializer_class = StudentSerializer
