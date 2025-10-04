import os
import django
import sys

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserTier, Tier, Profile

def update_all_user_tiers():
    """Atualizar tiers de todos os usuários baseado em suas referências reais"""
    
    print("🔄 Iniciando atualização de tiers para todos os usuários...")
    
    # Obter todos os usuários
    users = User.objects.all()
    total_users = users.count()
    updated_count = 0
    
    print(f"📊 Total de usuários encontrados: {total_users}")
    
    for user in users:
        try:
            # Obter ou criar UserTier
            user_tier, created = UserTier.objects.get_or_create(
                user=user,
                defaults={'current_referrals': 0, 'total_points': 0}
            )
            
            # Obter ou criar Profile
            profile, profile_created = Profile.objects.get_or_create(
                user=user,
                defaults={'referral_code': f'REF{user.id:06d}', 'points': 0}
            )
            
            # Contar referências reais do usuário
            real_referrals = user.friends.filter(is_referred=True).count()
            
            # Atualizar dados
            user_tier.current_referrals = real_referrals
            user_tier.total_points = profile.points
            user_tier.save()
            
            # Atualizar tier baseado nas referências
            user_tier.update_tier()
            
            updated_count += 1
            print(f"✅ {user.username}: {user_tier.tier.name} | {real_referrals} referrals | {profile.points} pontos")
            
        except Exception as e:
            print(f"❌ Erro ao atualizar {user.username}: {e}")
    
    print(f"\n🎉 Atualização concluída!")
    print(f"📈 Usuários atualizados: {updated_count}/{total_users}")
    
    # Mostrar resumo por tier
    print("\n📊 Resumo por Tier:")
    print("=" * 50)
    
    tiers = Tier.objects.all().order_by('min_referrals')
    for tier in tiers:
        count = UserTier.objects.filter(tier=tier).count()
        print(f"{tier.name}: {count} usuários")

if __name__ == '__main__':
    update_all_user_tiers()
