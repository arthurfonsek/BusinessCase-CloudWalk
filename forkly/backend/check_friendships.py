#!/usr/bin/env python3
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from api.models import Friendship
from django.contrib.auth.models import User

def check_friendships():
    try:
        user = User.objects.get(username='arthur')
        friendships = Friendship.objects.filter(user=user)
        print(f'Amizades do arthur: {friendships.count()}')
        
        for f in friendships[:10]:
            print(f'- {f.friend.username} (referido: {f.is_referred})')
            
        # Verificar também amizades onde arthur é o friend
        reverse_friendships = Friendship.objects.filter(friend=user)
        print(f'\nAmizades onde arthur é o friend: {reverse_friendships.count()}')
        
        for f in reverse_friendships[:10]:
            print(f'- {f.user.username} (referido: {f.is_referred})')
            
    except User.DoesNotExist:
        print('Usuário arthur não encontrado')
    except Exception as e:
        print(f'Erro: {e}')

if __name__ == "__main__":
    check_friendships()
