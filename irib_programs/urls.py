from django.contrib import admin
from django.urls import include, path
from django.views.generic import RedirectView

urlpatterns = [
    path("", RedirectView.as_view(url="admin/", permanent=False)),
    path("admin/", admin.site.urls),
    path("api/", include("programs.api.urls")),
    path("channels/<int:channel_id>/schedule/<str:date_str>/", include("programs.urls.timeline_urls")),
]
