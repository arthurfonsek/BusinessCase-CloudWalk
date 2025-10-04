import os
import django
import sys

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserTier, Tier, Profile

def fix_test_users_tiers():
    """Corrigir tiers dos usuários de teste com dados específicos"""
    
    print("🔄 Corrigindo tiers dos usuários de teste...")
    
    # Dados específicos dos usuários de teste
    test_users_data = {
        'usuario_iniciante': {'referrals': 0, 'points': 50, 'tier_name': 'Iniciante'},
        'usuario_bronze': {'referrals': 2, 'points': 150, 'tier_name': 'Bronze'},
        'usuario_prata': {'referrals': 5, 'points': 400, 'tier_name': 'Prata'},
        'usuario_ouro': {'referrals': 10, 'points': 800, 'tier_name': 'Ouro'},
        'usuario_diamante': {'referrals': 20, 'points': 1500, 'tier_name': 'Diamante'},
    }
    
    for username, data in test_users_data.items():
        try:
            user = User.objects.get(username=username)
            user_tier = UserTier.objects.get(user=user)
            tier = Tier.objects.get(name=data['tier_name'])
            profile = Profile.objects.get(user=user)
            
            # Atualizar dados
            user_tier.current_referrals = data['referrals']
            user_tier.total_points = data['points']
            user_tier.tier = tier
            user_tier.save()
            
            profile.points = data['points']
            profile.save()
            
            print(f"✅ {username}: {tier.name} | {data['referrals']} referrals | {data['points']} pontos")
            
        except User.DoesNotExist:
            print(f"❌ Usuário {username} não encontrado")
        except UserTier.DoesNotExist:
            print(f"❌ UserTier não encontrado para {username}")
        except Tier.DoesNotExist:
            print(f"❌ Tier {data['tier_name']} não encontrado")
        except Profile.DoesNotExist:
            print(f"❌ Profile não encontrado para {username}")
        except Exception as e:
            print(f"❌ Erro ao atualizar {username}: {e}")
    
    print("\n🎉 Usuários de teste atualizados!")
    
    # Mostrar resumo final
    print("\n📊 Resumo dos usuários de teste:")
    print("=" * 50)
    for username, data in test_users_data.items():
        try:
            user = User.objects.get(username=username)
            user_tier = UserTier.objects.get(user=user)
            print(f"👤 {username}: {user_tier.tier.name} | {user_tier.current_referrals} referrals | {user_tier.total_points} pontos")
        except:
            print(f"❌ {username}: Erro ao obter dados")

if __name__ == '__main__':
    fix_test_users_tiers()
