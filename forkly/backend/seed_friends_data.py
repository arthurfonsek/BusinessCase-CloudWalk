#!/usr/bin/env python3
import os
import sys
import django
from django.contrib.auth.models import User
from django.db import transaction

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
django.setup()

from api.models import Profile, Friendship
from api.utils import gen_code

def create_mock_users():
    """Cria usuários mock com perfis e amizades"""
    
    # Dados dos usuários mock - MUITO MAIS USUÁRIOS
    users_data = [
        # Usuários principais
        {"username": "arthur", "email": "arthur@teste.com", "first_name": "Arthur", "last_name": "Silva"},
        {"username": "maria", "email": "maria@teste.com", "first_name": "Maria", "last_name": "Santos"},
        {"username": "joao", "email": "joao@teste.com", "first_name": "João", "last_name": "Oliveira"},
        {"username": "ana", "email": "ana@teste.com", "first_name": "Ana", "last_name": "Costa"},
        {"username": "pedro", "email": "pedro@teste.com", "first_name": "Pedro", "last_name": "Ferreira"},
        {"username": "carla", "email": "carla@teste.com", "first_name": "Carla", "last_name": "Lima"},
        {"username": "lucas", "email": "lucas@teste.com", "first_name": "Lucas", "last_name": "Rodrigues"},
        {"username": "sofia", "email": "sofia@teste.com", "first_name": "Sofia", "last_name": "Almeida"},
        {"username": "rafael", "email": "rafael@teste.com", "first_name": "Rafael", "last_name": "Pereira"},
        {"username": "julia", "email": "julia@teste.com", "first_name": "Julia", "last_name": "Martins"},
        {"username": "gabriel", "email": "gabriel@teste.com", "first_name": "Gabriel", "last_name": "Nascimento"},
        {"username": "beatriz", "email": "beatriz@teste.com", "first_name": "Beatriz", "last_name": "Rocha"},
        {"username": "felipe", "email": "felipe@teste.com", "first_name": "Felipe", "last_name": "Barbosa"},
        {"username": "lara", "email": "lara@teste.com", "first_name": "Lara", "last_name": "Cardoso"},
        {"username": "diego", "email": "diego@teste.com", "first_name": "Diego", "last_name": "Mendes"},
        
        # Mais usuários para popular
        {"username": "camila", "email": "camila@teste.com", "first_name": "Camila", "last_name": "Vieira"},
        {"username": "bruno", "email": "bruno@teste.com", "first_name": "Bruno", "last_name": "Castro"},
        {"username": "fernanda", "email": "fernanda@teste.com", "first_name": "Fernanda", "last_name": "Dias"},
        {"username": "marcos", "email": "marcos@teste.com", "first_name": "Marcos", "last_name": "Araújo"},
        {"username": "patricia", "email": "patricia@teste.com", "first_name": "Patrícia", "last_name": "Monteiro"},
        {"username": "ricardo", "email": "ricardo@teste.com", "first_name": "Ricardo", "last_name": "Nunes"},
        {"username": "vanessa", "email": "vanessa@teste.com", "first_name": "Vanessa", "last_name": "Freitas"},
        {"username": "thiago", "email": "thiago@teste.com", "first_name": "Thiago", "last_name": "Melo"},
        {"username": "isabela", "email": "isabela@teste.com", "first_name": "Isabela", "last_name": "Gomes"},
        {"username": "andre", "email": "andre@teste.com", "first_name": "André", "last_name": "Ribeiro"},
        {"username": "natalia", "email": "natalia@teste.com", "first_name": "Natália", "last_name": "Moreira"},
        {"username": "leonardo", "email": "leonardo@teste.com", "first_name": "Leonardo", "last_name": "Carvalho"},
        {"username": "amanda", "email": "amanda@teste.com", "first_name": "Amanda", "last_name": "Teixeira"},
        {"username": "rodrigo", "email": "rodrigo@teste.com", "first_name": "Rodrigo", "last_name": "Machado"},
        {"username": "carolina", "email": "carolina@teste.com", "first_name": "Carolina", "last_name": "Reis"},
        {"username": "vinicius", "email": "vinicius@teste.com", "first_name": "Vinícius", "last_name": "Fonseca"},
        {"username": "larissa", "email": "larissa@teste.com", "first_name": "Larissa", "last_name": "Moura"},
        {"username": "guilherme", "email": "guilherme@teste.com", "first_name": "Guilherme", "last_name": "Campos"},
        {"username": "barbara", "email": "barbara@teste.com", "first_name": "Bárbara", "last_name": "Lopes"},
        {"username": "fabricio", "email": "fabricio@teste.com", "first_name": "Fabrício", "last_name": "Silveira"},
        {"username": "monique", "email": "monique@teste.com", "first_name": "Monique", "last_name": "Vargas"},
        {"username": "henrique", "email": "henrique@teste.com", "first_name": "Henrique", "last_name": "Duarte"},
        {"username": "tamires", "email": "tamires@teste.com", "first_name": "Tamires", "last_name": "Bezerra"},
        {"username": "alexandre", "email": "alexandre@teste.com", "first_name": "Alexandre", "last_name": "Tavares"},
        {"username": "priscila", "email": "priscila@teste.com", "first_name": "Priscila", "last_name": "Santana"},
        {"username": "daniel", "email": "daniel@teste.com", "first_name": "Daniel", "last_name": "Correia"},
        {"username": "jessica", "email": "jessica@teste.com", "first_name": "Jéssica", "last_name": "Azevedo"},
        {"username": "marcelo", "email": "marcelo@teste.com", "first_name": "Marcelo", "last_name": "Medeiros"},
        {"username": "renata", "email": "renata@teste.com", "first_name": "Renata", "last_name": "Nogueira"},
        {"username": "carlos", "email": "carlos@teste.com", "first_name": "Carlos", "last_name": "Brito"},
        {"username": "adriana", "email": "adriana@teste.com", "first_name": "Adriana", "last_name": "Souza"},
        {"username": "roberto", "email": "roberto@teste.com", "first_name": "Roberto", "last_name": "Fernandes"},
        {"username": "cristina", "email": "cristina@teste.com", "first_name": "Cristina", "last_name": "Mendes"},
        {"username": "antonio", "email": "antonio@teste.com", "first_name": "Antônio", "last_name": "Ramos"},
        {"username": "eliane", "email": "eliane@teste.com", "first_name": "Eliane", "last_name": "Cavalcanti"},
        {"username": "paulo", "email": "paulo@teste.com", "first_name": "Paulo", "last_name": "Torres"},
        {"username": "silvia", "email": "silvia@teste.com", "first_name": "Sílvia", "last_name": "Moraes"},
        {"username": "eduardo", "email": "eduardo@teste.com", "first_name": "Eduardo", "last_name": "Peixoto"},
        {"username": "denise", "email": "denise@teste.com", "first_name": "Denise", "last_name": "Cordeiro"},
        {"username": "sergio", "email": "sergio@teste.com", "first_name": "Sérgio", "last_name": "Pinto"},
        {"username": "rosana", "email": "rosana@teste.com", "first_name": "Rosana", "last_name": "Guimarães"},
        {"username": "wagner", "email": "wagner@teste.com", "first_name": "Wagner", "last_name": "Santos"},
        {"username": "marcia", "email": "marcia@teste.com", "first_name": "Márcia", "last_name": "Cunha"},
        {"username": "jose", "email": "jose@teste.com", "first_name": "José", "last_name": "Farias"},
        {"username": "lucia", "email": "lucia@teste.com", "first_name": "Lúcia", "last_name": "Andrade"},
        {"username": "luiz", "email": "luiz@teste.com", "first_name": "Luiz", "last_name": "Bastos"},
        {"username": "rosemary", "email": "rosemary@teste.com", "first_name": "Rosemary", "last_name": "Leite"},
        {"username": "miguel", "email": "miguel@teste.com", "first_name": "Miguel", "last_name": "Coelho"},
        {"username": "valeria", "email": "valeria@teste.com", "first_name": "Valéria", "last_name": "Macedo"},
        {"username": "cesar", "email": "cesar@teste.com", "first_name": "César", "last_name": "Vieira"},
        {"username": "sandra", "email": "sandra@teste.com", "first_name": "Sandra", "last_name": "Ferreira"},
        {"username": "rogerio", "email": "rogerio@teste.com", "first_name": "Rogério", "last_name": "Barros"},
        {"username": "claudia", "email": "claudia@teste.com", "first_name": "Cláudia", "last_name": "Xavier"},
        {"username": "marcos2", "email": "marcos2@teste.com", "first_name": "Marcos", "last_name": "Dantas"},
        {"username": "elisa", "email": "elisa@teste.com", "first_name": "Elisa", "last_name": "Borges"},
        {"username": "alberto", "email": "alberto@teste.com", "first_name": "Alberto", "last_name": "Mendes"},
        {"username": "vera", "email": "vera@teste.com", "first_name": "Vera", "last_name": "Lacerda"},
        {"username": "nelson", "email": "nelson@teste.com", "first_name": "Nelson", "last_name": "Guedes"},
        {"username": "maria2", "email": "maria2@teste.com", "first_name": "Maria", "last_name": "Fagundes"},
        {"username": "osvaldo", "email": "osvaldo@teste.com", "first_name": "Osvaldo", "last_name": "Pacheco"},
        {"username": "rita", "email": "rita@teste.com", "first_name": "Rita", "last_name": "Brito"},
        {"username": "gilberto", "email": "gilberto@teste.com", "first_name": "Gilberto", "last_name": "Siqueira"},
        {"username": "maria3", "email": "maria3@teste.com", "first_name": "Maria", "last_name": "Cavalcanti"},
        {"username": "jorge", "email": "jorge@teste.com", "first_name": "Jorge", "last_name": "Araújo"},
        {"username": "lucia2", "email": "lucia2@teste.com", "first_name": "Lúcia", "last_name": "Melo"},
        {"username": "roberto2", "email": "roberto2@teste.com", "first_name": "Roberto", "last_name": "Nascimento"},
        {"username": "maria4", "email": "maria4@teste.com", "first_name": "Maria", "last_name": "Oliveira"},
        {"username": "carlos2", "email": "carlos2@teste.com", "first_name": "Carlos", "last_name": "Silva"},
        {"username": "ana2", "email": "ana2@teste.com", "first_name": "Ana", "last_name": "Santos"},
        {"username": "joao2", "email": "joao2@teste.com", "first_name": "João", "last_name": "Costa"},
        {"username": "maria5", "email": "maria5@teste.com", "first_name": "Maria", "last_name": "Ferreira"},
        {"username": "antonio2", "email": "antonio2@teste.com", "first_name": "Antônio", "last_name": "Lima"},
        {"username": "francisco", "email": "francisco@teste.com", "first_name": "Francisco", "last_name": "Rodrigues"},
        {"username": "maria6", "email": "maria6@teste.com", "first_name": "Maria", "last_name": "Almeida"},
        {"username": "jose2", "email": "jose2@teste.com", "first_name": "José", "last_name": "Pereira"},
        {"username": "maria7", "email": "maria7@teste.com", "first_name": "Maria", "last_name": "Martins"},
        {"username": "manoel", "email": "manoel@teste.com", "first_name": "Manoel", "last_name": "Nascimento"},
        {"username": "maria8", "email": "maria8@teste.com", "first_name": "Maria", "last_name": "Rocha"},
        {"username": "sebastiao", "email": "sebastiao@teste.com", "first_name": "Sebastião", "last_name": "Barbosa"},
        {"username": "maria9", "email": "maria9@teste.com", "first_name": "Maria", "last_name": "Cardoso"},
        {"username": "francisco2", "email": "francisco2@teste.com", "first_name": "Francisco", "last_name": "Mendes"},
        {"username": "maria10", "email": "maria10@teste.com", "first_name": "Maria", "last_name": "Vieira"},
        {"username": "antonio3", "email": "antonio3@teste.com", "first_name": "Antônio", "last_name": "Castro"},
        {"username": "maria11", "email": "maria11@teste.com", "first_name": "Maria", "last_name": "Dias"},
        {"username": "francisco3", "email": "francisco3@teste.com", "first_name": "Francisco", "last_name": "Araújo"},
        {"username": "maria12", "email": "maria12@teste.com", "first_name": "Maria", "last_name": "Monteiro"},
        {"username": "antonio4", "email": "antonio4@teste.com", "first_name": "Antônio", "last_name": "Nunes"},
        {"username": "maria13", "email": "maria13@teste.com", "first_name": "Maria", "last_name": "Freitas"},
        {"username": "francisco4", "email": "francisco4@teste.com", "first_name": "Francisco", "last_name": "Melo"},
        {"username": "maria14", "email": "maria14@teste.com", "first_name": "Maria", "last_name": "Gomes"},
        {"username": "antonio5", "email": "antonio5@teste.com", "first_name": "Antônio", "last_name": "Ribeiro"},
        {"username": "maria15", "email": "maria15@teste.com", "first_name": "Maria", "last_name": "Moreira"},
        {"username": "francisco5", "email": "francisco5@teste.com", "first_name": "Francisco", "last_name": "Carvalho"},
        {"username": "maria16", "email": "maria16@teste.com", "first_name": "Maria", "last_name": "Teixeira"},
        {"username": "antonio6", "email": "antonio6@teste.com", "first_name": "Antônio", "last_name": "Machado"},
        {"username": "maria17", "email": "maria17@teste.com", "first_name": "Maria", "last_name": "Reis"},
        {"username": "francisco6", "email": "francisco6@teste.com", "first_name": "Francisco", "last_name": "Fonseca"},
        {"username": "maria18", "email": "maria18@teste.com", "first_name": "Maria", "last_name": "Moura"},
        {"username": "antonio7", "email": "antonio7@teste.com", "first_name": "Antônio", "last_name": "Campos"},
        {"username": "maria19", "email": "maria19@teste.com", "first_name": "Maria", "last_name": "Lopes"},
        {"username": "francisco7", "email": "francisco7@teste.com", "first_name": "Francisco", "last_name": "Silveira"},
        {"username": "maria20", "email": "maria20@teste.com", "first_name": "Maria", "last_name": "Vargas"},
        {"username": "antonio8", "email": "antonio8@teste.com", "first_name": "Antônio", "last_name": "Duarte"},
        {"username": "maria21", "email": "maria21@teste.com", "first_name": "Maria", "last_name": "Bezerra"},
        {"username": "francisco8", "email": "francisco8@teste.com", "first_name": "Francisco", "last_name": "Tavares"},
        {"username": "maria22", "email": "maria22@teste.com", "first_name": "Maria", "last_name": "Santana"},
        {"username": "antonio9", "email": "antonio9@teste.com", "first_name": "Antônio", "last_name": "Correia"},
        {"username": "maria23", "email": "maria23@teste.com", "first_name": "Maria", "last_name": "Azevedo"},
        {"username": "francisco9", "email": "francisco9@teste.com", "first_name": "Francisco", "last_name": "Medeiros"},
        {"username": "maria24", "email": "maria24@teste.com", "first_name": "Maria", "last_name": "Nogueira"},
        {"username": "antonio10", "email": "antonio10@teste.com", "first_name": "Antônio", "last_name": "Brito"},
        {"username": "maria25", "email": "maria25@teste.com", "first_name": "Maria", "last_name": "Souza"},
        {"username": "francisco10", "email": "francisco10@teste.com", "first_name": "Francisco", "last_name": "Fernandes"},
        {"username": "maria26", "email": "maria26@teste.com", "first_name": "Maria", "last_name": "Mendes"},
        {"username": "antonio11", "email": "antonio11@teste.com", "first_name": "Antônio", "last_name": "Ramos"},
        {"username": "maria27", "email": "maria27@teste.com", "first_name": "Maria", "last_name": "Cavalcanti"},
        {"username": "francisco11", "email": "francisco11@teste.com", "first_name": "Francisco", "last_name": "Torres"},
        {"username": "maria28", "email": "maria28@teste.com", "first_name": "Maria", "last_name": "Moraes"},
        {"username": "antonio12", "email": "antonio12@teste.com", "first_name": "Antônio", "last_name": "Peixoto"},
        {"username": "maria29", "email": "maria29@teste.com", "first_name": "Maria", "last_name": "Cordeiro"},
        {"username": "francisco12", "email": "francisco12@teste.com", "first_name": "Francisco", "last_name": "Pinto"},
        {"username": "maria30", "email": "maria30@teste.com", "first_name": "Maria", "last_name": "Guimarães"},
    ]
    
    with transaction.atomic():
        print("Criando usuários mock...")
        
        # Criar usuários
        created_users = []
        for user_data in users_data:
            user, created = User.objects.get_or_create(
                username=user_data["username"],
                defaults={
                    'email': user_data["email"],
                    'first_name': user_data["first_name"],
                    'last_name': user_data["last_name"],
                    'is_active': True,
                }
            )
            
            if created:
                user.set_password("123456")  # Senha padrão para todos
                user.save()
                print(f"✓ Usuário criado: {user.username}")
            else:
                print(f"→ Usuário já existe: {user.username}")
            
            # Criar ou atualizar perfil
            profile, profile_created = Profile.objects.get_or_create(
                user=user,
                defaults={
                    'referral_code': gen_code(),
                    'points': 0,
                }
            )
            
            if profile_created:
                print(f"✓ Perfil criado para {user.username} - Código: {profile.referral_code}")
            
            created_users.append(user)
        
        print(f"\nTotal de usuários: {len(created_users)}")
        
        # Criar amizades
        print("\nCriando amizades...")
        
        # Amizades normais (não referidas) - MUITO MAIS AMIZADES
        normal_friendships = [
            # Grupo principal
            ("arthur", "maria"), ("arthur", "joao"), ("arthur", "ana"), ("arthur", "pedro"), ("arthur", "carla"),
            ("maria", "joao"), ("maria", "carla"), ("maria", "lucas"), ("maria", "sofia"), ("maria", "rafael"),
            ("joao", "pedro"), ("joao", "ana"), ("joao", "lucas"), ("joao", "julia"), ("joao", "gabriel"),
            ("ana", "carla"), ("ana", "lucas"), ("ana", "sofia"), ("ana", "julia"), ("ana", "beatriz"),
            ("pedro", "carla"), ("pedro", "lucas"), ("pedro", "sofia"), ("pedro", "rafael"), ("pedro", "felipe"),
            ("carla", "lucas"), ("carla", "sofia"), ("carla", "julia"), ("carla", "gabriel"), ("carla", "lara"),
            ("lucas", "sofia"), ("lucas", "rafael"), ("lucas", "julia"), ("lucas", "gabriel"), ("lucas", "beatriz"),
            ("sofia", "rafael"), ("sofia", "julia"), ("sofia", "gabriel"), ("sofia", "beatriz"), ("sofia", "felipe"),
            ("rafael", "julia"), ("rafael", "gabriel"), ("rafael", "beatriz"), ("rafael", "felipe"), ("rafael", "lara"),
            ("julia", "gabriel"), ("julia", "beatriz"), ("julia", "felipe"), ("julia", "lara"), ("julia", "diego"),
            ("gabriel", "beatriz"), ("gabriel", "felipe"), ("gabriel", "lara"), ("gabriel", "diego"),
            ("beatriz", "felipe"), ("beatriz", "lara"), ("beatriz", "diego"),
            ("felipe", "lara"), ("felipe", "diego"),
            ("lara", "diego"),
            
            # Conexões com novos usuários
            ("arthur", "camila"), ("arthur", "bruno"), ("arthur", "fernanda"), ("arthur", "marcos"), ("arthur", "patricia"),
            ("maria", "ricardo"), ("maria", "vanessa"), ("maria", "thiago"), ("maria", "isabela"), ("maria", "andre"),
            ("joao", "natalia"), ("joao", "leonardo"), ("joao", "amanda"), ("joao", "rodrigo"), ("joao", "carolina"),
            ("ana", "vinicius"), ("ana", "larissa"), ("ana", "guilherme"), ("ana", "barbara"), ("ana", "fabricio"),
            ("pedro", "monique"), ("pedro", "henrique"), ("pedro", "tamires"), ("pedro", "alexandre"), ("pedro", "priscila"),
            ("carla", "daniel"), ("carla", "jessica"), ("carla", "marcelo"), ("carla", "renata"), ("carla", "carlos"),
            ("lucas", "adriana"), ("lucas", "roberto"), ("lucas", "cristina"), ("lucas", "antonio"), ("lucas", "eliane"),
            ("sofia", "paulo"), ("sofia", "silvia"), ("sofia", "eduardo"), ("sofia", "denise"), ("sofia", "sergio"),
            ("rafael", "rosana"), ("rafael", "wagner"), ("rafael", "marcia"), ("rafael", "jose"), ("rafael", "lucia"),
            ("julia", "luiz"), ("julia", "rosemary"), ("julia", "miguel"), ("julia", "valeria"), ("julia", "cesar"),
            ("gabriel", "sandra"), ("gabriel", "rogerio"), ("gabriel", "claudia"), ("gabriel", "marcos2"), ("gabriel", "elisa"),
            ("beatriz", "alberto"), ("beatriz", "vera"), ("beatriz", "nelson"), ("beatriz", "maria2"), ("beatriz", "osvaldo"),
            ("felipe", "rita"), ("felipe", "gilberto"), ("felipe", "maria3"), ("felipe", "jorge"), ("felipe", "lucia2"),
            ("lara", "roberto2"), ("lara", "maria4"), ("lara", "carlos2"), ("lara", "ana2"), ("lara", "joao2"),
            ("diego", "maria5"), ("diego", "antonio2"), ("diego", "francisco"), ("diego", "maria6"), ("diego", "jose2"),
            
            # Conexões entre novos usuários
            ("camila", "bruno"), ("camila", "fernanda"), ("camila", "marcos"), ("camila", "patricia"), ("camila", "ricardo"),
            ("bruno", "fernanda"), ("bruno", "marcos"), ("bruno", "patricia"), ("bruno", "ricardo"), ("bruno", "vanessa"),
            ("fernanda", "marcos"), ("fernanda", "patricia"), ("fernanda", "ricardo"), ("fernanda", "vanessa"), ("fernanda", "thiago"),
            ("marcos", "patricia"), ("marcos", "ricardo"), ("marcos", "vanessa"), ("marcos", "thiago"), ("marcos", "isabela"),
            ("patricia", "ricardo"), ("patricia", "vanessa"), ("patricia", "thiago"), ("patricia", "isabela"), ("patricia", "andre"),
            ("ricardo", "vanessa"), ("ricardo", "thiago"), ("ricardo", "isabela"), ("ricardo", "andre"), ("ricardo", "natalia"),
            ("vanessa", "thiago"), ("vanessa", "isabela"), ("vanessa", "andre"), ("vanessa", "natalia"), ("vanessa", "leonardo"),
            ("thiago", "isabela"), ("thiago", "andre"), ("thiago", "natalia"), ("thiago", "leonardo"), ("thiago", "amanda"),
            ("isabela", "andre"), ("isabela", "natalia"), ("isabela", "leonardo"), ("isabela", "amanda"), ("isabela", "rodrigo"),
            ("andre", "natalia"), ("andre", "leonardo"), ("andre", "amanda"), ("andre", "rodrigo"), ("andre", "carolina"),
            ("natalia", "leonardo"), ("natalia", "amanda"), ("natalia", "rodrigo"), ("natalia", "carolina"), ("natalia", "vinicius"),
            ("leonardo", "amanda"), ("leonardo", "rodrigo"), ("leonardo", "carolina"), ("leonardo", "vinicius"), ("leonardo", "larissa"),
            ("amanda", "rodrigo"), ("amanda", "carolina"), ("amanda", "vinicius"), ("amanda", "larissa"), ("amanda", "guilherme"),
            ("rodrigo", "carolina"), ("rodrigo", "vinicius"), ("rodrigo", "larissa"), ("rodrigo", "guilherme"), ("rodrigo", "barbara"),
            ("carolina", "vinicius"), ("carolina", "larissa"), ("carolina", "guilherme"), ("carolina", "barbara"), ("carolina", "fabricio"),
            ("vinicius", "larissa"), ("vinicius", "guilherme"), ("vinicius", "barbara"), ("vinicius", "fabricio"), ("vinicius", "monique"),
            ("larissa", "guilherme"), ("larissa", "barbara"), ("larissa", "fabricio"), ("larissa", "monique"), ("larissa", "henrique"),
            ("guilherme", "barbara"), ("guilherme", "fabricio"), ("guilherme", "monique"), ("guilherme", "henrique"), ("guilherme", "tamires"),
            ("barbara", "fabricio"), ("barbara", "monique"), ("barbara", "henrique"), ("barbara", "tamires"), ("barbara", "alexandre"),
            ("fabricio", "monique"), ("fabricio", "henrique"), ("fabricio", "tamires"), ("fabricio", "alexandre"), ("fabricio", "priscila"),
            ("monique", "henrique"), ("monique", "tamires"), ("monique", "alexandre"), ("monique", "priscila"), ("monique", "daniel"),
            ("henrique", "tamires"), ("henrique", "alexandre"), ("henrique", "priscila"), ("henrique", "daniel"), ("henrique", "jessica"),
            ("tamires", "alexandre"), ("tamires", "priscila"), ("tamires", "daniel"), ("tamires", "jessica"), ("tamires", "marcelo"),
            ("alexandre", "priscila"), ("alexandre", "daniel"), ("alexandre", "jessica"), ("alexandre", "marcelo"), ("alexandre", "renata"),
            ("priscila", "daniel"), ("priscila", "jessica"), ("priscila", "marcelo"), ("priscila", "renata"), ("priscila", "carlos"),
            ("daniel", "jessica"), ("daniel", "marcelo"), ("daniel", "renata"), ("daniel", "carlos"), ("daniel", "adriana"),
            ("jessica", "marcelo"), ("jessica", "renata"), ("jessica", "carlos"), ("jessica", "adriana"), ("jessica", "roberto"),
            ("marcelo", "renata"), ("marcelo", "carlos"), ("marcelo", "adriana"), ("marcelo", "roberto"), ("marcelo", "cristina"),
            ("renata", "carlos"), ("renata", "adriana"), ("renata", "roberto"), ("renata", "cristina"), ("renata", "antonio"),
            ("carlos", "adriana"), ("carlos", "roberto"), ("carlos", "cristina"), ("carlos", "antonio"), ("carlos", "eliane"),
            ("adriana", "roberto"), ("adriana", "cristina"), ("adriana", "antonio"), ("adriana", "eliane"), ("adriana", "paulo"),
            ("roberto", "cristina"), ("roberto", "antonio"), ("roberto", "eliane"), ("roberto", "paulo"), ("roberto", "silvia"),
            ("cristina", "antonio"), ("cristina", "eliane"), ("cristina", "paulo"), ("cristina", "silvia"), ("cristina", "eduardo"),
            ("antonio", "eliane"), ("antonio", "paulo"), ("antonio", "silvia"), ("antonio", "eduardo"), ("antonio", "denise"),
            ("eliane", "paulo"), ("eliane", "silvia"), ("eliane", "eduardo"), ("eliane", "denise"), ("eliane", "sergio"),
            ("paulo", "silvia"), ("paulo", "eduardo"), ("paulo", "denise"), ("paulo", "sergio"), ("paulo", "rosana"),
            ("silvia", "eduardo"), ("silvia", "denise"), ("silvia", "sergio"), ("silvia", "rosana"), ("silvia", "wagner"),
            ("eduardo", "denise"), ("eduardo", "sergio"), ("eduardo", "rosana"), ("eduardo", "wagner"), ("eduardo", "marcia"),
            ("denise", "sergio"), ("denise", "rosana"), ("denise", "wagner"), ("denise", "marcia"), ("denise", "jose"),
            ("sergio", "rosana"), ("sergio", "wagner"), ("sergio", "marcia"), ("sergio", "jose"), ("sergio", "lucia"),
            ("rosana", "wagner"), ("rosana", "marcia"), ("rosana", "jose"), ("rosana", "lucia"), ("rosana", "luiz"),
            ("wagner", "marcia"), ("wagner", "jose"), ("wagner", "lucia"), ("wagner", "luiz"), ("wagner", "rosemary"),
            ("marcia", "jose"), ("marcia", "lucia"), ("marcia", "luiz"), ("marcia", "rosemary"), ("marcia", "miguel"),
            ("jose", "lucia"), ("jose", "luiz"), ("jose", "rosemary"), ("jose", "miguel"), ("jose", "valeria"),
            ("lucia", "luiz"), ("lucia", "rosemary"), ("lucia", "miguel"), ("lucia", "valeria"), ("lucia", "cesar"),
            ("luiz", "rosemary"), ("luiz", "miguel"), ("luiz", "valeria"), ("luiz", "cesar"), ("luiz", "sandra"),
            ("rosemary", "miguel"), ("rosemary", "valeria"), ("rosemary", "cesar"), ("rosemary", "sandra"), ("rosemary", "rogerio"),
            ("miguel", "valeria"), ("miguel", "cesar"), ("miguel", "sandra"), ("miguel", "rogerio"), ("miguel", "claudia"),
            ("valeria", "cesar"), ("valeria", "sandra"), ("valeria", "rogerio"), ("valeria", "claudia"), ("valeria", "marcos2"),
            ("cesar", "sandra"), ("cesar", "rogerio"), ("cesar", "claudia"), ("cesar", "marcos2"), ("cesar", "elisa"),
            ("sandra", "rogerio"), ("sandra", "claudia"), ("sandra", "marcos2"), ("sandra", "elisa"), ("sandra", "alberto"),
            ("rogerio", "claudia"), ("rogerio", "marcos2"), ("rogerio", "elisa"), ("rogerio", "alberto"), ("rogerio", "vera"),
            ("claudia", "marcos2"), ("claudia", "elisa"), ("claudia", "alberto"), ("claudia", "vera"), ("claudia", "nelson"),
            ("marcos2", "elisa"), ("marcos2", "alberto"), ("marcos2", "vera"), ("marcos2", "nelson"), ("marcos2", "maria2"),
            ("elisa", "alberto"), ("elisa", "vera"), ("elisa", "nelson"), ("elisa", "maria2"), ("elisa", "osvaldo"),
            ("alberto", "vera"), ("alberto", "nelson"), ("alberto", "maria2"), ("alberto", "osvaldo"), ("alberto", "rita"),
            ("vera", "nelson"), ("vera", "maria2"), ("vera", "osvaldo"), ("vera", "rita"), ("vera", "gilberto"),
            ("nelson", "maria2"), ("nelson", "osvaldo"), ("nelson", "rita"), ("nelson", "gilberto"), ("nelson", "maria3"),
            ("maria2", "osvaldo"), ("maria2", "rita"), ("maria2", "gilberto"), ("maria2", "maria3"), ("maria2", "jorge"),
            ("osvaldo", "rita"), ("osvaldo", "gilberto"), ("osvaldo", "maria3"), ("osvaldo", "jorge"), ("osvaldo", "lucia2"),
            ("rita", "gilberto"), ("rita", "maria3"), ("rita", "jorge"), ("rita", "lucia2"), ("rita", "roberto2"),
            ("gilberto", "maria3"), ("gilberto", "jorge"), ("gilberto", "lucia2"), ("gilberto", "roberto2"), ("gilberto", "maria4"),
            ("maria3", "jorge"), ("maria3", "lucia2"), ("maria3", "roberto2"), ("maria3", "maria4"), ("maria3", "carlos2"),
            ("jorge", "lucia2"), ("jorge", "roberto2"), ("jorge", "maria4"), ("jorge", "carlos2"), ("jorge", "ana2"),
            ("lucia2", "roberto2"), ("lucia2", "maria4"), ("lucia2", "carlos2"), ("lucia2", "ana2"), ("lucia2", "joao2"),
            ("roberto2", "maria4"), ("roberto2", "carlos2"), ("roberto2", "ana2"), ("roberto2", "joao2"), ("roberto2", "maria5"),
            ("maria4", "carlos2"), ("maria4", "ana2"), ("maria4", "joao2"), ("maria4", "maria5"), ("maria4", "antonio2"),
            ("carlos2", "ana2"), ("carlos2", "joao2"), ("carlos2", "maria5"), ("carlos2", "antonio2"), ("carlos2", "francisco"),
            ("ana2", "joao2"), ("ana2", "maria5"), ("ana2", "antonio2"), ("ana2", "francisco"), ("ana2", "maria6"),
            ("joao2", "maria5"), ("joao2", "antonio2"), ("joao2", "francisco"), ("joao2", "maria6"), ("joao2", "jose2"),
            ("maria5", "antonio2"), ("maria5", "francisco"), ("maria5", "maria6"), ("maria5", "jose2"), ("maria5", "maria7"),
            ("antonio2", "francisco"), ("antonio2", "maria6"), ("antonio2", "jose2"), ("antonio2", "maria7"), ("antonio2", "manoel"),
            ("francisco", "maria6"), ("francisco", "jose2"), ("francisco", "maria7"), ("francisco", "manoel"), ("francisco", "maria8"),
            ("maria6", "jose2"), ("maria6", "maria7"), ("maria6", "manoel"), ("maria6", "maria8"), ("maria6", "sebastiao"),
            ("jose2", "maria7"), ("jose2", "manoel"), ("jose2", "maria8"), ("jose2", "sebastiao"), ("jose2", "maria9"),
            ("maria7", "manoel"), ("maria7", "maria8"), ("maria7", "sebastiao"), ("maria7", "maria9"), ("maria7", "francisco2"),
            ("manoel", "maria8"), ("manoel", "sebastiao"), ("manoel", "maria9"), ("manoel", "francisco2"), ("manoel", "maria10"),
            ("maria8", "sebastiao"), ("maria8", "maria9"), ("maria8", "francisco2"), ("maria8", "maria10"), ("maria8", "antonio3"),
            ("sebastiao", "maria9"), ("sebastiao", "francisco2"), ("sebastiao", "maria10"), ("sebastiao", "antonio3"), ("sebastiao", "maria11"),
            ("maria9", "francisco2"), ("maria9", "maria10"), ("maria9", "antonio3"), ("maria9", "maria11"), ("maria9", "francisco3"),
            ("francisco2", "maria10"), ("francisco2", "antonio3"), ("francisco2", "maria11"), ("francisco2", "francisco3"), ("francisco2", "maria12"),
            ("maria10", "antonio3"), ("maria10", "maria11"), ("maria10", "francisco3"), ("maria10", "maria12"), ("maria10", "antonio4"),
            ("antonio3", "maria11"), ("antonio3", "francisco3"), ("antonio3", "maria12"), ("antonio3", "antonio4"), ("antonio3", "maria13"),
            ("maria11", "francisco3"), ("maria11", "maria12"), ("maria11", "antonio4"), ("maria11", "maria13"), ("maria11", "francisco4"),
            ("francisco3", "maria12"), ("francisco3", "antonio4"), ("francisco3", "maria13"), ("francisco3", "francisco4"), ("francisco3", "maria14"),
            ("maria12", "antonio4"), ("maria12", "maria13"), ("maria12", "francisco4"), ("maria12", "maria14"), ("maria12", "antonio5"),
            ("antonio4", "maria13"), ("antonio4", "francisco4"), ("antonio4", "maria14"), ("antonio4", "antonio5"), ("antonio4", "maria15"),
            ("maria13", "francisco4"), ("maria13", "maria14"), ("maria13", "antonio5"), ("maria13", "maria15"), ("maria13", "francisco5"),
            ("francisco4", "maria14"), ("francisco4", "antonio5"), ("francisco4", "maria15"), ("francisco4", "francisco5"), ("francisco4", "maria16"),
            ("maria14", "antonio5"), ("maria14", "maria15"), ("maria14", "francisco5"), ("maria14", "maria16"), ("maria14", "antonio6"),
            ("antonio5", "maria15"), ("antonio5", "francisco5"), ("antonio5", "maria16"), ("antonio5", "antonio6"), ("antonio5", "maria17"),
            ("maria15", "francisco5"), ("maria15", "maria16"), ("maria15", "antonio6"), ("maria15", "maria17"), ("maria15", "francisco6"),
            ("francisco5", "maria16"), ("francisco5", "antonio6"), ("francisco5", "maria17"), ("francisco5", "francisco6"), ("francisco5", "maria18"),
            ("maria16", "antonio6"), ("maria16", "maria17"), ("maria16", "francisco6"), ("maria16", "maria18"), ("maria16", "antonio7"),
            ("antonio6", "maria17"), ("antonio6", "francisco6"), ("antonio6", "maria18"), ("antonio6", "antonio7"), ("antonio6", "maria19"),
            ("maria17", "francisco6"), ("maria17", "maria18"), ("maria17", "antonio7"), ("maria17", "maria19"), ("maria17", "francisco7"),
            ("francisco6", "maria18"), ("francisco6", "antonio7"), ("francisco6", "maria19"), ("francisco6", "francisco7"), ("francisco6", "maria20"),
            ("maria18", "antonio7"), ("maria18", "maria19"), ("maria18", "francisco7"), ("maria18", "maria20"), ("maria18", "antonio8"),
            ("antonio7", "maria19"), ("antonio7", "francisco7"), ("antonio7", "maria20"), ("antonio7", "antonio8"), ("antonio7", "maria21"),
            ("maria19", "francisco7"), ("maria19", "maria20"), ("maria19", "antonio8"), ("maria19", "maria21"), ("maria19", "francisco8"),
            ("francisco7", "maria20"), ("francisco7", "antonio8"), ("francisco7", "maria21"), ("francisco7", "francisco8"), ("francisco7", "maria22"),
            ("maria20", "antonio8"), ("maria20", "maria21"), ("maria20", "francisco8"), ("maria20", "maria22"), ("maria20", "antonio9"),
            ("antonio8", "maria21"), ("antonio8", "francisco8"), ("antonio8", "maria22"), ("antonio8", "antonio9"), ("antonio8", "maria23"),
            ("maria21", "francisco8"), ("maria21", "maria22"), ("maria21", "antonio9"), ("maria21", "maria23"), ("maria21", "francisco9"),
            ("francisco8", "maria22"), ("francisco8", "antonio9"), ("francisco8", "maria23"), ("francisco8", "francisco9"), ("francisco8", "maria24"),
            ("maria22", "antonio9"), ("maria22", "maria23"), ("maria22", "francisco9"), ("maria22", "maria24"), ("maria22", "antonio10"),
            ("antonio9", "maria23"), ("antonio9", "francisco9"), ("antonio9", "maria24"), ("antonio9", "antonio10"), ("antonio9", "maria25"),
            ("maria23", "francisco9"), ("maria23", "maria24"), ("maria23", "antonio10"), ("maria23", "maria25"), ("maria23", "francisco10"),
            ("francisco9", "maria24"), ("francisco9", "antonio10"), ("francisco9", "maria25"), ("francisco9", "francisco10"), ("francisco9", "maria26"),
            ("maria24", "antonio10"), ("maria24", "maria25"), ("maria24", "francisco10"), ("maria24", "maria26"), ("maria24", "antonio11"),
            ("antonio10", "maria25"), ("antonio10", "francisco10"), ("antonio10", "maria26"), ("antonio10", "antonio11"), ("antonio10", "maria27"),
            ("maria25", "francisco10"), ("maria25", "maria26"), ("maria25", "antonio11"), ("maria25", "maria27"), ("maria25", "francisco11"),
            ("francisco10", "maria26"), ("francisco10", "antonio11"), ("francisco10", "maria27"), ("francisco10", "francisco11"), ("francisco10", "maria28"),
            ("maria26", "antonio11"), ("maria26", "maria27"), ("maria26", "francisco11"), ("maria26", "maria28"), ("maria26", "antonio12"),
            ("antonio11", "maria27"), ("antonio11", "francisco11"), ("antonio11", "maria28"), ("antonio11", "antonio12"), ("antonio11", "maria29"),
            ("maria27", "francisco11"), ("maria27", "maria28"), ("maria27", "antonio12"), ("maria27", "maria29"), ("maria27", "francisco12"),
            ("francisco11", "maria28"), ("francisco11", "antonio12"), ("francisco11", "maria29"), ("francisco11", "francisco12"), ("francisco11", "maria30"),
            ("maria28", "antonio12"), ("maria28", "maria29"), ("maria28", "francisco12"), ("maria28", "maria30"),
            ("antonio12", "maria29"), ("antonio12", "francisco12"), ("antonio12", "maria30"),
            ("maria29", "francisco12"), ("maria29", "maria30"),
            ("francisco12", "maria30"),
        ]
        
        # Amizades referidas (um usou o código do outro) - MUITO MAIS REFERIDOS
        referred_friendships = [
            # Referidos pelos usuários principais
            ("arthur", "lucas", "arthur"), ("arthur", "sofia", "arthur"), ("arthur", "gabriel", "arthur"), ("arthur", "beatriz", "arthur"),
            ("maria", "rafael", "maria"), ("maria", "julia", "maria"), ("maria", "felipe", "maria"), ("maria", "lara", "maria"),
            ("joao", "diego", "joao"), ("joao", "camila", "joao"), ("joao", "bruno", "joao"), ("joao", "fernanda", "joao"),
            ("ana", "marcos", "ana"), ("ana", "patricia", "ana"), ("ana", "ricardo", "ana"), ("ana", "vanessa", "ana"),
            ("pedro", "thiago", "pedro"), ("pedro", "isabela", "pedro"), ("pedro", "andre", "pedro"), ("pedro", "natalia", "pedro"),
            ("carla", "leonardo", "carla"), ("carla", "amanda", "carla"), ("carla", "rodrigo", "carla"), ("carla", "carolina", "carla"),
            ("lucas", "vinicius", "lucas"), ("lucas", "larissa", "lucas"), ("lucas", "guilherme", "lucas"), ("lucas", "barbara", "lucas"),
            ("sofia", "fabricio", "sofia"), ("sofia", "monique", "sofia"), ("sofia", "henrique", "sofia"), ("sofia", "tamires", "sofia"),
            ("rafael", "alexandre", "rafael"), ("rafael", "priscila", "rafael"), ("rafael", "daniel", "rafael"), ("rafael", "jessica", "rafael"),
            ("julia", "marcelo", "julia"), ("julia", "renata", "julia"), ("julia", "carlos", "julia"), ("julia", "adriana", "julia"),
            ("gabriel", "roberto", "gabriel"), ("gabriel", "cristina", "gabriel"), ("gabriel", "antonio", "gabriel"), ("gabriel", "eliane", "gabriel"),
            ("beatriz", "paulo", "beatriz"), ("beatriz", "silvia", "beatriz"), ("beatriz", "eduardo", "beatriz"), ("beatriz", "denise", "beatriz"),
            ("felipe", "sergio", "felipe"), ("felipe", "rosana", "felipe"), ("felipe", "wagner", "felipe"), ("felipe", "marcia", "felipe"),
            ("lara", "jose", "lara"), ("lara", "lucia", "lara"), ("lara", "luiz", "lara"), ("lara", "rosemary", "lara"),
            ("diego", "miguel", "diego"), ("diego", "valeria", "diego"), ("diego", "cesar", "diego"), ("diego", "sandra", "diego"),
            
            # Referidos pelos novos usuários
            ("camila", "rogerio", "camila"), ("camila", "claudia", "camila"), ("camila", "marcos2", "camila"), ("camila", "elisa", "camila"),
            ("bruno", "alberto", "bruno"), ("bruno", "vera", "bruno"), ("bruno", "nelson", "bruno"), ("bruno", "maria2", "bruno"),
            ("fernanda", "osvaldo", "fernanda"), ("fernanda", "rita", "fernanda"), ("fernanda", "gilberto", "fernanda"), ("fernanda", "maria3", "fernanda"),
            ("marcos", "jorge", "marcos"), ("marcos", "lucia2", "marcos"), ("marcos", "roberto2", "marcos"), ("marcos", "maria4", "marcos"),
            ("patricia", "carlos2", "patricia"), ("patricia", "ana2", "patricia"), ("patricia", "joao2", "patricia"), ("patricia", "maria5", "patricia"),
            ("ricardo", "antonio2", "ricardo"), ("ricardo", "francisco", "ricardo"), ("ricardo", "maria6", "ricardo"), ("ricardo", "jose2", "ricardo"),
            ("vanessa", "maria7", "vanessa"), ("vanessa", "manoel", "vanessa"), ("vanessa", "maria8", "vanessa"), ("vanessa", "sebastiao", "vanessa"),
            ("thiago", "maria9", "thiago"), ("thiago", "francisco2", "thiago"), ("thiago", "maria10", "thiago"), ("thiago", "antonio3", "thiago"),
            ("isabela", "maria11", "isabela"), ("isabela", "francisco3", "isabela"), ("isabela", "maria12", "isabela"), ("isabela", "antonio4", "isabela"),
            ("andre", "maria13", "andre"), ("andre", "francisco4", "andre"), ("andre", "maria14", "andre"), ("andre", "antonio5", "andre"),
            ("natalia", "maria15", "natalia"), ("natalia", "francisco5", "natalia"), ("natalia", "maria16", "natalia"), ("natalia", "antonio6", "natalia"),
            ("leonardo", "maria17", "leonardo"), ("leonardo", "francisco6", "leonardo"), ("leonardo", "maria18", "leonardo"), ("leonardo", "antonio7", "leonardo"),
            ("amanda", "maria19", "amanda"), ("amanda", "francisco7", "amanda"), ("amanda", "maria20", "amanda"), ("amanda", "antonio8", "amanda"),
            ("rodrigo", "maria21", "rodrigo"), ("rodrigo", "francisco8", "rodrigo"), ("rodrigo", "maria22", "rodrigo"), ("rodrigo", "antonio9", "rodrigo"),
            ("carolina", "maria23", "carolina"), ("carolina", "francisco9", "carolina"), ("carolina", "maria24", "carolina"), ("carolina", "antonio10", "carolina"),
            ("vinicius", "maria25", "vinicius"), ("vinicius", "francisco10", "vinicius"), ("vinicius", "maria26", "vinicius"), ("vinicius", "antonio11", "vinicius"),
            ("larissa", "maria27", "larissa"), ("larissa", "francisco11", "larissa"), ("larissa", "maria28", "larissa"), ("larissa", "antonio12", "larissa"),
            ("guilherme", "maria29", "guilherme"), ("guilherme", "francisco12", "guilherme"), ("guilherme", "maria30", "guilherme"),
            ("barbara", "maria30", "barbara"),
        ]
        
        # Criar amizades normais
        for username1, username2 in normal_friendships:
            try:
                user1 = User.objects.get(username=username1)
                user2 = User.objects.get(username=username2)
                
                # Criar amizade bidirecional
                friendship1, created1 = Friendship.objects.get_or_create(
                    user=user1,
                    friend=user2,
                    defaults={'is_referred': False}
                )
                
                friendship2, created2 = Friendship.objects.get_or_create(
                    user=user2,
                    friend=user1,
                    defaults={'is_referred': False}
                )
                
                if created1 and created2:
                    print(f"✓ Amizade criada: {username1} ↔ {username2}")
                elif created1 or created2:
                    print(f"→ Amizade parcial já existe: {username1} ↔ {username2}")
                else:
                    print(f"→ Amizade já existe: {username1} ↔ {username2}")
                    
            except User.DoesNotExist as e:
                print(f"✗ Erro: Usuário não encontrado - {e}")
        
        # Criar amizades referidas
        for username1, username2, referrer in referred_friendships:
            try:
                user1 = User.objects.get(username=username1)
                user2 = User.objects.get(username=username2)
                referrer_user = User.objects.get(username=referrer)
                referrer_profile = Profile.objects.get(user=referrer_user)
                
                # Criar amizade bidirecional com flag de referido
                friendship1, created1 = Friendship.objects.get_or_create(
                    user=user1,
                    friend=user2,
                    defaults={
                        'is_referred': True,
                        'referral_code': referrer_profile.referral_code
                    }
                )
                
                friendship2, created2 = Friendship.objects.get_or_create(
                    user=user2,
                    friend=user1,
                    defaults={
                        'is_referred': True,
                        'referral_code': referrer_profile.referral_code
                    }
                )
                
                if created1 and created2:
                    print(f"✓ Amizade referida criada: {username1} ↔ {username2} (referido por {referrer})")
                elif created1 or created2:
                    print(f"→ Amizade referida parcial já existe: {username1} ↔ {username2}")
                else:
                    print(f"→ Amizade referida já existe: {username1} ↔ {username2}")
                    
            except User.DoesNotExist as e:
                print(f"✗ Erro: Usuário não encontrado - {e}")
            except Profile.DoesNotExist as e:
                print(f"✗ Erro: Perfil não encontrado - {e}")
        
        print("\n🎉 Dados mock criados com sucesso!")
        print("\nResumo:")
        print(f"- {len(created_users)} usuários criados")
        print(f"- {len(normal_friendships)} amizades normais")
        print(f"- {len(referred_friendships)} amizades referidas")
        
        # Mostrar alguns códigos de referência
        print("\nCódigos de referência:")
        for user in created_users[:5]:  # Mostrar apenas os primeiros 5
            try:
                profile = Profile.objects.get(user=user)
                print(f"- {user.username}: {profile.referral_code}")
            except Profile.DoesNotExist:
                print(f"- {user.username}: Perfil não encontrado")

if __name__ == "__main__":
    create_mock_users()
