from django.core.management.base import BaseCommand
from django.utils.crypto import get_random_string

class Command(BaseCommand):
    help = 'Administrative Commands'

    def add_arguments(self, parser):
        parser.add_argument('option', nargs='+', type=str)


    def generate_secret(self, *args, **options):
        chars = 'abcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*(-_=+)'
        self.stdout.write(self.style.SUCCESS('SECRET KEY: "%s"' % get_random_string(50, chars)))

    def handle(self, *args, **options):
        # self.stdout.write(self.style.SUCCESS("subcommand: " + str(options['subcommand'])))
        # self.stdout.write(self.style.SUCCESS("options: " + str(options)))
        if "generate_secret" in options['option']:
            self.generate_secret()
        else:
            self.stdout.write(self.style.SUCCESS(" "))
            self.stdout.write(self.style.SUCCESS("usage: ./manage.py admin [option]"))
            self.stdout.write(self.style.SUCCESS("example: ./manage.py admin generate_secret"))
            self.stdout.write(self.style.SUCCESS(" "))
            self.stdout.write(self.style.SUCCESS("options "))
            self.stdout.write(self.style.SUCCESS("--------"))
            self.stdout.write(self.style.SUCCESS("generate_secret - generates a new secret key to be replaced in secret.py"))
            self.stdout.write(self.style.SUCCESS(" "))
