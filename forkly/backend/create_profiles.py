from django.contrib.auth.models import User
from api.models import Profile

def create_profiles():
    """Criar profiles para usuários de teste que não têm"""
    
    test_usernames = [
        'usuario_bronze',
        'usuario_prata', 
        'usuario_ouro',
        'usuario_diamante',
        'usuario_iniciante'
    ]
    
    for username in test_usernames:
        try:
            user = User.objects.get(username=username)
            
            # Verificar se já tem profile
            try:
                profile = user.profile
                print(f"ℹ️ Profile já existe para {username}")
            except Profile.DoesNotExist:
                # Criar profile
                profile = Profile.objects.create(
                    user=user,
                    referral_code=f'REF{user.id:06d}',
                    points=0
                )
                print(f"✅ Profile criado para {username}")
                
        except User.DoesNotExist:
            print(f"❌ Usuário {username} não encontrado")
        except Exception as e:
            print(f"❌ Erro ao criar profile para {username}: {e}")

# Executar a função
create_profiles()
