from django.urls import path
from . import views

urlpatterns = [
        path("get/", views.gettest , name = "testreq-gettest"),
        path("post/" , views.posttest , name = "testreq-posttest"),
        path("", views.hello, name = "testreq-hello"),
]
