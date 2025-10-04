#!/usr/bin/env python3
"""
Script para criar usuários de teste com diferentes rankings e pontos
"""
import os
import sys
import django
from django.contrib.auth.models import User
from django.db import transaction

# Adicionar o diretório do projeto ao path
sys.path.append('/home/arthur/Workstation/CLoudWalk/BusinessCase-CloudWalk/forkly/backend')

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'forkly.settings')
django.setup()

from api.models import UserTier, Tier, UserAchievement, Achievement, UserReward, Reward

def create_test_users():
    """Criar usuários de teste com diferentes rankings"""
    
    # Dados dos usuários de teste
    test_users = [
        {
            'username': 'usuario_bronze',
            'email': 'bronze@test.com',
            'password': 'test123',
            'referrals': 2,
            'points': 150,
            'tier_name': 'Bronze'
        },
        {
            'username': 'usuario_prata',
            'email': 'prata@test.com', 
            'password': 'test123',
            'referrals': 5,
            'points': 400,
            'tier_name': 'Prata'
        },
        {
            'username': 'usuario_ouro',
            'email': 'ouro@test.com',
            'password': 'test123', 
            'referrals': 10,
            'points': 800,
            'tier_name': 'Ouro'
        },
        {
            'username': 'usuario_diamante',
            'email': 'diamante@test.com',
            'password': 'test123',
            'referrals': 20,
            'points': 1500,
            'tier_name': 'Diamante'
        },
        {
            'username': 'usuario_iniciante',
            'email': 'iniciante@test.com',
            'password': 'test123',
            'referrals': 0,
            'points': 50,
            'tier_name': 'Iniciante'
        }
    ]
    
    with transaction.atomic():
        for user_data in test_users:
            # Criar ou obter usuário
            user, created = User.objects.get_or_create(
                username=user_data['username'],
                defaults={
                    'email': user_data['email'],
                    'is_active': True
                }
            )
            
            if created:
                user.set_password(user_data['password'])
                user.save()
                print(f"✅ Usuário criado: {user_data['username']}")
            else:
                print(f"ℹ️ Usuário já existe: {user_data['username']}")
            
            # Obter tier
            try:
                tier = Tier.objects.get(name=user_data['tier_name'])
            except Tier.DoesNotExist:
                print(f"❌ Tier não encontrado: {user_data['tier_name']}")
                continue
            
            # Criar ou atualizar UserTier
            user_tier, created = UserTier.objects.get_or_create(
                user=user,
                defaults={
                    'tier': tier,
                    'current_referrals': user_data['referrals'],
                    'total_points': user_data['points']
                }
            )
            
            if not created:
                user_tier.current_referrals = user_data['referrals']
                user_tier.total_points = user_data['points']
                user_tier.tier = tier
                user_tier.save()
            
            print(f"  📊 Tier: {tier.name} | Referrals: {user_data['referrals']} | Pontos: {user_data['points']}")
            
            # Adicionar algumas conquistas
            achievements = Achievement.objects.all()[:3]  # Primeiras 3 conquistas
            for achievement in achievements:
                UserAchievement.objects.get_or_create(
                    user=user,
                    achievement=achievement
                )
            
            # Adicionar algumas recompensas
            rewards = Reward.objects.all()[:2]  # Primeiras 2 recompensas
            for reward in rewards:
                if user_tier.total_points >= reward.points_cost:
                    UserReward.objects.get_or_create(
                        user=user,
                        reward=reward
                    )
    
    print("\n🎉 Usuários de teste criados com sucesso!")
    print("\n📋 Resumo dos usuários:")
    print("=" * 50)
    
    for user_data in test_users:
        user = User.objects.get(username=user_data['username'])
        user_tier = UserTier.objects.get(user=user)
        print(f"👤 {user.username} | {user_tier.tier.name} | {user_tier.total_points} pontos | {user_tier.current_referrals} referrals")

if __name__ == '__main__':
    create_test_users()
