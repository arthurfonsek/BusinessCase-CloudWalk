from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.db import transaction
from django.utils import timezone

from api.models import (
    Profile,
    Friendship,
    Restaurant,
    List,
    ListItem,
    Reward,
    UserReward,
    RewardLedger,
    Tier,
    UserTier,
    Reservation,
    RestaurantOwner,
    RestaurantProfile,
    RestaurantAnalytics,
)

import random
import string
from datetime import timedelta, date, time
from decimal import Decimal


def generate_code(length: int = 8) -> str:
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))


class Command(BaseCommand):
    help = "Create two comprehensive test users: a Gold user with rich data and a restaurant owner with analytics"

    def add_arguments(self, parser):
        parser.add_argument('--reset', action='store_true', help='Reset existing users if present')
        # Gold user (normal)
        parser.add_argument('--gold-username', type=str, default='usuario_gold')
        parser.add_argument('--gold-first-name', type=str, default='Gold')
        parser.add_argument('--gold-last-name', type=str, default='User')
        parser.add_argument('--gold-email', type=str, default='gold@test.com')
        parser.add_argument('--gold-password', type=str, default='test123')
        # Restaurant owner
        parser.add_argument('--owner-username', type=str, default='restaurante_owner')
        parser.add_argument('--owner-first-name', type=str, default='Owner')
        parser.add_argument('--owner-last-name', type=str, default='Restaurant')
        parser.add_argument('--owner-email', type=str, default='owner@test.com')
        parser.add_argument('--owner-password', type=str, default='test123')
        # Restaurant details
        parser.add_argument('--restaurant-name', type=str, default='Cantina da Ana')
        parser.add_argument('--restaurant-address', type=str, default='Rua Exemplo, 123 - São Paulo')
        parser.add_argument('--restaurant-average-ticket', type=str, default='95.00')

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('Seeding comprehensive test users...'))

        # Ensure tiers and rewards exist minimally
        tier_names = ['Iniciante', 'Bronze', 'Prata', 'Ouro', 'Diamante']
        tiers = {t.name: t for t in Tier.objects.filter(name__in=tier_names)}
        if 'Ouro' not in tiers:
            self.stdout.write(self.style.WARNING('Tier Ouro não encontrado. Execute seed_gamification_data.py antes, ou criando tiers mínimos.'))
            # Create minimal tiers if missing
            tiers.setdefault('Iniciante', Tier.objects.create(name='Iniciante', min_referrals=0, color='#8B4513', icon='star_border', benefits=['Acesso']))
            tiers.setdefault('Bronze', Tier.objects.create(name='Bronze', min_referrals=3, color='#CD7F32', icon='star', benefits=['Desconto 5%']))
            tiers.setdefault('Prata', Tier.objects.create(name='Prata', min_referrals=8, color='#C0C0C0', icon='star_half', benefits=['Desconto 10%']))
            tiers.setdefault('Ouro', Tier.objects.create(name='Ouro', min_referrals=15, color='#FFD700', icon='star', benefits=['Desconto 15%']))
            tiers.setdefault('Diamante', Tier.objects.create(name='Diamante', min_referrals=30, color='#B9F2FF', icon='diamond', benefits=['Desconto 20%']))

        # Ensure restaurants exist
        restaurants = list(Restaurant.objects.all()[:12])
        if len(restaurants) < 6:
            # Create a few if database is empty-ish
            base = [
                ('Outback Steakhouse', -23.561, -46.656),
                ("McDonald's", -23.562, -46.657),
                ('Burger King', -23.563, -46.658),
                ('Subway', -23.564, -46.659),
                ('KFC', -23.565, -46.660),
                ('Pizza Hut', -23.566, -46.661),
                ("Domino's", -23.567, -46.662),
                ('Starbucks', -23.568, -46.663),
                ('Café Central', -23.569, -46.664),
                ('Sushi Yama', -23.570, -46.665),
                ('Pizza Express', -23.571, -46.666),
                ('Sushi Master', -23.572, -46.667),
            ]
            for name, lat, lng in base:
                r, _ = Restaurant.objects.get_or_create(
                    name=name,
                    defaults={
                        'address': 'São Paulo',
                        'lat': lat,
                        'lng': lng,
                        'categories': 'mixed',
                        'price_level': random.randint(1, 4),
                        'rating_avg': round(random.uniform(3.6, 4.6), 1),
                        'rating_count': random.randint(50, 300),
                    }
                )
                restaurants.append(r)

        # 1) Normal user Gold with friends, referrals, lists, rewards, reservations
        gold_username = options.get('gold_username')
        if options.get('reset'):
            User.objects.filter(username=gold_username).delete()
        gold_user, _ = User.objects.get_or_create(
            username=gold_username,
            defaults={
                'email': options.get('gold_email'),
                'first_name': options.get('gold_first_name'),
                'last_name': options.get('gold_last_name'),
            }
        )
        if not gold_user.has_usable_password():
            gold_user.set_password(options.get('gold_password'))
            gold_user.save()

        gold_profile, _ = Profile.objects.get_or_create(user=gold_user, defaults={'referral_code': generate_code(6), 'points': 0, 'role': 'user'})
        gold_tier, _ = UserTier.objects.get_or_create(user=gold_user, defaults={'tier': tiers['Ouro'], 'current_referrals': 15, 'total_points': 1200})
        # Force to Gold
        gold_tier.tier = tiers['Ouro']
        gold_tier.current_referrals = max(gold_tier.current_referrals, 15)
        gold_tier.total_points = max(gold_tier.total_points, 1200)
        gold_tier.save()

        # Create several friends and referrals
        friends = []
        for i in range(10):
            friend_username = f"gold_friend_{i+1}"
            friend, _ = User.objects.get_or_create(username=friend_username, defaults={'email': f'{friend_username}@test.com'})
            if not friend.has_usable_password():
                friend.set_password('test123')
                friend.save()
            Profile.objects.get_or_create(user=friend, defaults={'referral_code': generate_code(6), 'points': 0, 'role': 'user'})
            Friendship.objects.get_or_create(user=gold_user, friend=friend, defaults={'is_referred': (i < 7), 'referral_code': gold_profile.referral_code})
            Friendship.objects.get_or_create(user=friend, friend=gold_user, defaults={'is_referred': False})
            friends.append(friend)

        # Create lists for user and some friends
        list_templates = [
            ('Favoritos', 'Meus restaurantes preferidos'),
            ('Para Experimentar', 'Novos lugares para testar'),
            ('Delivery', 'Entregas rápidas'),
        ]
        for title, desc in list_templates:
            lst, _ = List.objects.get_or_create(owner=gold_user, title=title, defaults={'description': desc, 'is_public': True, 'share_code': generate_code(8)})
            items = random.sample(restaurants, 4)
            for idx, rest in enumerate(items):
                ListItem.objects.get_or_create(lst=lst, restaurant=rest, defaults={'note': random.choice(['Muito bom!', 'Favorito', 'Recomendo']), 'position': idx})

        for friend in friends[:5]:
            lst, _ = List.objects.get_or_create(owner=friend, title='Favoritos', defaults={'description': 'Lista do amigo', 'is_public': True, 'share_code': generate_code(8)})
            items = random.sample(restaurants, 3)
            for idx, rest in enumerate(items):
                ListItem.objects.get_or_create(lst=lst, restaurant=rest, defaults={'note': '', 'position': idx})

        # Rewards history (claimed and used)
        rewards = list(Reward.objects.all())
        if not rewards:
            # minimal rewards
            rewards = [
                Reward.objects.create(name='Desconto 5%', description='5% OFF', points_cost=100, reward_type='discount'),
                Reward.objects.create(name='Desconto 10%', description='10% OFF', points_cost=250, reward_type='discount'),
            ]
        now = timezone.now()
        for idx, rw in enumerate(rewards[:4]):
            ur, _ = UserReward.objects.get_or_create(user=gold_user, reward=rw)
            if idx % 2 == 0:
                ur.is_used = True
                ur.used_at = now - timedelta(days=idx * 5)
                ur.save()
            RewardLedger.objects.get_or_create(user=gold_user, reason='reward_claim', points=-rw.points_cost, meta={'reward': rw.name})

        # Some reservations to different restaurants
        for i in range(6):
            rest = random.choice(restaurants)
            res_date = date.today() - timedelta(days=30 - i * 3)
            res_time = time(hour=random.choice([19, 20, 21]), minute=0)
            status = random.choice(['confirmed', 'completed'])
            Reservation.objects.get_or_create(
                restaurant=rest,
                customer=gold_user,
                date=res_date,
                time=res_time,
                party_size=random.randint(2, 5),
                status=status,
                defaults={'estimated_value': random.randint(80, 250)}
            )

        self.stdout.write(self.style.SUCCESS('✅ Usuário Gold completo criado/atualizado.'))

        # 2) Restaurant owner with consolidated reservations and monthly revenue
        owner_username = options.get('owner_username')
        if options.get('reset'):
            User.objects.filter(username=owner_username).delete()
        owner_user, _ = User.objects.get_or_create(
            username=owner_username,
            defaults={
                'email': options.get('owner_email'),
                'first_name': options.get('owner_first_name'),
                'last_name': options.get('owner_last_name'),
            }
        )
        if not owner_user.has_usable_password():
            owner_user.set_password(options.get('owner_password'))
            owner_user.save()

        owner_profile, _ = Profile.objects.get_or_create(user=owner_user, defaults={'referral_code': generate_code(6), 'points': 0, 'role': 'restaurant_owner'})

        # Create or pick a restaurant for this owner
        restaurant, _ = Restaurant.objects.get_or_create(
            name=options.get('restaurant_name'),
            defaults={
                'address': options.get('restaurant_address'),
                'lat': -23.561,
                'lng': -46.656,
                'categories': 'italian,pasta',
                'price_level': 3,
                'rating_avg': 4.4,
                'rating_count': 180,
            }
        )

        # Attach owner to restaurant
        RestaurantOwner.objects.get_or_create(user=owner_user, restaurant=restaurant, defaults={'is_verified': True})

        # Ensure restaurant profile
        avg_ticket_str = options.get('restaurant_average_ticket')
        try:
            avg_ticket = Decimal(str(avg_ticket_str))
        except Exception:
            avg_ticket = Decimal('95.00')

        RestaurantProfile.objects.get_or_create(
            restaurant=restaurant,
            defaults={
                'description': 'Comida italiana caseira, ambiente familiar',
                'phone': '(11) 1234-5678',
                'email': 'contato@cantinadaana.com',
                'website': 'https://cantinadaana.com',
                'opening_hours': {day: {'open': '11:30', 'close': '23:00'} for day in ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']},
                'average_ticket': avg_ticket,
                'capacity': 60,
                'has_delivery': True,
                'has_takeaway': True,
                'has_reservations': True,
                'payment_methods': ['cash', 'credit', 'pix'],
                'special_features': ['wifi', 'parking']
            }
        )

        # Generate consolidated reservations over recent months
        months_back = 6
        customers = [gold_user] + friends[:5]
        for m in range(months_back, -1, -1):
            days_in_month = 28
            base_day = date.today() - timedelta(days=m*30)
            monthly_reservations = random.randint(12, 30)
            for _ in range(monthly_reservations):
                when = base_day - timedelta(days=random.randint(0, days_in_month))
                Reservation.objects.get_or_create(
                    restaurant=restaurant,
                    customer=random.choice(customers),
                    date=when,
                    time=time(hour=random.choice([19, 20, 21]), minute=0),
                    party_size=random.randint(2, 6),
                    status=random.choice(['confirmed', 'completed']),
                    defaults={'estimated_value': random.randint(80, 350)}
                )

        # Update analytics based on data
        analytics, _ = RestaurantAnalytics.objects.get_or_create(restaurant=restaurant)
        analytics.update_stats()

        self.stdout.write(self.style.SUCCESS('✅ Dono de restaurante com histórico e analytics criado/atualizado.'))

        self.stdout.write(self.style.SUCCESS('🎉 Seed concluído. Usuários criados/atualizados.'))


