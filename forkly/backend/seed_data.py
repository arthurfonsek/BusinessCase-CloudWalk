#!/usr/bin/env python3
"""
Simple seed script to add sample restaurants for testing
Run with: python3 seed_data.py
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from api.models import Restaurant

# Sample restaurants near São Paulo (example coordinates)
restaurants_data = [
    {
        "name": "Burger King - Paulista",
        "address": "Av. Paulista, 1000, São Paulo",
        "lat": -23.5611,
        "lng": -46.6565,
        "categories": "burger,fastfood",
        "price_level": 2,
        "rating_avg": 4.2,
        "rating_count": 150
    },
    {
        "name": "McDonald's - Ibirapuera",
        "address": "Av. Ibirapuera, 2000, São Paulo",
        "lat": -23.5874,
        "lng": -46.6576,
        "categories": "burger,fastfood",
        "price_level": 1,
        "rating_avg": 3.8,
        "rating_count": 200
    },
    {
        "name": "Sushi Yama",
        "address": "Rua Augusta, 500, São Paulo",
        "lat": -23.5611,
        "lng": -46.6565,
        "categories": "sushi,japanese",
        "price_level": 3,
        "rating_avg": 4.5,
        "rating_count": 80
    },
    {
        "name": "Pizza Hut - Vila Madalena",
        "address": "Rua Harmonia, 300, São Paulo",
        "lat": -23.5489,
        "lng": -46.6938,
        "categories": "pizza,italian",
        "price_level": 2,
        "rating_avg": 4.0,
        "rating_count": 120
    },
    {
        "name": "Starbucks - Faria Lima",
        "address": "Av. Faria Lima, 1000, São Paulo",
        "lat": -23.5679,
        "lng": -46.6915,
        "categories": "coffee,cafe",
        "price_level": 2,
        "rating_avg": 4.3,
        "rating_count": 90
    },
    {
        "name": "Vegan House",
        "address": "Rua Consolação, 800, São Paulo",
        "lat": -23.5611,
        "lng": -46.6565,
        "categories": "vegan,healthy",
        "price_level": 3,
        "rating_avg": 4.7,
        "rating_count": 60
    },
    {
        "name": "Ramen Ya",
        "address": "Rua da Liberdade, 200, São Paulo",
        "lat": -23.5611,
        "lng": -46.6565,
        "categories": "ramen,japanese",
        "price_level": 2,
        "rating_avg": 4.4,
        "rating_count": 70
    },
    {
        "name": "Subway - Shopping Iguatemi",
        "address": "Av. Brigadeiro Faria Lima, 2000, São Paulo",
        "lat": -23.5679,
        "lng": -46.6915,
        "categories": "sandwich,healthy",
        "price_level": 2,
        "rating_avg": 3.9,
        "rating_count": 110
    }
]

def seed_restaurants():
    print("Seeding restaurants...")
    for data in restaurants_data:
        restaurant, created = Restaurant.objects.get_or_create(
            name=data["name"],
            defaults=data
        )
        if created:
            print(f"Created: {restaurant.name}")
        else:
            print(f"Already exists: {restaurant.name}")
    
    print(f"\nTotal restaurants in database: {Restaurant.objects.count()}")

if __name__ == "__main__":
    seed_restaurants()
