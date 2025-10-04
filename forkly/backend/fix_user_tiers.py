from django.contrib.auth.models import User
from api.models import UserTier, Tier

def fix_user_tiers():
    """Corrigir os tiers dos usuários de teste"""
    
    # Dados dos usuários e seus tiers corretos
    user_tiers = {
        'usuario_iniciante': {'referrals': 0, 'points': 50, 'tier_name': 'Iniciante'},
        'usuario_bronze': {'referrals': 2, 'points': 150, 'tier_name': 'Bronze'},
        'usuario_prata': {'referrals': 5, 'points': 400, 'tier_name': 'Prata'},
        'usuario_ouro': {'referrals': 10, 'points': 800, 'tier_name': 'Ouro'},
        'usuario_diamante': {'referrals': 20, 'points': 1500, 'tier_name': 'Diamante'},
    }
    
    for username, data in user_tiers.items():
        try:
            user = User.objects.get(username=username)
            user_tier = UserTier.objects.get(user=user)
            tier = Tier.objects.get(name=data['tier_name'])
            
            # Atualizar dados
            user_tier.current_referrals = data['referrals']
            user_tier.total_points = data['points']
            user_tier.tier = tier
            user_tier.save()
            
            print(f"✅ {username}: {tier.name} | {data['referrals']} referrals | {data['points']} pontos")
            
        except User.DoesNotExist:
            print(f"❌ Usuário {username} não encontrado")
        except UserTier.DoesNotExist:
            print(f"❌ UserTier não encontrado para {username}")
        except Tier.DoesNotExist:
            print(f"❌ Tier {data['tier_name']} não encontrado")
        except Exception as e:
            print(f"❌ Erro ao atualizar {username}: {e}")

# Executar a função
fix_user_tiers()
