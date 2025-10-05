from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from api.models import Restaurant, RestaurantOwner, RestaurantProfile, RestaurantAnalytics, Profile, Reservation, Review
from django.db import transaction
from django.utils import timezone
from datetime import timedelta, time
import random
import unicodedata


NAMES = [
    "Cantina Vermelha", "Bistrô do Chef", "Casa do Sabor", "Ponto do Hamburguer",
    "Pizza da Praça", "Sushi do Bairro", "Churras & Cia", "Veggie Garden",
    "Café da Esquina", "Ramen House", "Pastel & Pimenta", "La Pasta",
]

CATEGORIES = [
    "pizza", "burger", "sushi", "vegan", "coffee", "ramen", "bbq", "italian", "brazilian"
]

FIRST_NAMES = [
    "Ana", "Bruno", "Carla", "Diego", "Eduarda", "Felipe", "Gabriela", "Heitor",
    "Isabela", "João", "Larissa", "Marcos", "Natália", "Otávio", "Paula", "Rafael",
    "Sofia", "Tiago", "Valentina", "Yasmin"
]

LAST_NAMES = [
    "Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Ferreira", "Almeida", "Costa",
    "Gomes", "Ribeiro", "Carvalho", "Lopes", "Barbosa", "Araujo", "Pereira"
]


class Command(BaseCommand):
    help = "Seed N restaurants with owners"

    def add_arguments(self, parser):
        parser.add_argument("count", type=int, nargs="?", default=20, help="How many restaurants to create")
        parser.add_argument("--prefix", type=str, default="seed", help="Username/email prefix for owners (fallback)")
        parser.add_argument("--customers", type=int, default=8, help="How many customers to create per restaurant")
        parser.add_argument("--reviews", type=int, default=3, help="Max reviews to create per restaurant")

    @transaction.atomic
    def handle(self, *args, **options):
        count = options["count"]
        prefix = options["prefix"]
        customers_per_restaurant = max(0, options["customers"])
        max_reviews_per_restaurant = max(0, options["reviews"])

        created = 0
        owner_lines = []
        for i in range(count):
            # Build a real name and username/email from it
            first_name = random.choice(FIRST_NAMES)
            last_name = random.choice(LAST_NAMES)
            full_base = f"{first_name}.{last_name}".lower()
            # Strip accents and non-ascii
            ascii_base = unicodedata.normalize('NFKD', full_base).encode('ascii', 'ignore').decode('ascii')
            ascii_base = ascii_base.replace(' ', '').replace("'", "")
            suffix = f"{i:03d}"
            base = f"{ascii_base}{suffix}"
            username = base
            email = f"{ascii_base}{suffix}@example.com"
            if User.objects.filter(username=username).exists():
                continue

            password = "Passw0rd!"
            user = User.objects.create_user(username=username, email=email, password=password)
            user.first_name = first_name
            user.last_name = last_name
            user.save()
            profile = Profile.objects.create(user=user, referral_code=f"{random.randint(100000,999999)}")

            # Restaurant basics
            name = random.choice(NAMES)
            lat = -23.55 + random.uniform(-0.2, 0.2)
            lng = -46.63 + random.uniform(-0.2, 0.2)
            categories = ",".join(random.sample(CATEGORIES, k=random.randint(1, 3)))
            price_level = random.randint(1, 4)

            restaurant = Restaurant.objects.create(
                name=name,
                address=f"Rua {i+1}, Centro",
                lat=lat,
                lng=lng,
                categories=categories,
                price_level=price_level,
                rating_avg=round(random.uniform(3.0, 4.9), 1),
                rating_count=random.randint(0, 500),
            )

            RestaurantProfile.objects.create(
                restaurant=restaurant,
                description="Restaurante gerado para testes",
                phone=f"+55 11 9{random.randint(1000,9999)}-{random.randint(1000,9999)}",
                email=email,
                website="https://forkly.example",
                opening_hours={"monday": {"open": "09:00", "close": "22:00"}},
                average_ticket=round(random.uniform(30, 180), 2),
                capacity=random.randint(20, 120),
                has_delivery=random.choice([True, False]),
                has_takeaway=True,
                has_reservations=True,
                payment_methods=["cash", "credit", "pix"],
                special_features=["wifi", "accessibility"],
            )

            RestaurantOwner.objects.create(user=user, restaurant=restaurant, is_verified=random.choice([True, False]))
            profile.role = "restaurant_owner"
            profile.save()

            RestaurantAnalytics.objects.create(restaurant=restaurant)

            # Create customers for this restaurant
            customers = []
            for c in range(customers_per_restaurant):
                c_base = f"cust_{base}_{c:02d}"
                if User.objects.filter(username=c_base).exists():
                    customers.append(User.objects.get(username=c_base))
                    continue
                c_email = f"{c_base}@example.com"
                c_user = User.objects.create_user(
                    username=c_base,
                    email=c_email,
                    password=password,
                    first_name=random.choice(FIRST_NAMES),
                    last_name=random.choice(LAST_NAMES),
                )
                Profile.objects.create(user=c_user, referral_code=f"{random.randint(100000,999999)}")
                customers.append(c_user)

            # Create reservations in the last 30 days with varied statuses
            statuses = ["pending", "confirmed", "cancelled", "completed", "no_show"]
            for _ in range(random.randint(6, 14)):
                day_offset = random.randint(0, 29)
                date_val = (timezone.now() - timedelta(days=day_offset)).date()
                time_val = time(hour=random.randint(11, 22), minute=random.choice([0, 15, 30, 45]))
                party_size = random.randint(1, 8)
                status = random.choices(statuses, weights=[2, 4, 1, 3, 1], k=1)[0]
                Reservation.objects.create(
                    restaurant=restaurant,
                    customer=random.choice(customers),
                    date=date_val,
                    time=time_val,
                    party_size=party_size,
                    status=status,
                    customer_phone=f"+55 11 9{random.randint(1000,9999)}-{random.randint(1000,9999)}",
                    customer_email="",
                    special_requests=random.choice(["", "Mesa perto da janela", "Cadeira infantil", "Canto mais silencioso"]),
                    estimated_value=restaurant.profile.average_ticket * party_size,
                )

            # Some reviews
            for _ in range(random.randint(0, max_reviews_per_restaurant)):
                Review.objects.create(
                    user=random.choice(customers),
                    restaurant=restaurant,
                    rating=random.randint(3, 5),
                    text=random.choice([
                        "Excelente atendimento e comida!",
                        "Muito bom, voltarei em breve.",
                        "Preço justo e ambiente agradável.",
                        "Poderia melhorar o tempo de espera, mas o sabor compensa.",
                    ]),
                )

            # Update analytics now that there is activity
            restaurant.analytics.update_stats()

            created += 1
            owner_lines.append(f"{user.first_name} {user.last_name} | user: {username} | email: {email} | pass: {password} | restaurant: {restaurant.name}")

        self.stdout.write(self.style.SUCCESS(f"Created {created} restaurants with owners"))
        if owner_lines:
            self.stdout.write("\nSample owner credentials:")
            for line in owner_lines[:10]:
                self.stdout.write(f" - {line}")


