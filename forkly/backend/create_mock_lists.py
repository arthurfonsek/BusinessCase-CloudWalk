#!/usr/bin/env python3
"""
Script para criar listas mock para todos os usuários existentes no banco.
Cada usuário receberá uma lista com 5 restaurantes.
"""

import os
import sys
import django
from django.db import transaction

# Configurar Django
sys.path.append('/home/arthur/Workstation/CLoudWalk/BusinessCase-CloudWalk/forkly/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import List, ListItem, Restaurant
import random
import string

def generate_share_code():
    """Gera um código de compartilhamento único"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

def create_mock_restaurants():
    """Cria restaurantes mock se não existirem"""
    restaurants_data = [
        {"name": "Outback Steakhouse", "address": "Av. Paulista, 1000", "lat": -23.561, "lng": -46.656},
        {"name": "McDonald's", "address": "Rua Augusta, 2000", "lat": -23.562, "lng": -46.657},
        {"name": "Burger King", "address": "Rua Oscar Freire, 3000", "lat": -23.563, "lng": -46.658},
        {"name": "Subway", "address": "Av. Faria Lima, 4000", "lat": -23.564, "lng": -46.659},
        {"name": "KFC", "address": "Rua da Consolação, 5000", "lat": -23.565, "lng": -46.660},
        {"name": "Pizza Hut", "address": "Av. Ibirapuera, 6000", "lat": -23.566, "lng": -46.661},
        {"name": "Domino's", "address": "Rua Augusta, 7000", "lat": -23.567, "lng": -46.662},
        {"name": "Starbucks", "address": "Av. Paulista, 8000", "lat": -23.568, "lng": -46.663},
        {"name": "Café do Ponto", "address": "Rua Oscar Freire, 9000", "lat": -23.569, "lng": -46.664},
        {"name": "Padaria Bella Vista", "address": "Av. Faria Lima, 10000", "lat": -23.570, "lng": -46.665},
        {"name": "Restaurante Japonês", "address": "Rua da Consolação, 11000", "lat": -23.571, "lng": -46.666},
        {"name": "Churrascaria", "address": "Av. Ibirapuera, 12000", "lat": -23.572, "lng": -46.667},
        {"name": "Pizzaria Italiana", "address": "Rua Augusta, 13000", "lat": -23.573, "lng": -46.668},
        {"name": "Lanchonete do João", "address": "Av. Paulista, 14000", "lat": -23.574, "lng": -46.669},
        {"name": "Restaurante Árabe", "address": "Rua Oscar Freire, 15000", "lat": -23.575, "lng": -46.670},
    ]
    
    created_restaurants = []
    for data in restaurants_data:
        restaurant, created = Restaurant.objects.get_or_create(
            name=data["name"],
            defaults={
                "address": data["address"],
                "lat": data["lat"],
                "lng": data["lng"],
                "phone": f"(11) {random.randint(1000, 9999)}-{random.randint(1000, 9999)}",
                "rating": round(random.uniform(3.0, 5.0), 1),
                "price_range": random.randint(1, 4),
                "cuisine_type": random.choice(["Brasileira", "Italiana", "Japonesa", "Árabe", "Americana", "Fast Food"]),
            }
        )
        created_restaurants.append(restaurant)
        if created:
            print(f"✅ Restaurante criado: {restaurant.name}")
    
    return created_restaurants

def create_mock_lists_for_users():
    """Cria listas mock para todos os usuários"""
    users = User.objects.all()
    restaurants = Restaurant.objects.all()
    
    if not users.exists():
        print("❌ Nenhum usuário encontrado no banco de dados!")
        return
    
    if not restaurants.exists():
        print("📝 Criando restaurantes mock...")
        restaurants = create_mock_restaurants()
    
    print(f"👥 Encontrados {users.count()} usuários")
    print(f"🍽️ Encontrados {restaurants.count()} restaurantes")
    
    list_titles = [
        "Meus Favoritos",
        "Para Experimentar",
        "Melhores de SP",
        "Restaurantes do Centro",
        "Comida Rápida",
        "Para Datas Especiais",
        "Restaurantes Baratos",
        "Culinária Internacional"
    ]
    
    created_lists = 0
    
    with transaction.atomic():
        for user in users:
            # Criar 1-2 listas por usuário
            num_lists = random.randint(1, 2)
            
            for i in range(num_lists):
                title = random.choice(list_titles)
                if num_lists > 1:
                    title = f"{title} {i+1}"
                
                # Criar lista
                user_list = List.objects.create(
                    title=title,
                    description=f"Lista criada automaticamente para {user.username}",
                    owner=user,
                    is_public=random.choice([True, False]),
                    share_code=generate_share_code()
                )
                
                # Adicionar 3-5 restaurantes aleatórios
                num_restaurants = random.randint(3, 5)
                selected_restaurants = random.sample(list(restaurants), min(num_restaurants, len(restaurants)))
                
                for i, restaurant in enumerate(selected_restaurants):
                    ListItem.objects.create(
                        lst=user_list,
                        restaurant=restaurant,
                        note=f"Recomendação para {user.username}",
                        position=i
                    )
                
                created_lists += 1
                print(f"✅ Lista criada para {user.username}: '{title}' com {len(selected_restaurants)} restaurantes")
    
    print(f"\n🎉 Total de {created_lists} listas criadas!")

if __name__ == "__main__":
    print("🚀 Iniciando criação de listas mock...")
    create_mock_lists_for_users()
    print("✅ Concluído!")
