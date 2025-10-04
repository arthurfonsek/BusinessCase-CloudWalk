#!/usr/bin/env python3
"""
Script para popular dados iniciais do sistema de gamificação
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from api.models import Tier, Achievement, Reward, User, Profile, UserTier

def create_tiers():
    """Cria os tiers do sistema"""
    tiers_data = [
        {
            'name': 'Iniciante',
            'min_referrals': 0,
            'color': '#8B4513',  # Marrom
            'icon': 'star_border',
            'benefits': ['Acesso básico ao app', 'Pontos por indicações']
        },
        {
            'name': 'Bronze',
            'min_referrals': 3,
            'color': '#CD7F32',  # Bronze
            'icon': 'star',
            'benefits': ['Desconto de 5% em restaurantes', 'Pontos bônus por reviews']
        },
        {
            'name': 'Prata',
            'min_referrals': 8,
            'color': '#C0C0C0',  # Prata
            'icon': 'star_half',
            'benefits': ['Desconto de 10% em restaurantes', 'Acesso a listas premium', 'Pontos bônus por indicações']
        },
        {
            'name': 'Ouro',
            'min_referrals': 15,
            'color': '#FFD700',  # Ouro
            'icon': 'star',
            'benefits': ['Desconto de 15% em restaurantes', 'Listas ilimitadas', 'Recompensas exclusivas']
        },
        {
            'name': 'Diamante',
            'min_referrals': 30,
            'color': '#B9F2FF',  # Diamante
            'icon': 'diamond',
            'benefits': ['Desconto de 20% em restaurantes', 'Suporte prioritário', 'Eventos exclusivos', 'Recompensas VIP']
        }
    ]
    
    created_tiers = []
    for tier_data in tiers_data:
        tier, created = Tier.objects.get_or_create(
            name=tier_data['name'],
            defaults=tier_data
        )
        created_tiers.append(tier)
        if created:
            print(f"✅ Tier criado: {tier.name}")
        else:
            print(f"ℹ️ Tier já existe: {tier.name}")
    
    return created_tiers

def create_achievements():
    """Cria as conquistas do sistema"""
    achievements_data = [
        {
            'name': 'Primeira Indicação',
            'description': 'Indique seu primeiro amigo',
            'icon': 'person_add',
            'points_reward': 50,
            'condition_type': 'referrals',
            'condition_value': 1
        },
        {
            'name': 'Indicador Popular',
            'description': 'Indique 5 amigos',
            'icon': 'group_add',
            'points_reward': 200,
            'condition_type': 'referrals',
            'condition_value': 5
        },
        {
            'name': 'Influenciador',
            'description': 'Indique 10 amigos',
            'icon': 'trending_up',
            'points_reward': 500,
            'condition_type': 'referrals',
            'condition_value': 10
        },
        {
            'name': 'Primeira Avaliação',
            'description': 'Faça sua primeira avaliação',
            'icon': 'rate_review',
            'points_reward': 25,
            'condition_type': 'reviews',
            'condition_value': 1
        },
        {
            'name': 'Crítico',
            'description': 'Faça 10 avaliações',
            'icon': 'star',
            'points_reward': 100,
            'condition_type': 'reviews',
            'condition_value': 10
        },
        {
            'name': 'Colecionador de Pontos',
            'description': 'Acumule 1000 pontos',
            'icon': 'emoji_events',
            'points_reward': 100,
            'condition_type': 'points',
            'condition_value': 1000
        },
        {
            'name': 'Mestre dos Pontos',
            'description': 'Acumule 5000 pontos',
            'icon': 'military_tech',
            'points_reward': 500,
            'condition_type': 'points',
            'condition_value': 5000
        }
    ]
    
    created_achievements = []
    for achievement_data in achievements_data:
        achievement, created = Achievement.objects.get_or_create(
            name=achievement_data['name'],
            defaults=achievement_data
        )
        created_achievements.append(achievement)
        if created:
            print(f"✅ Conquista criada: {achievement.name}")
        else:
            print(f"ℹ️ Conquista já existe: {achievement.name}")
    
    return created_achievements

def create_rewards():
    """Cria as recompensas disponíveis"""
    rewards_data = [
        {
            'name': 'Desconto 5%',
            'description': 'Desconto de 5% em qualquer restaurante',
            'points_cost': 100,
            'reward_type': 'discount'
        },
        {
            'name': 'Desconto 10%',
            'description': 'Desconto de 10% em qualquer restaurante',
            'points_cost': 250,
            'reward_type': 'discount'
        },
        {
            'name': 'Desconto 15%',
            'description': 'Desconto de 15% em qualquer restaurante',
            'points_cost': 500,
            'reward_type': 'discount'
        },
        {
            'name': 'Item Grátis',
            'description': 'Um item grátis em restaurantes parceiros',
            'points_cost': 300,
            'reward_type': 'free_item'
        },
        {
            'name': 'Lista Premium',
            'description': 'Crie listas privadas ilimitadas',
            'points_cost': 200,
            'reward_type': 'premium_feature'
        },
        {
            'name': 'Badge Especial',
            'description': 'Badge exclusivo no seu perfil',
            'points_cost': 150,
            'reward_type': 'badge'
        }
    ]
    
    created_rewards = []
    for reward_data in rewards_data:
        reward, created = Reward.objects.get_or_create(
            name=reward_data['name'],
            defaults=reward_data
        )
        created_rewards.append(reward)
        if created:
            print(f"✅ Recompensa criada: {reward.name}")
        else:
            print(f"ℹ️ Recompensa já existe: {reward.name}")
    
    return created_rewards

def update_existing_users():
    """Atualiza usuários existentes com sistema de tiers"""
    users = User.objects.all()
    bronze_tier = Tier.objects.get(name='Iniciante')
    
    updated_count = 0
    for user in users:
        # Criar UserTier se não existir
        user_tier, created = UserTier.objects.get_or_create(
            user=user,
            defaults={'tier': bronze_tier}
        )
        
        if created:
            updated_count += 1
            print(f"✅ UserTier criado para: {user.username}")
    
    print(f"📊 {updated_count} usuários atualizados com sistema de tiers")

def main():
    print("🎮 Iniciando seed de dados de gamificação...")
    print("=" * 50)
    
    # Criar tiers
    print("\n🏆 Criando tiers...")
    tiers = create_tiers()
    
    # Criar conquistas
    print("\n🏅 Criando conquistas...")
    achievements = create_achievements()
    
    # Criar recompensas
    print("\n🎁 Criando recompensas...")
    rewards = create_rewards()
    
    # Atualizar usuários existentes
    print("\n👥 Atualizando usuários existentes...")
    update_existing_users()
    
    print("\n" + "=" * 50)
    print("✅ Seed de gamificação concluído!")
    print(f"📊 Estatísticas:")
    print(f"   - Tiers: {Tier.objects.count()}")
    print(f"   - Conquistas: {Achievement.objects.count()}")
    print(f"   - Recompensas: {Reward.objects.count()}")
    print(f"   - UserTiers: {UserTier.objects.count()}")

if __name__ == "__main__":
    main()
