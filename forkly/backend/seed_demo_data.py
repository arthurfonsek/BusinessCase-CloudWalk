#!/usr/bin/env python3
"""
Demo Data Seeder for FoodieMap
Creates 15-20 restaurants near São Paulo coordinates for testing
"""

import os
import sys
import django
from django.db import transaction

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from api.models import Restaurant, User, Profile, Referral, Review, List, ListItem
import random
import string
from datetime import datetime, timedelta

# São Paulo coordinates (center)
SP_LAT = -23.561
SP_LNG = -46.656

# Demo restaurants data
DEMO_RESTAURANTS = [
    {
        'name': 'Burger King - Paulista',
        'address': 'Av. Paulista, 1000 - Bela Vista, São Paulo',
        'lat': SP_LAT + 0.001,
        'lng': SP_LNG + 0.001,
        'categories': 'fastfood,burger',
        'price_level': 2,
        'rating_avg': 4.2,
        'rating_count': 150
    },
    {
        'name': 'McDonald\'s - Consolação',
        'address': 'Rua da Consolação, 2000 - Consolação, São Paulo',
        'lat': SP_LAT - 0.002,
        'lng': SP_LNG + 0.003,
        'categories': 'fastfood,burger',
        'price_level': 2,
        'rating_avg': 3.8,
        'rating_count': 200
    },
    {
        'name': 'Sushi Yama',
        'address': 'Rua Augusta, 500 - Consolação, São Paulo',
        'lat': SP_LAT + 0.003,
        'lng': SP_LNG - 0.001,
        'categories': 'japanese,sushi',
        'price_level': 4,
        'rating_avg': 4.5,
        'rating_count': 80
    },
    {
        'name': 'Pizza Hut - Centro',
        'address': 'Rua 7 de Abril, 100 - Centro, São Paulo',
        'lat': SP_LAT - 0.001,
        'lng': SP_LNG - 0.002,
        'categories': 'pizza,italian',
        'price_level': 3,
        'rating_avg': 4.0,
        'rating_count': 120
    },
    {
        'name': 'Outback Steakhouse',
        'address': 'Av. Paulista, 2000 - Bela Vista, São Paulo',
        'lat': SP_LAT + 0.004,
        'lng': SP_LNG + 0.002,
        'categories': 'steakhouse,australian',
        'price_level': 4,
        'rating_avg': 4.3,
        'rating_count': 90
    },
    {
        'name': 'Subway - Shopping Center',
        'address': 'Rua Oscar Freire, 800 - Jardins, São Paulo',
        'lat': SP_LAT + 0.005,
        'lng': SP_LNG - 0.003,
        'categories': 'sandwich,healthy',
        'price_level': 2,
        'rating_avg': 3.9,
        'rating_count': 180
    },
    {
        'name': 'Starbucks Coffee',
        'address': 'Av. Paulista, 1500 - Bela Vista, São Paulo',
        'lat': SP_LAT + 0.002,
        'lng': SP_LNG + 0.004,
        'categories': 'coffee,cafe',
        'price_level': 3,
        'rating_avg': 4.1,
        'rating_count': 160
    },
    {
        'name': 'KFC - Liberdade',
        'address': 'Rua da Liberdade, 300 - Liberdade, São Paulo',
        'lat': SP_LAT - 0.003,
        'lng': SP_LNG + 0.005,
        'categories': 'fastfood,chicken',
        'price_level': 2,
        'rating_avg': 3.7,
        'rating_count': 140
    },
    {
        'name': 'Domino\'s Pizza',
        'address': 'Rua das Flores, 400 - Vila Madalena, São Paulo',
        'lat': SP_LAT + 0.006,
        'lng': SP_LNG - 0.004,
        'categories': 'pizza,delivery',
        'price_level': 2,
        'rating_avg': 3.8,
        'rating_count': 110
    },
    {
        'name': 'Taco Bell',
        'address': 'Av. Faria Lima, 1000 - Itaim Bibi, São Paulo',
        'lat': SP_LAT - 0.004,
        'lng': SP_LNG - 0.005,
        'categories': 'mexican,fastfood',
        'price_level': 2,
        'rating_avg': 3.6,
        'rating_count': 95
    },
    {
        'name': 'Pizza Express',
        'address': 'Rua Haddock Lobo, 600 - Cerqueira César, São Paulo',
        'lat': SP_LAT + 0.007,
        'lng': SP_LNG + 0.006,
        'categories': 'pizza,italian',
        'price_level': 3,
        'rating_avg': 4.2,
        'rating_count': 75
    },
    {
        'name': 'Sushi Express',
        'address': 'Rua Bela Cintra, 800 - Jardins, São Paulo',
        'lat': SP_LAT - 0.005,
        'lng': SP_LNG + 0.007,
        'categories': 'japanese,sushi',
        'price_level': 3,
        'rating_avg': 4.4,
        'rating_count': 85
    },
    {
        'name': 'Burger Palace',
        'address': 'Av. Rebouças, 1200 - Pinheiros, São Paulo',
        'lat': SP_LAT + 0.008,
        'lng': SP_LNG - 0.006,
        'categories': 'burger,american',
        'price_level': 3,
        'rating_avg': 4.0,
        'rating_count': 100
    },
    {
        'name': 'Café Central',
        'address': 'Rua da Consolação, 1500 - Consolação, São Paulo',
        'lat': SP_LAT - 0.006,
        'lng': SP_LNG - 0.007,
        'categories': 'cafe,breakfast',
        'price_level': 2,
        'rating_avg': 4.3,
        'rating_count': 70
    },
    {
        'name': 'Sushi Master',
        'address': 'Av. Paulista, 2500 - Bela Vista, São Paulo',
        'lat': SP_LAT + 0.009,
        'lng': SP_LNG + 0.008,
        'categories': 'japanese,sushi',
        'price_level': 4,
        'rating_avg': 4.6,
        'rating_count': 60
    },
    {
        'name': 'Pizza Corner',
        'address': 'Rua Oscar Freire, 1200 - Jardins, São Paulo',
        'lat': SP_LAT - 0.007,
        'lng': SP_LNG + 0.009,
        'categories': 'pizza,italian',
        'price_level': 3,
        'rating_avg': 4.1,
        'rating_count': 90
    },
    {
        'name': 'Burger Joint',
        'address': 'Av. Faria Lima, 2000 - Itaim Bibi, São Paulo',
        'lat': SP_LAT + 0.010,
        'lng': SP_LNG - 0.008,
        'categories': 'burger,american',
        'price_level': 3,
        'rating_avg': 3.9,
        'rating_count': 80
    },
    {
        'name': 'Sushi Bar',
        'address': 'Rua Haddock Lobo, 1000 - Cerqueira César, São Paulo',
        'lat': SP_LAT - 0.008,
        'lng': SP_LNG - 0.009,
        'categories': 'japanese,sushi',
        'price_level': 4,
        'rating_avg': 4.5,
        'rating_count': 55
    },
    {
        'name': 'Pizza House',
        'address': 'Rua Bela Cintra, 1400 - Jardins, São Paulo',
        'lat': SP_LAT + 0.011,
        'lng': SP_LNG + 0.010,
        'categories': 'pizza,italian',
        'price_level': 3,
        'rating_avg': 4.0,
        'rating_count': 105
    },
    {
        'name': 'Burger Spot',
        'address': 'Av. Rebouças, 2000 - Pinheiros, São Paulo',
        'lat': SP_LAT - 0.009,
        'lng': SP_LNG + 0.011,
        'categories': 'burger,fastfood',
        'price_level': 2,
        'rating_avg': 3.8,
        'rating_count': 125
    }
]

