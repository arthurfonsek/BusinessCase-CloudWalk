#!/usr/bin/env python3
"""
Large Dataset Seeder for FoodieMap
Creates 100+ restaurants spread across São Paulo city
"""

import os
import sys
import django
from django.db import transaction

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from api.models import Restaurant
import random

# São Paulo neighborhoods with approximate coordinates
SP_NEIGHBORHOODS = [
    # Centro
    {'name': 'Centro', 'lat': -23.550, 'lng': -46.633},
    {'name': 'República', 'lat': -23.543, 'lng': -46.643},
    {'name': 'Sé', 'lat': -23.550, 'lng': -46.634},
    {'name': 'Bela Vista', 'lat': -23.561, 'lng': -46.656},
    
    # Zona Oeste
    {'name': 'Pinheiros', 'lat': -23.565, 'lng': -46.682},
    {'name': 'Vila Madalena', 'lat': -23.555, 'lng': -46.690},
    {'name': 'Perdizes', 'lat': -23.540, 'lng': -46.673},
    {'name': 'Lapa', 'lat': -23.528, 'lng': -46.704},
    {'name': 'Barra Funda', 'lat': -23.526, 'lng': -46.665},
    
    # Zona Sul
    {'name': 'Moema', 'lat': -23.596, 'lng': -46.674},
    {'name': 'Vila Mariana', 'lat': -23.588, 'lng': -46.640},
    {'name': 'Brooklin', 'lat': -23.605, 'lng': -46.703},
    {'name': 'Morumbi', 'lat': -23.623, 'lng': -46.698},
    {'name': 'Santo Amaro', 'lat': -23.654, 'lng': -46.709},
    {'name': 'Jardim Paulista', 'lat': -23.569, 'lng': -46.663},
    {'name': 'Itaim Bibi', 'lat': -23.587, 'lng': -46.681},
    {'name': 'Vila Olímpia', 'lat': -23.594, 'lng': -46.687},
    
    # Zona Norte
    {'name': 'Santana', 'lat': -23.506, 'lng': -46.628},
    {'name': 'Tucuruvi', 'lat': -23.479, 'lng': -46.602},
    {'name': 'Casa Verde', 'lat': -23.516, 'lng': -46.656},
    {'name': 'Vila Guilherme', 'lat': -23.503, 'lng': -46.600},
    {'name': 'Jaçanã', 'lat': -23.465, 'lng': -46.566},
    
    # Zona Leste
    {'name': 'Tatuapé', 'lat': -23.539, 'lng': -46.575},
    {'name': 'Mooca', 'lat': -23.562, 'lng': -46.594},
    {'name': 'Vila Prudente', 'lat': -23.593, 'lng': -46.578},
    {'name': 'Penha', 'lat': -23.529, 'lng': -46.541},
    {'name': 'Aricanduva', 'lat': -23.564, 'lng': -46.509},
    {'name': 'São Mateus', 'lat': -23.611, 'lng': -46.475},
    
    # Outras regiões
    {'name': 'Liberdade', 'lat': -23.560, 'lng': -46.631},
    {'name': 'Consolação', 'lat': -23.554, 'lng': -46.660},
    {'name': 'Jardins', 'lat': -23.573, 'lng': -46.665},
    {'name': 'Aclimação', 'lat': -23.574, 'lng': -46.631},
    {'name': 'Paraíso', 'lat': -23.575, 'lng': -46.645},
]

