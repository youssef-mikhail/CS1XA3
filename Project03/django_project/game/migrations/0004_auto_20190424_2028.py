# Generated by Django 2.1.7 on 2019-04-24 20:28

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('game', '0003_auto_20190420_1731'),
    ]

    operations = [
        migrations.AlterField(
            model_name='battleshipsession',
            name='player1LiveShips',
            field=models.CharField(max_length=25),
        ),
        migrations.AlterField(
            model_name='battleshipsession',
            name='player1SunkShips',
            field=models.CharField(max_length=25),
        ),
        migrations.AlterField(
            model_name='battleshipsession',
            name='player2LiveShips',
            field=models.CharField(max_length=25),
        ),
        migrations.AlterField(
            model_name='battleshipsession',
            name='player2SunkShips',
            field=models.CharField(max_length=25),
        ),
    ]