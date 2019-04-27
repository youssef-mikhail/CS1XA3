# Generated by Django 2.1.7 on 2019-04-26 23:28

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('game', '0005_auto_20190426_1829'),
    ]

    operations = [
        migrations.AlterField(
            model_name='battleshipsession',
            name='gameWinner',
            field=models.ForeignKey(on_delete=django.db.models.deletion.DO_NOTHING, related_name='winner', to=settings.AUTH_USER_MODEL),
        ),
    ]
