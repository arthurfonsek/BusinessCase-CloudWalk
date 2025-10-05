import os
import uuid
from typing import Dict, List
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from .models import (
    RestaurantOwner, Reservation, RestaurantAnalytics, AIConversation, AIMessage
)


class AIRestaurantService:
    """Serviço de IA para donos de restaurante (insights de desempenho)."""

    def __init__(self):
        self.openai_key = os.getenv("OPENAI_API_KEY")

    # ===== Conversa (utilidades iguais às do serviço de gamificação) =====
    def create_conversation(self, user: User) -> AIConversation:
        session_id = str(uuid.uuid4())
        conversation = AIConversation.objects.create(
            user=user,
            session_id=session_id
        )
        return conversation

    def add_message(self, conversation: AIConversation, role: str, content: str,
                    message_type: str = 'text', metadata: Dict = None) -> AIMessage:
        return AIMessage.objects.create(
            conversation=conversation,
            role=role,
            content=content,
            message_type=message_type,
            metadata=metadata or {}
        )

    def get_conversation_history(self, conversation: AIConversation) -> List[Dict]:
        messages = conversation.messages.all()
        return [
            {
                'role': msg.role,
                'content': msg.content,
                'message_type': msg.message_type,
                'created_at': msg.created_at.isoformat(),
                'metadata': msg.metadata
            }
            for msg in messages
        ]

    # ===== Dados e respostas =====
    def get_restaurant_context(self, user: User) -> Dict:
        owner = RestaurantOwner.objects.get(user=user)
        restaurant = owner.restaurant
        # garantir analytics atualizados
        restaurant.analytics.update_stats()

        now = timezone.now()
        month_ago = now - timedelta(days=30)

        monthly_done = Reservation.objects.filter(
            restaurant=restaurant,
            created_at__gte=month_ago,
            status__in=['confirmed', 'completed']
        )
        monthly_no_show = Reservation.objects.filter(
            restaurant=restaurant,
            created_at__gte=month_ago,
            status='no_show'
        )

        monthly_count = monthly_done.count()
        avg_ticket = float(getattr(restaurant.profile, 'average_ticket', 0) or 0)
        monthly_revenue = monthly_count * avg_ticket

        return {
            'restaurant_name': restaurant.name,
            'average_rating': restaurant.analytics.average_rating,
            'total_reviews': restaurant.analytics.total_reviews,
            'total_reservations': restaurant.analytics.total_reservations,
            'total_revenue': float(restaurant.analytics.total_revenue),
            'monthly_reservations': monthly_count,
            'monthly_revenue': float(monthly_revenue),
            'no_shows_30d': monthly_no_show.count(),
            'period': 'últimos 30 dias',
        }

    def generate_ai_response(self, user: User, user_message: str) -> str:
        """Gera resposta da IA com foco em desempenho do restaurante.
        Usa OpenAI se disponível, senão fallback determinístico.
        """
        try:
            context = self.get_restaurant_context(user)
        except RestaurantOwner.DoesNotExist:
            return 'Você ainda não possui um restaurante cadastrado.'

        # Fallback: regras simples baseadas em palavras-chave
        if not self.openai_key:
            text = user_message.lower()
            # Projeção inteligente baseada em tendências reais das reservas
            if any(k in text for k in ['próximo mês', 'proximo mes', 'mês que vem', 'mes que vem', 'expectativa', 'expectativa de ganho', 'previsão', 'projecao', 'projeção']):
                try:
                    from django.utils import timezone
                    from datetime import timedelta
                    from api.models import Reservation
                    
                    owner = RestaurantOwner.objects.get(user=user)
                    restaurant = owner.restaurant
                    now = timezone.now()
                    
                    # Analisar tendências dos últimos 3 meses
                    three_months_ago = now - timedelta(days=90)
                    two_months_ago = now - timedelta(days=60)
                    one_month_ago = now - timedelta(days=30)
                    
                    # Reservas por período
                    reservations_3m = Reservation.objects.filter(
                        restaurant=restaurant,
                        created_at__gte=three_months_ago,
                        created_at__lt=two_months_ago,
                        status__in=['confirmed', 'completed']
                    ).count()
                    
                    reservations_2m = Reservation.objects.filter(
                        restaurant=restaurant,
                        created_at__gte=two_months_ago,
                        created_at__lt=one_month_ago,
                        status__in=['confirmed', 'completed']
                    ).count()
                    
                    reservations_1m = Reservation.objects.filter(
                        restaurant=restaurant,
                        created_at__gte=one_month_ago,
                        status__in=['confirmed', 'completed']
                    ).count()
                    
                    # Calcular tendência
                    if reservations_2m > 0 and reservations_1m > 0:
                        # Tendência baseada nos últimos 2 meses
                        growth_rate = (reservations_1m - reservations_2m) / reservations_2m
                    elif reservations_3m > 0:
                        # Tendência baseada nos últimos 3 meses
                        growth_rate = (reservations_1m - reservations_3m) / reservations_3m
                    else:
                        growth_rate = 0.0
                    
                    # Aplicar lift de exposição em listas
                    analytics = restaurant.analytics
                    times_in_lists = float(analytics.times_in_lists or 0)
                    times_recommended = float(analytics.times_recommended or 0)
                    k = 200.0
                    raw_lift = (times_in_lists + times_recommended) / k
                    lift = max(0.0, min(raw_lift, 0.3))  # Máximo 30% de lift
                    
                    # Projeção baseada na tendência real + lift
                    base_rev = float(context['monthly_revenue'])
                    trend_factor = 1.0 + (growth_rate * 0.5)  # Suavizar tendência
                    lift_factor = 1.0 + lift
                    next_month_revenue = base_rev * trend_factor * lift_factor
                    
                    delta = next_month_revenue - base_rev
                    direction = '↑' if delta >= 0 else '↓'
                    
                    # Explicação da projeção
                    explanation = []
                    if growth_rate > 0.1:
                        explanation.append(f"crescimento de {(growth_rate*100):.1f}%")
                    elif growth_rate < -0.1:
                        explanation.append(f"queda de {(abs(growth_rate)*100):.1f}%")
                    else:
                        explanation.append("tendência estável")
                    
                    if lift > 0.05:
                        explanation.append(f"exposição em listas (+{(lift*100):.1f}%)")
                    
                    return (
                        f"Expectativa de receita para o próximo mês: R$ {next_month_revenue:.2f} ({direction} R$ {abs(delta):.2f} vs. mês atual).\n"
                        f"Baseado em: {', '.join(explanation)}. "
                        f"Reservas: {reservations_1m} (último mês), {reservations_2m} (mês anterior)."
                    )
                    
                except Exception as e:
                    return f"Erro ao calcular projeção: {str(e)}"
            if any(k in text for k in ['resumo', 'mês', 'mensal', '30 dias']):
                return (
                    f"Resumo {context['period']} – {context['restaurant_name']}\n"
                    f"• Reservas concluídas/confirmadas: {context['monthly_reservations']}\n"
                    f"• Receita estimada: R$ {context['monthly_revenue']:.2f}\n"
                    f"• No-shows: {context['no_shows_30d']}\n"
                    f"• Avaliação média geral: {context['average_rating']:.1f} ({context['total_reviews']} avaliações)\n"
                    f"Sugestão: reduza no-shows confirmando reservas por mensagem e oferecendo lembretes."
                )
            if any(k in text for k in ['reserva', 'reservas']):
                return (
                    f"Você teve {context['monthly_reservations']} reservas nos {context['period']}. "
                    f"Capriche no pico de movimento com equipe e estoque alinhados."
                )
            if any(k in text for k in ['receita', 'faturamento']):
                return (
                    f"Receita estimada do período ({context['period']}): R$ {context['monthly_revenue']:.2f}. "
                    f"Ticket médio atual: otimize combos e upsell para aumentar o valor por mesa."
                )
            if any(k in text for k in ['avaliação', 'reviews']):
                return (
                    f"Sua avaliação média geral é {context['average_rating']:.1f} baseada em {context['total_reviews']} reviews. "
                    f"Estimule feedbacks pós-refeição e responda avaliações-chave."
                )
            # Default
            return (
                f"Olá! Posso analisar métricas do seu restaurante. Pergunte por exemplo: \n"
                f"• 'Me dê um resumo do mês'\n"
                f"• 'Como estão as reservas?'\n"
                f"• 'Qual foi a receita estimada?'\n"
                f"• 'Como está minha avaliação?'"
            )

        # Se houver OpenAI, incluir contexto e instruções específicas
        try:
            import openai
            openai.api_key = self.openai_key
            system_prompt = (
                "Você é um assistente de inteligência para donos de restaurante. "
                "Responda de forma objetiva, com números, tendências e sugestões práticas. "
                "Use dados do contexto quando citados."
            )
            ctx = self.get_restaurant_context(user)
            prompt = (
                f"Contexto:\n"
                f"Restaurante: {ctx['restaurant_name']}\n"
                f"Avaliação média: {ctx['average_rating']} ({ctx['total_reviews']} avaliações)\n"
                f"Reservas totais: {ctx['total_reservations']} | Receita total: R$ {ctx['total_revenue']:.2f}\n"
                f"Últimos 30 dias: reservas={ctx['monthly_reservations']}, receita=R$ {ctx['monthly_revenue']:.2f}, no-shows={ctx['no_shows_30d']}\n\n"
                f"Pergunta: {user_message}"
            )
            resp = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt},
                ],
                max_tokens=500,
                temperature=0.4,
            )
            return resp.choices[0].message.content.strip()
        except Exception:
            # fallback se OpenAI falhar
            return self.generate_ai_response.__wrapped__(self, user, user_message)  # type: ignore