# Restaurant types and names
RESTAURANT_TYPES = {
    'burger': {
        'names': ['Burger King', 'McDonald\'s', 'Burger Palace', 'Burger Joint', 'Smash Burger', 
                  'The Burger Co', 'Premium Burgers', 'Artisan Burger', 'Burger House', 'Five Guys'],
        'categories': 'burger,fastfood',
        'price_range': (2, 3),
    },
    'pizza': {
        'names': ['Pizza Hut', 'Domino\'s', 'Pizza Express', 'Pizza Corner', 'Pizza House',
                  'Pizzaria Napoli', 'Bella Pizza', 'Pizza Mania', 'La Pizza', 'Pizza Roma'],
        'categories': 'pizza,italian',
        'price_range': (2, 4),
    },
    'sushi': {
        'names': ['Sushi Yama', 'Sushi Express', 'Sushi Master', 'Sushi Bar', 'Tokyo Sushi',
                  'Sushi House', 'Sakura Sushi', 'Hashi Sushi', 'Temaki Bar', 'Sushi Place'],
        'categories': 'sushi,japanese',
        'price_range': (3, 4),
    },
    'coffee': {
        'names': ['Starbucks', 'Café Central', 'Coffee House', 'Café Gourmet', 'Espresso Bar',
                  'The Coffee', 'Café & Co', 'Urban Coffee', 'Coffee Time', 'Café Arte'],
        'categories': 'coffee,cafe',
        'price_range': (2, 3),
    },
    'brazilian': {
        'names': ['Fogo de Chão', 'Churrascaria', 'Comida Caseira', 'Cantina da Nonna', 'Sabor Brasil',
                  'Restaurante Mineiro', 'Cozinha Brasileira', 'Mesa Brasil', 'Tempero Caseiro', 'Brasil Gourmet'],
        'categories': 'brazilian,traditional',
        'price_range': (2, 4),
    },
    'asian': {
        'names': ['China in Box', 'Thai House', 'Restaurante Asiático', 'Wok Express', 'Asian Fusion',
                  'Noodle Bar', 'Ramen House', 'Pho House', 'Asian Kitchen', 'Oriental Taste'],
        'categories': 'asian,oriental',
        'price_range': (2, 4),
    },
    'mexican': {
        'names': ['Taco Bell', 'Tacos & Co', 'Mexican House', 'El Taco', 'Burrito Bar',
                  'Cantina Mexicana', 'Taqueria', 'Quesadilla House', 'Chili\'s', 'Mexican Grill'],
        'categories': 'mexican,fastfood',
        'price_range': (2, 3),
    },
    'italian': {
        'names': ['Spoleto', 'Pasta House', 'Trattoria', 'La Pasta', 'Bella Italia',
                  'Ristorante Italiano', 'Pasta Express', 'Cucina Italiana', 'Pasta & Co', 'Milano Pasta'],
        'categories': 'italian,pasta',
        'price_range': (2, 4),
    },
    'healthy': {
        'names': ['Subway', 'Green House', 'Salad Bar', 'Healthy Life', 'Natural Food',
                  'Veggie House', 'Juice Bar', 'Fresh Food', 'Organic Kitchen', 'Health Bowl'],
        'categories': 'healthy,salad',
        'price_range': (2, 3),
    },
    'steakhouse': {
        'names': ['Outback', 'Texas Steakhouse', 'Prime Steak', 'Churrascaria Grill', 'Beef House',
                  'Steakhouse Premium', 'Grill & Co', 'Meat House', 'The Steak', 'Carnivore'],
        'categories': 'steakhouse,meat',
        'price_range': (3, 4),
    },
}

def generate_restaurants():
    """Generate a large list of restaurants spread across São Paulo"""
    restaurants = []
    restaurant_id = 1
    
    for neighborhood in SP_NEIGHBORHOODS:
        # Each neighborhood gets 3-5 restaurants of different types
        num_restaurants = random.randint(3, 5)
        types = random.sample(list(RESTAURANT_TYPES.keys()), min(num_restaurants, len(RESTAURANT_TYPES)))
        
        for rest_type in types:
            type_data = RESTAURANT_TYPES[rest_type]
            name = random.choice(type_data['names'])
            
            # Add some coordinate variation within the neighborhood
            lat = neighborhood['lat'] + random.uniform(-0.01, 0.01)
            lng = neighborhood['lng'] + random.uniform(-0.01, 0.01)
            
            # Generate realistic ratings
            rating_avg = round(random.uniform(3.5, 4.8), 1)
            rating_count = random.randint(20, 500)
            price_level = random.randint(*type_data['price_range'])
            
            restaurant = {
                'name': f"{name} - {neighborhood['name']}",
                'address': f"Rua {random.randint(1, 2000)}, {neighborhood['name']}, São Paulo",
                'lat': round(lat, 6),
                'lng': round(lng, 6),
                'categories': type_data['categories'],
                'price_level': price_level,
                'rating_avg': rating_avg,
                'rating_count': rating_count,
            }
            
            restaurants.append(restaurant)
            restaurant_id += 1
    
    return restaurants

@transaction.atomic
def seed_large_dataset():
    """Seed database with large restaurant dataset"""
    print("🌱 Seeding large dataset for São Paulo...")
    print("📍 Generating restaurants across all neighborhoods...")
    
    restaurants_data = generate_restaurants()
    
    print(f"✅ Generated {len(restaurants_data)} restaurants")
    print("💾 Saving to database...")
    
    created_count = 0
    updated_count = 0
    
    for restaurant_data in restaurants_data:
        restaurant, created = Restaurant.objects.update_or_create(
            name=restaurant_data['name'],
            defaults=restaurant_data
        )
        if created:
            created_count += 1
        else:
            updated_count += 1
    
    print(f"\n🎉 Dataset seeding complete!")
    print(f"📊 Summary:")
    print(f"  - Total restaurants: {Restaurant.objects.count()}")
    print(f"  - New restaurants: {created_count}")
    print(f"  - Updated restaurants: {updated_count}")
    print(f"  - Neighborhoods covered: {len(SP_NEIGHBORHOODS)}")
    print(f"\n🗺️ Restaurants are spread across:")
    for neighborhood in SP_NEIGHBORHOODS[:10]:
        count = Restaurant.objects.filter(address__contains=neighborhood['name']).count()
        print(f"  - {neighborhood['name']}: {count} restaurants")
    print(f"  - ... and {len(SP_NEIGHBORHOODS) - 10} more neighborhoods")

if __name__ == '__main__':
    seed_large_dataset()