def generate_referral_code():
    """Generate a random referral code"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

def create_demo_users():
    """Create demo users with referral codes"""
    users_data = [
        {'username': 'demo_user1', 'email': 'user1@demo.com', 'first_name': 'João', 'last_name': 'Silva'},
        {'username': 'demo_user2', 'email': 'user2@demo.com', 'first_name': 'Maria', 'last_name': 'Santos'},
        {'username': 'demo_user3', 'email': 'user3@demo.com', 'first_name': 'Pedro', 'last_name': 'Costa'},
        {'username': 'demo_user4', 'email': 'user4@demo.com', 'first_name': 'Ana', 'last_name': 'Oliveira'},
        {'username': 'demo_user5', 'email': 'user5@demo.com', 'first_name': 'Carlos', 'last_name': 'Ferreira'},
    ]
    
    created_users = []
    for user_data in users_data:
        user, created = User.objects.get_or_create(
            username=user_data['username'],
            defaults={
                'email': user_data['email'],
                'first_name': user_data['first_name'],
                'last_name': user_data['last_name'],
            }
        )
        if created:
            user.set_password('demo123')
            user.save()
        
        # Create profile with referral code
        profile, created = Profile.objects.get_or_create(
            user=user,
            defaults={
                'referral_code': generate_referral_code(),
                'points': random.randint(50, 500)
            }
        )
        created_users.append(user)
    
    return created_users

def create_demo_referrals(users):
    """Create demo referral tracking data"""
    # Create some referral tracking events
    for i, user in enumerate(users[:3]):  # First 3 users have referrals
        for j in range(random.randint(1, 3)):  # 1-3 referrals per user
            Referral.objects.create(
                inviter=user,
                code=user.profile.referral_code,
                status=random.choice(['clicked', 'registered', 'first_review']),
                created_at=datetime.now() - timedelta(days=random.randint(1, 30))
            )

def create_demo_reviews(users, restaurants):
    """Create demo reviews"""
    for user in users:
        # Each user reviews 2-4 random restaurants
        reviewed_restaurants = random.sample(restaurants, random.randint(2, 4))
        for restaurant in reviewed_restaurants:
            Review.objects.create(
                user=user,
                restaurant=restaurant,
                rating=random.randint(3, 5),  # 3-5 stars
                text=random.choice([
                    'Excelente comida!',
                    'Muito bom, recomendo!',
                    'Atendimento rápido e comida deliciosa.',
                    'Preço justo e qualidade boa.',
                    'Ambiente agradável, voltarei!',
                    'Comida fresca e saborosa.',
                    'Serviço eficiente.',
                    'Localização conveniente.'
                ]),
                created_at=datetime.now() - timedelta(days=random.randint(1, 60))
            )

def create_demo_lists(users, restaurants):
    """Create demo user lists"""
    list_templates = [
        {'title': 'Favoritos', 'description': 'Meus restaurantes preferidos'},
        {'title': 'Para Experimentar', 'description': 'Novos lugares para testar'},
        {'title': 'Delivery', 'description': 'Restaurantes com entrega rápida'},
        {'title': 'Romântico', 'description': 'Para jantares especiais'},
        {'title': 'Família', 'description': 'Lugares para levar a família'}
    ]
    
    for user in users:
        # Each user has 1-2 lists
        user_lists = random.sample(list_templates, random.randint(1, 2))
        for list_template in user_lists:
            lst = List.objects.create(
                owner=user,
                title=list_template['title'],
                description=list_template['description'],
                share_code=generate_referral_code()
            )
            
            # Add 2-4 restaurants to each list
            list_restaurants = random.sample(restaurants, random.randint(2, 4))
            for i, restaurant in enumerate(list_restaurants):
                ListItem.objects.create(
                    lst=lst,
                    restaurant=restaurant,
                    note=random.choice(['', 'Muito bom!', 'Recomendo!', 'Favorito!']),
                    position=i
                )

@transaction.atomic
def seed_demo_data():
    """Main function to seed all demo data"""
    print("🌱 Seeding demo data for FoodieMap...")
    
    # Clear existing data (optional - comment out to keep existing data)
    # Restaurant.objects.all().delete()
    # User.objects.filter(username__startswith='demo_').delete()
    
    # Create restaurants
    print("📍 Creating restaurants...")
    restaurants = []
    for restaurant_data in DEMO_RESTAURANTS:
        restaurant, created = Restaurant.objects.get_or_create(
            name=restaurant_data['name'],
            defaults=restaurant_data
        )
        restaurants.append(restaurant)
        if created:
            print(f"  ✅ Created: {restaurant.name}")
    
    # Create demo users
    print("👥 Creating demo users...")
    users = create_demo_users()
    for user in users:
        print(f"  ✅ Created user: {user.username}")
    
    # Create referral tracking
    print("🔗 Creating referral tracking...")
    create_demo_referrals(users)
    print(f"  ✅ Created {Referral.objects.count()} referral events")
    
    # Create reviews
    print("⭐ Creating reviews...")
    create_demo_reviews(users, restaurants)
    print(f"  ✅ Created {Review.objects.count()} reviews")
    
    # Create user lists
    print("📝 Creating user lists...")
    create_demo_lists(users, restaurants)
    print(f"  ✅ Created {List.objects.count()} lists with {ListItem.objects.count()} items")
    
    print(f"\n🎉 Demo data seeding complete!")
    print(f"📊 Summary:")
    print(f"  - Restaurants: {Restaurant.objects.count()}")
    print(f"  - Users: {User.objects.count()}")
    print(f"  - Reviews: {Review.objects.count()}")
    print(f"  - Lists: {List.objects.count()}")
    print(f"  - Referrals: {Referral.objects.count()}")
    print(f"  - List Items: {ListItem.objects.count()}")

if __name__ == '__main__':
    seed_demo_data()
