import os
import django
import sys

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserTier, Tier, Profile, Friendship

def create_realistic_referrals():
    """Criar referrals realistas para os usuários de teste"""
    
    print("🔄 Criando referrals realistas...")
    
    # Usuários de teste e quantos referrals cada um deve ter
    test_users_referrals = {
        'usuario_iniciante': 0,  # Sem referrals
        'usuario_bronze': 3,     # 3 referrals para Bronze
        'usuario_prata': 7,      # 7 referrals para Prata  
        'usuario_ouro': 12,      # 12 referrals para Ouro
        'usuario_diamante': 25,  # 25 referrals para Diamante
    }
    
    # Criar usuários "referidos" para cada usuário de teste
    for username, num_referrals in test_users_referrals.items():
        try:
            # Obter o usuário principal
            main_user = User.objects.get(username=username)
            main_profile = Profile.objects.get(user=main_user)
            
            print(f"\n👤 Criando {num_referrals} referrals para {username}...")
            
            # Obter UserTier do usuário principal
            main_user_tier = UserTier.objects.get(user=main_user)
            
            # Criar usuários referidos
            for i in range(num_referrals):
                referred_username = f"{username}_referido_{i+1}"
                referred_email = f"{referred_username}@test.com"
                
                # Criar usuário referido
                referred_user, created = User.objects.get_or_create(
                    username=referred_username,
                    defaults={'email': referred_email}
                )
                
                if created:
                    referred_user.set_password("test123")
                    referred_user.save()
                    print(f"  ✅ Usuário referido criado: {referred_username}")
                else:
                    print(f"  ℹ️ Usuário referido já existe: {referred_username}")
                
                # Criar Profile para o usuário referido
                referred_profile, profile_created = Profile.objects.get_or_create(
                    user=referred_user,
                    defaults={'referral_code': f'REF{referred_user.id:06d}', 'points': 0}
                )
                
                # Criar UserTier para o usuário referido
                tier_iniciante = Tier.objects.get(name='Iniciante')
                referred_user_tier, tier_created = UserTier.objects.get_or_create(
                    user=referred_user,
                    defaults={'tier': tier_iniciante, 'current_referrals': 0, 'total_points': 0}
                )
                
                # Criar Friendship (referral)
                friendship, friendship_created = Friendship.objects.get_or_create(
                    user=main_user,
                    friend=referred_user,
                    defaults={
                        'is_referred': True,
                        'referral_code': main_profile.referral_code
                    }
                )
                
                if friendship_created:
                    print(f"    🔗 Referral criado: {referred_username} → {username}")
                
                # Atualizar pontos do usuário principal (50 pontos por referral)
                main_profile.points += 50
                main_profile.save()
                
                # Atualizar UserTier do usuário principal
                main_user_tier = UserTier.objects.get(user=main_user)
                main_user_tier.current_referrals += 1
                main_user_tier.total_points = main_profile.points
                main_user_tier.save()
                
                # Atualizar tier baseado nas referências
                main_user_tier.update_tier()
                
                print(f"    💰 +50 pontos para {username} (Total: {main_profile.points} pontos)")
                print(f"    📊 Tier atualizado: {main_user_tier.tier.name}")
            
            print(f"✅ {username}: {main_user_tier.tier.name} | {main_user_tier.current_referrals} referrals | {main_profile.points} pontos")
            
        except User.DoesNotExist:
            print(f"❌ Usuário {username} não encontrado")
        except Exception as e:
            print(f"❌ Erro ao processar {username}: {e}")
    
    print("\n🎉 Referrals realistas criados com sucesso!")
    
    # Mostrar resumo final
    print("\n📊 Resumo dos usuários de teste:")
    print("=" * 60)
    for username in test_users_referrals.keys():
        try:
            user = User.objects.get(username=username)
            user_tier = UserTier.objects.get(user=user)
            profile = Profile.objects.get(user=user)
            print(f"👤 {username}: {user_tier.tier.name} | {user_tier.current_referrals} referrals | {profile.points} pontos")
        except:
            print(f"❌ {username}: Erro ao obter dados")

if __name__ == '__main__':
    create_realistic_referrals()
