#!/usr/bin/env python3
"""
Script para adicionar uma lista manualmente no banco de dados.
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

def add_manual_list():
    """Adiciona uma lista manual para o usuário testuser"""
    
    # Buscar o usuário testuser
    try:
        user = User.objects.get(username='testuser')
        print(f"✅ Usuário encontrado: {user.username}")
    except User.DoesNotExist:
        print("❌ Usuário 'testuser' não encontrado!")
        return
    
    # Buscar alguns restaurantes
    restaurants = Restaurant.objects.all()[:5]
    if not restaurants.exists():
        print("❌ Nenhum restaurante encontrado!")
        return
    
    print(f"🍽️ Encontrados {restaurants.count()} restaurantes")
    
    with transaction.atomic():
        # Criar a lista
        user_list = List.objects.create(
            title="Lista Manual de Teste",
            description="Lista criada manualmente para testar o sistema",
            owner=user,
            is_public=True,
            share_code=generate_share_code()
        )
        
        print(f"✅ Lista criada: '{user_list.title}' (ID: {user_list.id})")
        print(f"🔗 Código de compartilhamento: {user_list.share_code}")
        
        # Adicionar restaurantes à lista
        for i, restaurant in enumerate(restaurants):
            ListItem.objects.create(
                lst=user_list,
                restaurant=restaurant,
                note=f"Restaurante {i+1} da lista manual",
                position=i
            )
            print(f"  ➕ Adicionado: {restaurant.name}")
        
        print(f"\n🎉 Lista criada com sucesso!")
        print(f"📊 Total de itens: {user_list.items.count()}")
        print(f"👤 Proprietário: {user_list.owner.username}")
        print(f"🌐 Pública: {'Sim' if user_list.is_public else 'Não'}")

if __name__ == "__main__":
    print("🚀 Adicionando lista manual...")
    add_manual_list()
    print("✅ Concluído!")
