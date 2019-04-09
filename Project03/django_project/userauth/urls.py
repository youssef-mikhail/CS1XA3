from django.urls import path
from . import views

urlpatterns = [
        path('adduser/', views.add_user, name = 'userauth-add_user'),
        path('loginuser/', views.login_user, name = 'userauth-login_user'),
        path('logoutuser/', views.logout_user, name = 'userauth-logout_user'),
        path('userinfo/', views.user_info, name = 'userauth-user_info'),

    ]
    
