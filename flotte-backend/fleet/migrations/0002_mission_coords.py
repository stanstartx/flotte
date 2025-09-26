from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('fleet', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='mission',
            name='depart_latitude',
            field=models.FloatField(null=True, blank=True),
        ),
        migrations.AddField(
            model_name='mission',
            name='depart_longitude',
            field=models.FloatField(null=True, blank=True),
        ),
        migrations.AddField(
            model_name='mission',
            name='arrivee_latitude',
            field=models.FloatField(null=True, blank=True),
        ),
        migrations.AddField(
            model_name='mission',
            name='arrivee_longitude',
            field=models.FloatField(null=True, blank=True),
        ),
    ]








