from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from .models import Student


class StudentAPITestCase(APITestCase):
    """Test cases for Student API endpoints."""

    def setUp(self):
        """Set up test data."""
        self.student = Student.objects.create(
            first_name="John",
            last_name="Doe",
            email="john.doe@example.com",
            date_of_birth="2000-01-15"
        )
        self.list_url = "/api/v1/students/"
        self.detail_url = f"/api/v1/students/{self.student.id}/"

    def test_list_students(self):
        """Test GET /api/v1/students/ returns all students."""
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_create_student(self):
        """Test POST /api/v1/students/ creates a new student."""
        data = {
            "first_name": "Jane",
            "last_name": "Smith",
            "email": "jane.smith@example.com",
            "date_of_birth": "1999-05-20"
        }
        response = self.client.post(self.list_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Student.objects.count(), 2)
        self.assertEqual(response.data["first_name"], "Jane")

    def test_retrieve_student(self):
        """Test GET /api/v1/students/{id}/ returns a single student."""
        response = self.client.get(self.detail_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["email"], "john.doe@example.com")

    def test_update_student(self):
        """Test PUT /api/v1/students/{id}/ updates a student."""
        data = {
            "first_name": "John",
            "last_name": "Updated",
            "email": "john.updated@example.com",
            "date_of_birth": "2000-01-15"
        }
        response = self.client.put(self.detail_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.student.refresh_from_db()
        self.assertEqual(self.student.last_name, "Updated")

    def test_partial_update_student(self):
        """Test PATCH /api/v1/students/{id}/ partially updates a student."""
        data = {"last_name": "Patched"}
        response = self.client.patch(self.detail_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.student.refresh_from_db()
        self.assertEqual(self.student.last_name, "Patched")

    def test_delete_student(self):
        """Test DELETE /api/v1/students/{id}/ removes a student."""
        response = self.client.delete(self.detail_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Student.objects.count(), 0)

    def test_create_student_invalid_email(self):
        """Test POST with duplicate email returns 400."""
        data = {
            "first_name": "Duplicate",
            "last_name": "Email",
            "email": "john.doe@example.com",  # Already exists
        }
        response = self.client.post(self.list_url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_retrieve_nonexistent_student(self):
        """Test GET with invalid ID returns 404."""
        response = self.client.get("/api/v1/students/9999/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
